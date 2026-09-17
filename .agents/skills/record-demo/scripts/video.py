#!/usr/bin/env python3
"""Post-production for demo recordings. Needs ffmpeg/ffprobe on PATH.

    video.py info <in.mp4>
    video.py encode-frames <frames-dir> <out.mp4> [--fps 30] [--size 1920x1080]
        JPEG frames + times.txt ("index milliseconds" per line, as written by
        recorder.ps1) to a constant-frame-rate MP4 that keeps real timing.
    video.py scenes <in.mp4> [--threshold 0.08] [--from S] [--to S]
        Timestamps where the picture changes a lot: windows appearing/closing.
    video.py freezes <in.mp4> [--min 0.8]
        Stretches where nothing moves: dead time to cut.
    video.py sheet <in.mp4> <out.jpg> (--at T,T,… | --every SECONDS) [--width 480] [--cols 6]
        Contact sheet to check cut points by eye (frames in the order given).
    video.py cut <in.mp4> <out.mp4> --keep A-B [--keep C-D …] [--fps 30] [--max 1920x1200]
        Keeps the given ranges (seconds), joins them, and writes an X-ready file:
        H.264 High, yuv420p, faststart, no audio.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, **kw)


def ffmpeg_log(args):
    """Runs ffmpeg for its log output (filters that print metadata)."""
    return subprocess.run(['ffmpeg', '-hide_banner', '-v', 'info', *args, '-an', '-f', 'null', '-'],
                          capture_output=True, text=True).stderr


X_ENCODE = ['-c:v', 'libx264', '-preset', 'slow', '-crf', '18', '-profile:v', 'high',
            '-pix_fmt', 'yuv420p', '-color_range', 'tv', '-movflags', '+faststart', '-an']


def fit(size):
    w, h = size.lower().split('x')
    return (f'scale=w={w}:h={h}:force_original_aspect_ratio=decrease:flags=lanczos,'
            'scale=trunc(iw/2)*2:trunc(ih/2)*2')


def info(a):
    run(['ffprobe', '-v', 'error', '-show_entries',
         'stream=codec_name,profile,pix_fmt,width,height,r_frame_rate:format=duration,size',
         '-of', 'default=nw=1', a.input])


def encode_frames(a):
    rows = [tuple(map(int, line.split())) for line in open(os.path.join(a.frames, 'times.txt'))
            if line.strip()]
    rows = [r for r in rows if os.path.exists(os.path.join(a.frames, f'{r[0]:06d}.jpg'))]
    if len(rows) < 2:
        raise SystemExit('not enough frames')
    with tempfile.NamedTemporaryFile('w', suffix='.txt', delete=False) as f:
        for (i, t), (_, t2) in zip(rows, rows[1:]):
            f.write(f"file '{os.path.abspath(a.frames)}/{i:06d}.jpg'\nduration {(t2 - t) / 1000:.3f}\n")
        last = f"file '{os.path.abspath(a.frames)}/{rows[-1][0]:06d}.jpg'\n"
        f.write(last + 'duration 0.040\n' + last)  # the concat demuxer ignores the last duration
    seconds = (rows[-1][1] - rows[0][1]) / 1000
    print(f'{len(rows)} frames over {seconds:.1f}s = {len(rows) / seconds:.1f} fps captured')
    # JPEG is full-range; convert explicitly or players show washed-out yuvj420p.
    run(['ffmpeg', '-y', '-v', 'error', '-f', 'concat', '-safe', '0', '-i', f.name,
         '-vf', f'fps={a.fps},{fit(a.size)},scale=in_range=pc:out_range=tv,format=yuv420p',
         *X_ENCODE, a.output])
    os.remove(f.name)
    info(argparse.Namespace(input=a.output))


def scenes(a):
    trim = f'trim=start={a.start}:end={a.end},' if a.end else ''
    log = ffmpeg_log(['-i', a.input, '-vf', f"{trim}select='gt(scene,{a.threshold})',metadata=print"])
    times = re.findall(r'pts_time:([\d.]+)', log)
    scores = re.findall(r'scene_score=([\d.]+)', log)
    for t, s in zip(times, scores):
        print(f'{float(t):8.2f}s  score {float(s):.3f}')
    if not times:
        print('no scene changes; lower --threshold (0.02 finds small windows)')


def freezes(a):
    log = ffmpeg_log(['-i', a.input, '-vf', f'freezedetect=n=0.003:d={a.min}', '-map', '0:v'])
    starts = re.findall(r'freeze_start: ([\d.]+)', log)
    ends = re.findall(r'freeze_end: ([\d.]+)', log)
    for i, s in enumerate(starts):
        e = ends[i] if i < len(ends) else 'end'
        print(f'{float(s):8.2f}s – {e if e == "end" else format(float(e), ".2f") + "s"}')


def sheet(a):
    if a.at:
        times = [float(t) for t in a.at.split(',')]
    else:
        duration = float(subprocess.run(
            ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', a.input],
            capture_output=True, text=True, check=True).stdout)
        times = [t * a.every for t in range(int(duration / a.every) + 1)]
    with tempfile.TemporaryDirectory() as tmp:
        for n, t in enumerate(times):
            # No timestamp overlay: drawtext is missing from many ffmpeg builds.
            run(['ffmpeg', '-y', '-v', 'error', '-ss', str(t), '-i', a.input, '-frames:v', '1',
                 '-vf', f'scale={a.width}:-2', f'{tmp}/{n:04d}.jpg'])
        cols = min(a.cols, len(times))
        rows = -(-len(times) // cols)
        run(['ffmpeg', '-y', '-v', 'error', '-framerate', '1', '-i', f'{tmp}/%04d.jpg',
             '-vf', f'tile={cols}x{rows}', '-frames:v', '1', a.output])
    print(f'{a.output}: {cols}x{rows}, left to right then down: '
          + ', '.join(f'{t:.2f}s' for t in times))


def cut(a):
    parts, labels = [], []
    for n, keep in enumerate(a.keep):
        start, end = keep.split('-')
        parts.append(f'[0:v]trim=start={start}:end={end},setpts=PTS-STARTPTS[p{n}]')
        labels.append(f'[p{n}]')
    graph = ';'.join(parts) + f";{''.join(labels)}concat=n={len(labels)}:v=1:a=0," \
        f'{fit(a.max)},format=yuv420p[v]'
    run(['ffmpeg', '-y', '-v', 'error', '-i', a.input, '-filter_complex', graph, '-map', '[v]',
         '-r', str(a.fps), *X_ENCODE, a.output])
    info(argparse.Namespace(input=a.output))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest='cmd', required=True)
    s = sub.add_parser('info'); s.add_argument('input'); s.set_defaults(fn=info)
    s = sub.add_parser('encode-frames'); s.add_argument('frames'); s.add_argument('output')
    s.add_argument('--fps', type=int, default=30); s.add_argument('--size', default='1920x1080')
    s.set_defaults(fn=encode_frames)
    s = sub.add_parser('scenes'); s.add_argument('input')
    s.add_argument('--threshold', type=float, default=0.08)
    s.add_argument('--from', dest='start', type=float, default=0); s.add_argument('--to', dest='end', type=float)
    s.set_defaults(fn=scenes)
    s = sub.add_parser('freezes'); s.add_argument('input'); s.add_argument('--min', type=float, default=0.8)
    s.set_defaults(fn=freezes)
    s = sub.add_parser('sheet'); s.add_argument('input'); s.add_argument('output')
    g = s.add_mutually_exclusive_group(required=True)
    g.add_argument('--at'); g.add_argument('--every', type=float)
    s.add_argument('--width', type=int, default=480); s.add_argument('--cols', type=int, default=6)
    s.set_defaults(fn=sheet)
    s = sub.add_parser('cut'); s.add_argument('input'); s.add_argument('output')
    s.add_argument('--keep', action='append', required=True, metavar='START-END')
    s.add_argument('--fps', type=int, default=30); s.add_argument('--max', default='1920x1200')
    s.set_defaults(fn=cut)
    a = p.parse_args()
    a.fn(a)


if __name__ == '__main__':
    sys.exit(main())
