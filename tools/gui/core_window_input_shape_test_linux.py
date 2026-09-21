#!/usr/bin/env python3
"""Assert Wayland input regions from the real client's protocol trace. No input."""
import os
from pathlib import Path
import re
import subprocess

scratch = Path(__file__).resolve().parent
log = scratch / 'shape-input-wayland.log'
with log.open('w') as out:
    result = subprocess.run([str(scratch / 'core_window_input_shape_test_linux')],
                            env=dict(os.environ, GDK_BACKEND='wayland', WAYLAND_DEBUG='1'),
                            stdout=out, stderr=subprocess.STDOUT, timeout=40)
assert result.returncode == 0, log.read_text()[-6000:]
regions = {}
current = None
pending = {}
checks = 0
for line in log.read_text().splitlines():
    create = re.search(r'create_region\(new id wl_region[@#](\d+)\)', line)
    add = re.search(r'wl_region[@#](\d+)\.add\(([-\d]+), ([-\d]+), (\d+), (\d+)\)', line)
    apply = re.search(r'wl_surface[@#](\d+)\.set_input_region\((?:wl_region[@#](\d+)|nil)\)', line)
    commit = re.search(r'wl_surface[@#](\d+)\.commit\(', line)
    if create:
        regions[create[1]] = []
    if add:
        regions.setdefault(add[1], []).append(tuple(map(int, add.groups()[1:])))
    if apply:
        pending[apply[1]] = list(regions[apply[2]]) if apply[2] else None
    if commit and commit[1] in pending:
        current = pending.pop(commit[1])
    if line.startswith('PASS '):
        print(line)
    if line.startswith('CHECK_REGION '):
        _, kind, dx, dy = line.split()
        dx, dy = int(dx), int(dy)
        extent = 400 if kind == 'large' else 320
        def contains(x, y):
            return current is None or any(a <= x + dx < a + w and b <= y + dy < b + h
                                          for a, b, w, h in current)
        assert contains(extent // 2, extent // 4), (kind, 'centre', current)
        assert contains(10, extent - 20) == (kind == 'rectangle'), (kind, 'corner', current)
        assert contains(20, 10), (kind, 'upper-left', current)
        checks += 3
        print(f'PASS Wayland {kind}: centre, top and corner; content offset {dx},{dy}')
assert checks == 12, f'Missing protocol checkpoints: {checks}'
print(f'{checks} Wayland protocol assertions passed')
