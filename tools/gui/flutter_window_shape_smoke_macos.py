#!/usr/bin/env python3
"""No-input macOS smoke test: native shape changes via the debug VM service.

Build examples/shaped_window_example in debug first. This verifies API/state and
captures actual window pixels; it does not claim to test mouse click-through.
"""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / '.agents/skills/gui-test/scripts/macos'))
from guiapp import GuiApp, flutter_executable

project = ROOT / 'examples/flutter_shaped_window_example'
app = GuiApp(flutter_executable(str(project)))
output = Path(tempfile.mkdtemp(prefix='window-shape-smoke-'))


def call(method, **params):
    url = app.probe.vm_url() + method + '?' + urllib.parse.urlencode(params)
    response = json.load(urllib.request.urlopen(url, timeout=20))
    if 'error' in response:
        raise AssertionError(response['error'])
    return response['result']


try:
    app.launch(min_windows=2)
    iso = next(i['id'] for i in call('getVM')['isolates'] if i['name'] == 'main')
    classes = call('getClassList', isolateId=iso)['classes']
    cls = next(c['id'] for c in classes if c['name'] == '_ShapeDemoState')
    state = call('getInstances', isolateId=iso, objectId=cls, limit=1)['instances'][0]['id']

    def invoke(selector, arguments=()):
        result = call('invoke', isolateId=iso, targetId=state,
                      selector=selector, argumentIds='[' + ','.join(arguments) + ']')
        assert result.get('type') != '@Error', result
        return result

    enum_class = next(c['id'] for c in classes if c['name'] == 'DemoShape')
    enums = call('getInstances', isolateId=iso, objectId=enum_class, limit=10)['instances']
    shapes = {}
    for instance in enums:
        fields = call('getObject', isolateId=iso, objectId=instance['id'])['fields']
        name = next(f['value']['valueAsString'] for f in fields if f['decl']['name'] == '_name')
        shapes[name] = instance['id']

    swift = output / 'windows.swift'
    swift.write_text('''import Cocoa
if CommandLine.arguments[1] == "pixels" {
  let path = CommandLine.arguments[2]
  let image = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: path)))!
  let centre = image.colorAt(x: image.pixelsWide / 2, y: image.pixelsHigh / 2)!.alphaComponent
  let corner = image.colorAt(x: image.pixelsWide / 20, y: image.pixelsHigh / 20)!.alphaComponent
  let rectangle = path.hasSuffix("rectangle.png")
  if rectangle {
    // AppKit's capture includes transparent padding around the contour shadow.
    // Locate coloured content first, then verify its four extreme corners.
    var left = image.pixelsWide, top = image.pixelsHigh, right = -1, bottom = -1
    func isContent(_ x: Int, _ y: Int) -> Bool {
      let c = image.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
      return c.alphaComponent > 0.98 && max(c.redComponent, c.greenComponent, c.blueComponent) > 0.2
    }
    for y in 0..<image.pixelsHigh {
      for x in 0..<image.pixelsWide where isContent(x, y) {
        left = min(left, x); right = max(right, x)
        top = min(top, y); bottom = max(bottom, y)
      }
    }
    guard right > left && bottom > top else { fatalError("No content") }
    for (x, y) in [(left, top), (right, top), (left, bottom), (right, bottom)] {
      guard isContent(x, y) else { fatalError("Rounded rectangle corner") }
    }
  } else {
    guard centre > 0.99 && corner < 0.01 else { fatalError("Unexpected silhouette alpha") }
  }
  exit(0)
}
if CommandLine.arguments[1] == "top" {
  let image = NSBitmapImageRep(data: try! Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2])))!
  for y in 0..<image.pixelsHigh {
    for x in 0..<image.pixelsWide {
      let c = image.colorAt(x: x, y: y)!.usingColorSpace(.deviceRGB)!
      if c.alphaComponent > 0.98 && max(c.redComponent, c.greenComponent, c.blueComponent) > 0.2 {
        print(y)
        exit(0)
      }
    }
  }
  fatalError("No visible content during endpoint resize")
}
if CommandLine.arguments[1] == "sizes" {
  let pid = Int32(CommandLine.arguments[2])!
  var widths: [Int] = []
  let end = Date().addingTimeInterval(1.5)
  while Date() < end {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
    if let window = list.first(where: {
      $0[kCGWindowOwnerPID as String] as? Int32 == pid &&
      $0[kCGWindowName as String] as? String == "Shape preview"
    }), let bounds = window[kCGWindowBounds as String] as? [String: Any],
       let width = bounds["Width"] as? Int { widths.append(width) }
    Thread.sleep(forTimeInterval: 0.005)
  }
  print(String(data: try! JSONSerialization.data(withJSONObject: widths), encoding: .utf8)!)
  exit(0)
}
let pid = Int32(CommandLine.arguments[1])!
let list = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]
for w in list where w[kCGWindowOwnerPID as String] as? Int32 == pid {
  if let name = w[kCGWindowName as String] as? String,
     let id = w[kCGWindowNumber as String] as? Int, name == "Shape preview" { print(id) }
}
''')
    capture = output / 'windows'
    subprocess.run(['swiftc', str(swift), '-o', str(capture)], check=True)

    def snapshot(name):
        time.sleep(0.8)
        windows = subprocess.check_output([str(capture), str(app.proc.pid)], text=True).split()
        assert windows, 'preview window not found'
        subprocess.run(['screencapture', '-x', '-o', '-l', windows[0], str(output / f'{name}.png')], check=True)
        subprocess.run([str(capture), 'pixels', str(output / f'{name}.png')], check=True)

    for shape in ['circle', 'star', 'bubble']:
        invoke('selectShape', [shapes[shape]])
        deadline = time.monotonic() + 3
        while f'{shape}: native shape active' not in app.output() and time.monotonic() < deadline:
            time.sleep(.05)
        assert f'{shape}: native shape active' in app.output()
        assert any(v.has(shape) for v in app.views()), f'missing {shape} label'
        snapshot(shape)
        print(f'PASS {shape}: native shape active, label rendered')
    for target in [400, 320]:
        sampler = subprocess.Popen([str(capture), 'sizes', str(app.proc.pid)],
                                   stdout=subprocess.PIPE, text=True)
        time.sleep(.15)
        invoke('resizePreview')
        visual_widths = []
        deadline = time.monotonic() + .8
        while time.monotonic() < deadline:
            fields = call('getObject', isolateId=iso, objectId=state)['fields']
            visual_widths.append(float(next(f['value']['valueAsString'] for f in fields
                                           if f['decl']['name'] == '_size')))
            time.sleep(.008)
        # macOS keeps the backing surface stable and animates its visible native
        # contour, avoiding a Flutter raster synchronization on every pixel step.
        assert len(set(visual_widths)) >= 12, visual_widths
        assert visual_widths[-1] == target, visual_widths
        widths = json.loads(sampler.communicate(timeout=5)[0])
        assert widths[-1] == target and all(320 <= w <= 400 for w in widths), widths
        print(f'PASS resize to {target}: {len(set(visual_widths))} contour sizes and correct final native bounds')
    invoke('restoreRectangle')
    time.sleep(.8)
    assert 'Rectangle restored' in app.output()
    snapshot('rectangle')
    invoke('resizePreview')
    time.sleep(1)
    assert any(v.size == (400.0, 400.0) for v in app.views())
    snapshot('resized-rectangle')
    print('PASS rectangle retained after resize')
    for _ in range(3):
        invoke('resizePreview')
        time.sleep(.12)
    time.sleep(1)
    views = app.views()
    assert any(v.size == (320.0, 320.0) for v in views), ([v.size for v in views], call('getObject', isolateId=iso, objectId=state))
    print('PASS interrupted resize settles at latest destination')
    # Check pixels around the final surface contraction, not just settled bounds.
    # A circle has the same absolute top inset at both sizes: a misplaced mask
    # exposes a jump here even if the next Dart callback repairs the endpoint.
    invoke('selectShape', [shapes['circle']])
    time.sleep(.8)
    invoke('resizePreview')
    time.sleep(.8)
    window_id = subprocess.check_output([str(capture), str(app.proc.pid)], text=True).split()[0]
    tops = []
    def endpoint_capture(index):
        path = output / f'endpoint-{index}.png'
        subprocess.run(['screencapture', '-x', '-o', '-l', window_id, str(path)], check=True)
        tops.append(int(subprocess.check_output([str(capture), 'top', str(path)], text=True)))
    endpoint_capture(0)
    invoke('resizePreview')
    time.sleep(.30)
    for index in range(1, 9):
        endpoint_capture(index)
    assert max(tops) - min(tops) <= 4, tops
    print(f'PASS shrink endpoint keeps visible contour anchored: {tops}')
    # Exercise the native surface replacement repeatedly: the old Impeller
    # crash was intermittent and a single grow/shrink could pass.
    assert 'Using the Skia rendering backend (Metal)' in app.output(), app.output()
    for iteration in range(24):
        invoke('resizePreview')
        time.sleep(.65)
        assert app.proc.poll() is None, app.output()
        fields = call('getObject', isolateId=iso, objectId=state)['fields']
        sizes = {f['decl']['name']: float(f['value']['valueAsString']) for f in fields
                 if f['decl']['name'] in ('_size', '_nativeSize')}
        expected = 400 if iteration % 2 == 0 else 320
        assert sizes == {'_size': expected, '_nativeSize': expected}, sizes
    print('PASS 24 repeated size transitions on Skia Metal without process exit')
    assert 'texture and its descriptor disagree' not in app.output(), app.output()
    assert 'timed out' not in app.output().lower(), app.output()
    assert 'EXCEPTION CAUGHT' not in app.output(), app.output()
    print(f'Captures: {output}')
finally:
    print(f'App log: {app.log_path}')
    app.quit()
