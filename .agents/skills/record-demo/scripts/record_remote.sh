#!/bin/bash
# record_remote.sh <host> <scenario.ps1> <output-dir> [timeout-seconds]
# Plays a recording scenario on a remote host (remote-hosts skill) and copies its video here.
# The scenario records and encodes  <scenario name>-<host os>.mp4  in the host's scratch dir
# (see templates/record_template.ps1); it is copied to <output-dir> and removed from the host.
# The scenario log goes next to it as  <scenario name>-<host os>.log .
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
R="$here/../../remote-hosts/scripts/remote.sh"
host=${1:?host}; scenario=${2:?scenario.ps1}; out=${3:?output dir}; timeout=${4:-600}
name=$(basename "$scenario"); name=${name%.*}
os=$("$R" hosts | awk -v h="$host" '$1 == h { print $2 }')
[ -n "$os" ] || { echo "unknown host $host" >&2; exit 2; }
mkdir -p "$out"
video="$name-$os.mp4"
log="$out/$name-$os.log"

"$R" "$host" setup
"$R" "$host" desktop "$scenario" "$timeout" | tee "$log"
if ! grep -q "saved .*$video" "$log"; then
  echo "no video was saved; see $log" >&2
  exit 1
fi
"$R" "$host" pull "$video" "$out/$video"
chmod 644 "$out/$video"  # scp keeps the host's odd Windows permission bits
"$R" "$host" exec "Remove-Item \"\$RemoteScratch\\$video\""
echo "Saved $out/$video"
if grep -q "ERROR" "$log"; then
  echo "the scenario reported an error; the video shows where" >&2
  exit 1
fi
