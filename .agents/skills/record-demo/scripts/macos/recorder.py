"""Records the main display on macOS and converts the capture to an X-ready MP4.

    import sys; sys.path.insert(0, '.agents/skills/record-demo/scripts/macos')
    from recorder import Recorder

    recorder = Recorder('demo.mp4')
    recorder.start()            # raises SystemExit with a hint when permission is missing
    try:
        ...                     # play the scenario
    finally:
        recorder.stop()
    recorder.convert()          # H.264 High, yuv420p, 60 fps, fits 1920x1200, no audio

The process that runs this needs Screen Recording permission (System Settings >
Privacy & Security). Uses `screencapture -v` (cursor and click highlights included),
then ffmpeg, falling back to avconvert.
"""

import os
import signal
import subprocess
import time


def pause(seconds):
    time.sleep(seconds)


PERMISSION_HINT = ('Could not record the screen. Give this terminal Screen Recording permission '
                   '(System Settings > Privacy & Security > Screen Recording), restart it, and '
                   'try again.')


class Recorder:
    """Records the main display with screencapture and converts it to MP4."""

    def __init__(self, output, display=1):
        self.output = os.path.abspath(output)
        self.display = display
        self.movie = os.path.splitext(self.output)[0] + '.capture.mov'
        self.proc = None

    def start(self):
        if os.path.exists(self.movie):
            os.remove(self.movie)
        self.proc = subprocess.Popen(
            ['screencapture', '-x', '-v', '-C', '-k', f'-D{self.display}', self.movie],
            stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        pause(2.0)  # recording starts after a short delay
        if self.proc.poll() is not None:
            raise SystemExit(PERMISSION_HINT)

    def stop(self):
        if not self.proc:
            return
        if self.proc.poll() is None:
            # SIGINT ends the movie at once and finalizes it. (Typing a key on stdin, as
            # the man page suggests, is ignored when stdin is a pipe: the recording then
            # runs on until a timeout and the video ends in half a minute of dead screen.)
            self.proc.send_signal(signal.SIGINT)
            self.proc.wait(30)
        if not os.path.exists(self.movie) or os.path.getsize(self.movie) == 0:
            raise SystemExit(PERMISSION_HINT)

    def convert(self):
        if subprocess.run(['which', 'ffmpeg'], capture_output=True).returncode == 0:
            # X accepts H.264 up to 1920x1200 and 60 fps.
            scale = ('scale=w=1920:h=1200:force_original_aspect_ratio=decrease,'
                     'scale=trunc(iw/2)*2:trunc(ih/2)*2,fps=60')
            subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', self.movie,
                            '-vf', scale, '-c:v', 'libx264', '-preset', 'slow', '-crf', '18',
                            '-profile:v', 'high', '-pix_fmt', 'yuv420p',
                            '-movflags', '+faststart', '-an', self.output], check=True)
        else:
            subprocess.run(['avconvert', '--preset', 'Preset1920x1080', '--replace',
                            '--source', self.movie, '--output', self.output], check=True)
        os.remove(self.movie)
        print(f'Saved {self.output}')
