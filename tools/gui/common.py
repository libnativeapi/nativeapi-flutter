"""Shared setup for the macOS scripts here: finds the skills' harness and the examples."""

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
WORKSPACE = os.path.dirname(os.path.dirname(HERE))
SKILLS = os.path.join(WORKSPACE, '.agents', 'skills')
EXAMPLES = os.path.join(WORKSPACE, 'bindings', 'flutter', 'examples')
OUTPUT = os.path.join(HERE, 'output')  # recordings; git-ignored
CORE_BUILD = os.path.join(WORKSPACE, 'core', 'build')  # ignored by core's .gitignore
sys.path.insert(0, os.path.join(SKILLS, 'gui-test', 'scripts', 'macos'))
sys.path.insert(0, os.path.join(SKILLS, 'record-demo', 'scripts', 'macos'))

import subprocess  # noqa: E402

from guiapp import GuiApp, build_flutter, flutter_executable  # noqa: E402


def example(name, args=()):
    """A GuiApp for a Flutter example of bindings/flutter."""
    return GuiApp(flutter_executable(os.path.join(EXAMPLES, name)), args=args)


def build_example(name):
    build_flutter(os.path.join(EXAMPLES, name))



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
