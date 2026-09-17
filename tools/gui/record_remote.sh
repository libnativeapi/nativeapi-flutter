#!/bin/bash
# record_remote.sh <host> <scenario.ps1> [timeout-seconds]
# Plays a *_demo.ps1 scenario on a remote host (remote-hosts skill), pulls the captured
# frames, and encodes them to  tools/gui/output/<scenario name>-<host os>.full.mp4
# The scenario must record into  $RemoteScratch\<scenario name>.frames .
# Trim the result with the record-demo skill's video.py into <scenario name>-<host os>.mp4.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
skills="$here/../../.agents/skills"
R="$skills/remote-hosts/scripts/remote.sh"
V="$skills/record-demo/scripts/video.py"
host=${1:?host}; scenario=${2:?scenario.ps1}; timeout=${3:-400}
name=$(basename "$scenario"); name=${name%.*}
os=$("$R" hosts | awk -v h="$host" '$1 == h { print $2 }')
[ -n "$os" ] || { echo "unknown host $host" >&2; exit 2; }
out="$here/output"; mkdir -p "$out"
frames="$out/$name-$os.frames"

"$R" "$host" setup
"$R" "$host" desktop "$scenario" "$timeout" | tee "$out/$name-$os.log"
grep -q "ERROR" "$out/$name-$os.log" && { echo "the scenario reported an error; not encoding" >&2; exit 1; }
rm -rf "$frames"
"$R" "$host" pull "$name.frames" "$frames"
# Keep the previous take: a new one is not always better (busy desktop, glitch).
[ ! -f "$out/$name-$os.full.mp4" ] || mv "$out/$name-$os.full.mp4" "$out/$name-$os.full.prev.mp4"
"$V" encode-frames "$frames" "$out/$name-$os.full.mp4"
rm -rf "$frames"
"$R" "$host" exec "Remove-Item \"\$RemoteScratch\\$name.frames\" -Recurse -Force"
echo "Saved $out/$name-$os.full.mp4 — trim it with video.py (scenes / sheet / cut) into $name-$os.mp4"
