#!/bin/bash
# record_remote_linux.sh <host> <scenario.py> <output-dir> [timeout-seconds]
# Plays a recording scenario on a Linux host (remote-hosts skill) and copies the take here.
#
# The Linux recorder writes JPEG frames with their real timing into
# <output>.frames/ on the host and encodes nothing: this host has no ffmpeg and its
# GStreamer has no H.264 encoder (see ../linux/recorder.py). So the frames are pulled to this
# machine and encoded with ffmpeg here, into <scenario name>-<host os>.mp4, with the scenario
# log next to it. The frames are removed from the host afterwards.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
R="$here/../../remote-hosts/scripts/remote.sh"
host=${1:?host}; scenario=${2:?scenario.py}; out=${3:?output dir}; timeout=${4:-600}
name=$(basename "$scenario"); name=${name%.*}
os=$("$R" hosts | awk -v h="$host" '$1 == h { print $2 }')
[ -n "$os" ] || { echo "unknown host $host" >&2; exit 2; }
[ "$os" = linux ] || { echo "$host is a $os host; use record_remote.sh for Windows" >&2; exit 2; }
mkdir -p "$out"
video="$name-$os.mp4"
log="$out/$name-$os.log"

"$R" "$host" setup
# `desktop` passes no arguments, so a stub runs the scenario with --record; the scenario
# still sees its own path as __file__ and names the take after itself.
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
stub="$tmp/$name.record.py"
cat > "$stub" <<PY
import os, runpy, sys
scenario = os.path.join(os.path.dirname(os.path.abspath(__file__)), '$(basename "$scenario")')
sys.argv = [scenario, '--record']
runpy.run_path(scenario, run_name='__main__')
PY
"$R" "$host" push "$scenario"
"$R" "$host" desktop "$stub" "$timeout" | tee "$log"
"$R" "$host" exec "rm -f \"\$REMOTE_SCRATCH/$name.record.py\""
dir=$(grep -m1 '^RECORD_FRAMES ' "$log" | awk '{print $2}') || true
if [ -z "${dir:-}" ]; then
  echo "the scenario recorded no frames; see $log" >&2
  exit 1
fi
# scp does not keep mtimes, and they are the frames' timing: list them first.
"$R" "$host" exec "cd '$dir' && find . -maxdepth 1 -name '*.jpg' -printf '%f %T@\\n' > times.txt"
"$R" "$host" pull "$(basename "$dir")" "$tmp/frames"
python3 "$here/linux/recorder.py" encode "$tmp/frames" "$out/$video"
"$R" "$host" exec "rm -rf '$dir'"
chmod 644 "$out/$video"   # scp can leave odd permission bits behind
echo "Saved $out/$video"
if grep -q "ERROR" "$log"; then
  echo "the scenario reported an error; the video shows where" >&2
  exit 1
fi
