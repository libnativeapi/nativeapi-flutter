#!/usr/bin/env python3
"""No-input Linux shape demo smoke test; Wayland by default; pass --x11 to also try X11.

Build the debug example in $REMOTE_SCRATCH/shape-flutter-linux first, then run
through remote.sh linux desktop. A failed X11 engine launch is a failure, not
silently counted as shape support. No mouse input is sent.
"""
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import time
import urllib.parse
import urllib.request

from guiapp import flutter_executable
from uiprobe import App

scratch = Path(os.environ.get('REMOTE_SCRATCH', Path(__file__).parent))
project = Path(os.environ.get('SHAPE_EXAMPLE_DIR', scratch / 'shape-flutter-linux/examples/flutter_shaped_window_example'))


def preview_input_region(trace, *, history=False):
    """Read the region committed for the surface titled Shape preview."""
    regions, xdg_surfaces, toplevels, pending, committed = {}, {}, {}, {}, {}
    preview = None
    updates = {}
    for line in trace.splitlines():
        match = re.search(r'get_xdg_surface\(new id xdg_surface[@#](\d+), wl_surface[@#](\d+)\)', line)
        if match:
            xdg_surfaces[match[1]] = match[2]
        match = re.search(r'xdg_surface[@#](\d+)\.get_toplevel\(new id xdg_toplevel[@#](\d+)\)', line)
        if match:
            toplevels[match[2]] = xdg_surfaces[match[1]]
        match = re.search(r'xdg_toplevel[@#](\d+)\.set_title\("Shape preview"\)', line)
        if match:
            preview = toplevels[match[1]]
        match = re.search(r'create_region\(new id wl_region[@#](\d+)\)', line)
        if match:
            regions[match[1]] = []
        match = re.search(r'wl_region[@#](\d+)\.add\(([-\d]+), ([-\d]+), (\d+), (\d+)\)', line)
        if match:
            regions.setdefault(match[1], []).append(tuple(map(int, match.groups()[1:])))
        match = re.search(r'wl_surface[@#](\d+)\.set_input_region\((?:wl_region[@#](\d+)|nil)\)', line)
        if match:
            pending[match[1]] = list(regions[match[2]]) if match[2] else None
        match = re.search(r'wl_surface[@#](\d+)\.commit\(', line)
        if match and match[1] in pending:
            committed[match[1]] = pending.pop(match[1])
            updates.setdefault(match[1], []).append(committed[match[1]])
    assert preview in committed, 'No committed input region for Shape preview'
    return updates[preview] if history else committed[preview]


def run(backend):
    log_path = scratch / f'shape-flutter-{backend}.log'
    with log_path.open('w') as log:
        proc = subprocess.Popen([flutter_executable(str(project))], stdout=log,
                                stderr=subprocess.STDOUT,
                                env=dict(os.environ, GDK_BACKEND=backend, WAYLAND_DEBUG='1' if backend == 'wayland' else '0'))
    probe = App(str(log_path))
    checks = 0

    def check(ok, label):
        nonlocal checks
        assert ok, label
        checks += 1
        print(f'PASS {backend}: {label}', flush=True)

    def call(method, **params):
        url = probe.vm_url() + method + '?' + urllib.parse.urlencode(params)
        result = json.load(urllib.request.urlopen(url, timeout=15))
        assert 'error' not in result, result
        return result['result']

    try:
        deadline = time.monotonic() + 45
        views = []
        while time.monotonic() < deadline and proc.poll() is None:
            try:
                views = probe.views() if probe.vm_url() else []
                if len(views) == 2 and any(v.has('Tap · 0') for v in views):
                    break
            except Exception:
                pass
            time.sleep(.5)
        check(proc.poll() is None and len(views) == 2, 'two rendered windows')
        # VM invoke can interrupt a paint callback; wait for startup frames to settle.
        time.sleep(3)
        if backend == 'wayland':
            check(re.search(r'xdg_toplevel[@#]\d+\.set_parent\(xdg_toplevel[@#]\d+\)',
                            log_path.read_text()) is not None, 'preview has a native parent')
        iso = next(i['id'] for i in call('getVM')['isolates'] if i['name'] == 'main')
        classes = call('getClassList', isolateId=iso)['classes']
        cls = next(c['id'] for c in classes if c['name'] == '_ShapeDemoState')
        state = call('getInstances', isolateId=iso, objectId=cls, limit=1)['instances'][0]['id']

        def invoke(selector, args=()):
            result = call('invoke', isolateId=iso, targetId=state, selector=selector,
                          argumentIds='[' + ','.join(args) + ']')
            assert result.get('type') != '@Error', result
            time.sleep(1)

        enum = next(c['id'] for c in classes if c['name'] == 'DemoShape')
        shapes = {}
        for instance in call('getInstances', isolateId=iso, objectId=enum, limit=10)['instances']:
            fields = call('getObject', isolateId=iso, objectId=instance['id'])['fields']
            name = next(f['value']['valueAsString'] for f in fields if f['decl']['name'] == '_name')
            shapes[name] = instance['id']
        for name in ['circle', 'star', 'bubble']:
            log_start = len(log_path.read_text())
            before_updates = (len(preview_input_region(log_path.read_text(), history=True))
                              if backend == 'wayland' else 0)
            invoke('selectShape', [shapes[name]])
            views = probe.views()
            check(any(v.has(name) and v.has('Tap · 0') for v in views), name + ' preview content')
            status = f'{name}: Flutter clip + native input region'
            # The portable probe omits wrapped paragraphs; inspect the raw tree.
            dump = call('ext.flutter.debugDumpRenderTree', isolateId=iso)['data']
            check(status in dump, name + ' backend status')
            if backend == 'wayland':
                check('isInputShaped=true' in log_path.read_text()[log_start:], name + ' native input state')
                region = preview_input_region(log_path.read_text())
                check(region is not None and len(region) > 2, name + ' polygon committed to compositor')
                if name != 'circle':
                    frames = preview_input_region(log_path.read_text(), history=True)[before_updates:]
                    distinct = {tuple(frame or []) for frame in frames}
                    check(len(distinct) >= 3, name + ' morph commits intermediate contours')
                subprocess.run([sys.executable, str(scratch / 'wayland_shot.py'),
                                str(scratch / f'shape-wayland-{name}.png')],
                               check=True, timeout=30, stdout=subprocess.DEVNULL)
        region_before = preview_input_region(log_path.read_text()) if backend == 'wayland' else None
        invoke('toggleShadow')
        dump = call('ext.flutter.debugDumpRenderTree', isolateId=iso)['data']
        check('[shadow] hasShadow=false' in log_path.read_text(), 'core shadow can be disabled')
        invoke('toggleShadow')
        dump = call('ext.flutter.debugDumpRenderTree', isolateId=iso)['data']
        check('[shadow] hasShadow=true' in log_path.read_text(), 'core shadow can be enabled')
        check('ContourShadowPainter' not in dump, 'Flutter does not paint shadows')
        if backend == 'wayland':
            check(preview_input_region(log_path.read_text()) == region_before,
                  'shadow toggle leaves compositor input region unchanged')
        invoke('resizePreview')
        check(any(v.has('Tap · 0') and v.size == (400., 400.) for v in probe.views()),
              '400 x 400 content; core owns shadow margin')
        before_restore = (len(preview_input_region(log_path.read_text(), history=True))
                          if backend == 'wayland' else 0)
        invoke('restoreRectangle')
        expected = 'Rectangle restored'
        check(any(v.has(expected) for v in probe.views()), 'rectangle restored')
        if backend == 'wayland':
            region = preview_input_region(log_path.read_text())
            left = min(r[0] for r in region)
            top = min(r[1] for r in region)
            right = max(r[0] + r[2] for r in region)
            bottom = max(r[1] + r[3] for r in region)
            check(right - left == 400 and bottom - top == 400,
                  'restored rectangle input excludes the shadow margin')
            restore_frames = preview_input_region(log_path.read_text(), history=True)[before_restore:]
            check(len({tuple(frame or []) for frame in restore_frames}) >= 3,
                  'restoration morph commits intermediate contours')
            subprocess.run([sys.executable, str(scratch / 'wayland_shot.py'),
                            str(scratch / 'shape-wayland-rectangle.png')],
                           check=True, timeout=30, stdout=subprocess.DEVNULL)
        invoke('selectShape', [shapes['star']])
        check(any(v.has('star') and v.has('Tap · 0') for v in probe.views()), 'reapply after restoration')
        check(proc.poll() is None and 'EXCEPTION CAUGHT' not in log_path.read_text(),
              'process alive without framework exceptions')
        return {'backend': backend, 'checks': checks, 'passed': True}
    except Exception as exc:
        print(f'FAIL {backend}: {exc}\n{log_path.read_text()[-2500:]}', flush=True)
        return {'backend': backend, 'checks': checks, 'passed': False, 'error': str(exc)}
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(5)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()


if __name__ == '__main__':
    results = [run(backend) for backend in (['wayland', 'x11'] if '--x11' in sys.argv else ['wayland'])]
    (scratch / 'shape-flutter-linux-results.json').write_text(json.dumps(results, indent=2))
    sys.exit(0 if all(r['passed'] for r in results) else 1)
