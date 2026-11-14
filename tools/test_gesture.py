#!/usr/bin/env python3
"""Run the actual platform-independent code added by changes.patch, without cloning Telegram."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = 'TMessagesProj/src/main/java/org/telegram/ui/Components/cameraselect/'
SOURCES = ('CameraSelectGesture.java', 'CameraSelectPlacement.java')


def added_file(patch, target):
    marker = f'diff --git a/{target} b/{target}\n'
    if marker not in patch:
        raise RuntimeError(f'Missing patched source: {target}')
    block = patch.split(marker, 1)[1].split('\ndiff --git ', 1)[0]
    if '--- /dev/null\n' not in block:
        raise RuntimeError(f'Expected added source: {target}')
    return '\n'.join(line[1:] for line in block.splitlines()
                     if line.startswith('+') and not line.startswith('+++')) + '\n'


def java_tool(name):
    home = os.environ.get('JAVA_HOME')
    if home:
        candidate = Path(home) / 'bin' / (name + ('.exe' if os.name == 'nt' else ''))
        if candidate.is_file():
            return str(candidate)
    found = shutil.which(name)
    if not found:
        raise RuntimeError('Set JAVA_HOME to a JDK or add java and javac to PATH.')
    return found


def main():
    patch = (ROOT / 'changes.patch').read_text(encoding='utf-8')
    scratch = ROOT / 'work'
    scratch.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='gesture-tests-', dir=scratch) as directory:
        temporary = Path(directory).resolve()
        if temporary.parent != scratch.resolve():
            raise RuntimeError('Unexpected temporary directory')
        sources = []
        for name in SOURCES:
            source = temporary / name
            source.write_text(added_file(patch, PACKAGE + name), encoding='utf-8')
            sources.append(str(source))
        sources += [str(ROOT / 'tests' / name) for name in
                    ('CameraSelectGestureTest.java', 'CameraSelectPlacementTest.java')]
        classes = temporary / 'classes'
        classes.mkdir()
        subprocess.run([java_tool('javac'), '-encoding', 'UTF-8', '-d', str(classes), *sources], check=True)
        for test in ('CameraSelectGestureTest', 'CameraSelectPlacementTest'):
            subprocess.run([java_tool('java'), '-cp', str(classes), test], check=True)


if __name__ == '__main__':
    main()
