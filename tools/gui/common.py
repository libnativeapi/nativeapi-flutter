"""Shared setup for the macOS scripts here: finds the skills' harness and the examples."""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORKSPACE = os.path.dirname(os.path.dirname(HERE))
SKILLS = os.path.join(WORKSPACE, '.agents', 'skills')
EXAMPLES = os.path.join(WORKSPACE, 'examples')
OUTPUT = os.path.join(HERE, 'output')  # recordings; git-ignored
# Checkouts of the leanflutter packages (tray_manager, window_manager, …), which live in
# their own repositories: by default next to the libnativeapi checkouts, i.e.
# ~/Projects/leanflutter for ~/Projects/libnativeapi/<workspace>.
LEANFLUTTER = os.environ.get(
    'LEANFLUTTER_DIR', os.path.join(os.path.dirname(os.path.dirname(WORKSPACE)), 'leanflutter'))
CORE_BUILD = os.path.join(WORKSPACE, 'core', 'build')  # ignored by core's .gitignore
sys.path.insert(0, os.path.join(SKILLS, 'gui-test', 'scripts', 'macos'))
sys.path.insert(0, os.path.join(SKILLS, 'record-demo', 'scripts', 'macos'))

import struct  # noqa: E402
import subprocess  # noqa: E402
import tempfile  # noqa: E402

from guiapp import GuiApp, build_flutter, flutter_executable  # noqa: E402


def example(name, args=()):
    """A GuiApp for the Flutter example examples/flutter_<name>."""
    return GuiApp(flutter_executable(os.path.join(EXAMPLES, 'flutter_' + name)), args=args)


def build_example(name):
    build_flutter(os.path.join(EXAMPLES, 'flutter_' + name))



def core_example(name):
    """A GuiApp for a C++ example of core/examples (built into core/build)."""
    return GuiApp(os.path.join(CORE_BUILD, 'examples', name, name))


def build_core_example(name):
    subprocess.run(['cmake', '-S', os.path.join(WORKSPACE, 'core'), '-B', CORE_BUILD,
                    '-DCMAKE_BUILD_TYPE=Debug'], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(['cmake', '--build', CORE_BUILD, '--target', name, '-j', '8'], check=True)


def output_path(script, platform, variant=None, ext='mp4'):
    """tools/gui/output/<script name>[-<variant>]-<platform>.<ext>"""
    os.makedirs(OUTPUT, exist_ok=True)
    name = os.path.splitext(os.path.basename(script))[0]
    return os.path.join(OUTPUT, '-'.join(filter(None, [name, variant, platform])) + f'.{ext}')


def screen_color(x, y):
    """(r, g, b) of the screen around a point, averaged over 4 x 4 points."""
    with tempfile.TemporaryDirectory() as tmp:
        png, bmp = os.path.join(tmp, 'p.png'), os.path.join(tmp, 'p.bmp')
        subprocess.run(['screencapture', '-x', '-R', f'{int(x)},{int(y)},4,4', png], check=True)
        subprocess.run(['sips', '-s', 'format', 'bmp', png, '--out', bmp], check=True,
                       stdout=subprocess.DEVNULL)
        data = open(bmp, 'rb').read()
    offset, width, height, bits = (struct.unpack_from('<I', data, 10)[0],
                                   *struct.unpack_from('<ii', data, 18),
                                   struct.unpack_from('<H', data, 28)[0])
    step, row = bits // 8, ((bits * width + 31) // 32) * 4
    pixels = [data[offset + r * row + c * step: offset + r * row + c * step + 3]
              for r in range(abs(height)) for c in range(width)]
    return tuple(round(sum(p[i] for p in pixels) / len(pixels)) for i in (2, 1, 0))
