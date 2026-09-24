"""Attach to the running debug shape demo. No synthetic mouse/key input.
Run on the Windows desktop with the demo's stdout log as the only argument.
"""
import ctypes as C
from ctypes import wintypes as W
import json
from pathlib import Path
import re
import sys
import time
import threading
import urllib.parse
import urllib.request

log = Path(sys.argv[1])
url = re.search(r'http://127\.0\.0\.1:\d+/\S+/', log.read_text()).group()
def call(method, **params):
    result = json.load(urllib.request.urlopen(url + method + '?' + urllib.parse.urlencode(params), timeout=20))
    assert 'error' not in result, result
    return result['result']
iso = next(i['id'] for i in call('getVM')['isolates'] if i['name'] == 'main')
classes = call('getClassList', isolateId=iso)['classes']
cls = next(c['id'] for c in classes if c['name'] == '_ShapeDemoState')
state = call('getInstances', isolateId=iso, objectId=cls, limit=1)['instances'][0]['id']
def invoke(selector, args=()):
    result = call('invoke', isolateId=iso, targetId=state, selector=selector,
                  argumentIds='[' + ','.join(args) + ']')
    assert result.get('type') != '@Error', result
    time.sleep(.8)

enum = next(c['id'] for c in classes if c['name'] == 'DemoShape')
shapes = {}
for instance in call('getInstances', isolateId=iso, objectId=enum, limit=10)['instances']:
    fields = call('getObject', isolateId=iso, objectId=instance['id'])['fields']
    name = next(f['value']['valueAsString'] for f in fields if f['decl']['name'] == '_name')
    shapes[name] = instance['id']

u = C.WinDLL('user32', use_last_error=True)
callback = C.WINFUNCTYPE(W.BOOL, W.HWND, W.LPARAM)
for name, args, result in [
    ('FindWindowW', [W.LPCWSTR, W.LPCWSTR], W.HWND),
    ('GetWindow', [W.HWND, W.UINT], W.HWND),
    ('GetWindowLongPtrW', [W.HWND, C.c_int], C.c_ssize_t),
    ('GetWindowRect', [W.HWND, C.POINTER(W.RECT)], W.BOOL),
    ('SetWindowPos', [W.HWND, W.HWND, C.c_int, C.c_int, C.c_int, C.c_int, W.UINT], W.BOOL),
    ('GetWindowThreadProcessId', [W.HWND, C.POINTER(W.DWORD)], W.DWORD),
    ('GetClassNameW', [W.HWND, W.LPWSTR, C.c_int], C.c_int),
    ('EnumWindows', [callback, W.LPARAM], W.BOOL),
    ('IsWindowVisible', [W.HWND], W.BOOL),
    ('ShowWindow', [W.HWND, C.c_int], W.BOOL),
]:
    f = getattr(u, name); f.argtypes = args; f.restype = result
preview = u.FindWindowW(None, 'Shape preview')
assert preview
pid = W.DWORD(); u.GetWindowThreadProcessId(preview, C.byref(pid))
def shadows():
    found = []
    @callback
    def visit(hwnd, _):
        p = W.DWORD(); u.GetWindowThreadProcessId(hwnd, C.byref(p))
        name = C.create_unicode_buffer(128); u.GetClassNameW(hwnd, name, 128)
        if p.value == pid.value and name.value == 'NativeAPIShapeShadowWindow': found.append(hwnd)
        return True
    u.EnumWindows(visit, 0)
    return found

def rect(hwnd):
    r = W.RECT(); assert u.GetWindowRect(hwnd, C.byref(r)); return r
checks = 0
def check(ok, label):
    global checks
    assert ok, label
    checks += 1; print('PASS', label, flush=True)

for name in ['circle', 'star', 'bubble']:
    invoke('selectShape', [shapes[name]])
    layers = shadows()
    check(len(layers) == 1 and u.IsWindowVisible(layers[0]), name + ' has one visible contour shadow')
    layer = layers[0]
    style = u.GetWindowLongPtrW(layer, -20)
    check(style & 0x80020 == 0x80020 and style & 0x08000080 == 0x08000080,
          name + ' shadow is layered, click-through, nonactivating and absent from taskbar')
    check(u.GetWindow(preview, 2) == layer, name + ' shadow immediately behind preview')
    a, b = rect(preview), rect(layer)
    check(b.left < a.left and b.top < a.top and b.right > a.right and b.bottom > a.bottom,
          name + ' soft shadow extends beyond hard window bounds')

before = rect(preview); shadow_before = rect(shadows()[0])
u.SetWindowPos(preview, None, before.left + 20, before.top + 20, 0, 0, 0x15)
time.sleep(.3)
after = rect(shadows()[0])
check(after.left - shadow_before.left == 20 and after.top - shadow_before.top == 20, 'shadow follows native move')
u.SetWindowPos(preview, None, before.left, before.top, 0, 0, 0x15)
u.ShowWindow(preview, 0); time.sleep(.2)
check(not u.IsWindowVisible(shadows()[0]), 'shadow hides with preview')
u.ShowWindow(preview, 8); time.sleep(.2)
check(u.IsWindowVisible(shadows()[0]), 'shadow returns with preview')
invoke('toggleShadow'); check(not shadows(), 'disabling shadow destroys helper')
invoke('toggleShadow'); check(len(shadows()) == 1, 'enabling shadow recreates helper')
invoke('restoreRectangle'); check(len(shadows()) == 1, 'clearing shape retains rectangle shadow')
invoke('toggleShadow'); check(not shadows(), 'rectangle shadow can be disabled')
invoke('toggleShadow'); check(len(shadows()) == 1, 'rectangle shadow can be reenabled')
invoke('selectShape', [shapes['star']]); check(len(shadows()) == 1, 'reapply after rectangle restores shadow')
# Sample the actual Win32 region throughout both growth and shrinkage. Clearing
# it, even temporarily, exposes a rectangular frame before Flutter repaints.
gdi = C.WinDLL('gdi32')
gdi.CreateRectRgn.argtypes = [C.c_int] * 4
gdi.CreateRectRgn.restype = W.HANDLE
gdi.DeleteObject.argtypes = [W.HANDLE]
u.GetWindowRgn.argtypes = [W.HWND, W.HANDLE]
u.GetWindowRgn.restype = C.c_int
gdi.GetRgnBox.argtypes = [W.HANDLE, C.POINTER(W.RECT)]
gdi.GetRgnBox.restype = C.c_int
winmm = C.WinDLL('winmm')
for direction in ['grow', 'shrink']:
    samples = []
    finished = threading.Event()
    def sample_region():
        region = gdi.CreateRectRgn(0, 0, 0, 0)
        try:
            while not finished.is_set():
                C.set_last_error(0)
                kind = u.GetWindowRgn(preview, region)
                # Reading a foreign region while SetWindowRgn replaces its GDI
                # handle can fail with ERROR_INVALID_HANDLE. Retry that race;
                # an absent region (ERROR with no invalid-handle error) still fails.
                for _ in range(3):
                    if kind != 0 or C.get_last_error() != 6:
                        break
                    C.set_last_error(0)
                    kind = u.GetWindowRgn(preview, region)
                if kind == 0:
                    print("REGION_READ_ERROR", C.get_last_error(), flush=True)
                bounds = W.RECT()
                gdi.GetRgnBox(region, C.byref(bounds))
                samples.append((kind, bounds.right - bounds.left))
                finished.wait(.001)
        finally:
            gdi.DeleteObject(region)
    # Windows otherwise rounds Event.wait(.001) to a ~15.6 ms timer quantum,
    # which can alias with the animation and miss most intermediate regions.
    assert winmm.timeBeginPeriod(1) == 0
    sampler = threading.Thread(target=sample_region)
    sampler.start()
    try:
        invoke('resizePreview')
    finally:
        finished.set()
        sampler.join()
        winmm.timeEndPeriod(1)
    print(direction + ' region kinds: ' + str({kind for kind, _ in samples}) + ' samples: ' + str(len(samples)), flush=True)
    check(len(samples) > 10 and all(kind == 3 for kind, _ in samples),
          direction + ' preserves a complex native region throughout resize')
    widths = [width for _, width in samples]
    print(direction + ' distinct native contour widths: ' + str(len(set(widths))), flush=True)
    check(len(set(widths)) >= 12, direction + ' animates through at least 12 native contour sizes')
    fields = call('getObject', isolateId=iso, objectId=state)['fields']
    sizes = {f['decl']['name']: float(f['value']['valueAsString']) for f in fields
             if f['decl']['name'] in ('_size', '_nativeSize')}
    expected = 400 if direction == 'grow' else 320
    check(sizes == {'_size': expected, '_nativeSize': expected}, direction + ' settles content and native size')
check(len(shadows()) == 1, 'resize keeps exactly one shadow')
# Standalone debug executables have no expression compilation service. Use
# existing methods and allow Flutter to finish each build before the next call;
# VM invoke can otherwise interrupt a build and artificially trigger setState.
for _ in range(6):
    for selector in ['resizePreview', 'toggleShadow', 'toggleShadow']:
        invoke(selector)
check(len(shadows()) == 1, 'repeated resize and shadow toggles retain one helper')
invoke('toggleShadow')
time.sleep(.3)
check(not shadows(), 'disabled shadow stays absent')
invoke('toggleShadow')
check(len(shadows()) == 1 and u.IsWindowVisible(shadows()[0]), 'shadow can be enabled after repeated resizes')
dump = call('ext.flutter.debugDumpRenderTree', isolateId=iso)['data']
check('Contour shadow' in dump and 'Tap' in dump, 'controls and preview rendered')
check('EXCEPTION CAUGHT' not in log.read_text(), 'no Flutter layout exceptions')
print(f'{checks} checks passed; demo remains running with star shadow.', flush=True)
