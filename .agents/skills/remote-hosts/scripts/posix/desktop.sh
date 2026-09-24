#!/bin/bash
# desktop.sh <linux|macos> <script in this directory> [timeout-seconds]
# Runs a script (.sh or .py) inside the logged-on desktop session instead of the bare SSH
# session, captures everything it prints in job.log, waits, and reports the exit code.
#   linux: the X session named by REMOTE_DISPLAY (default :0) of the same user
#   macos: the user's Aqua session, through `launchctl asuser`
here=$(cd "$(dirname "$0")" && pwd)
. "$here/env.sh"
os=$1; script="$here/$2"; timeout=${3:-600}
log="$here/job.log"; rm -f "$log"

case "$script" in
  *.py) cmd=("$PYTHON" "$script") ;;
  *)    cmd=(bash "$script") ;;
esac
if [ "$os" = linux ]; then
  # The desktop session imports its environment into the systemd user manager (GNOME,
  # KDE and most others do): take the Wayland socket, X display and cookie from there.
  while IFS= read -r kv; do
    case "$kv" in
      DISPLAY=*|XAUTHORITY=*|WAYLAND_DISPLAY=*|XDG_SESSION_TYPE=*|XDG_CURRENT_DESKTOP=*|XDG_RUNTIME_DIR=*|DBUS_SESSION_BUS_ADDRESS=*)
        export "$kv" ;;
    esac
  done < <(systemctl --user show-environment 2>/dev/null)
  export DISPLAY="${DISPLAY:-${REMOTE_DISPLAY:-:0}}"
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"
  # The cookie is wherever the display manager put it (GDM Xorg: /run/user/<uid>/gdm/Xauthority,
  # GNOME Wayland's Xwayland: /run/user/<uid>/.mutter-Xwaylandauth.*): read it off the X server.
  if [ -z "${XAUTHORITY:-}" ]; then
    auth=$(pgrep -a -u "$(id -u)" -f "X(org|wayland) $DISPLAY( |$)" | sed -n 's/.* -auth \([^ ]*\).*/\1/p' | head -n1)
    [ -n "$auth" ] || { [ -f "$HOME/.Xauthority" ] && auth="$HOME/.Xauthority"; }
    [ -z "$auth" ] || export XAUTHORITY="$auth"
  fi
elif [ "$os" = macos ]; then
  cmd=(launchctl asuser "$(id -u)" "${cmd[@]}")
fi

start=$(date +%s)
"${cmd[@]}" > "$log" 2>&1 &
pid=$!
while kill -0 "$pid" 2>/dev/null; do
  if [ $(( $(date +%s) - start )) -ge "$timeout" ]; then
    cat "$log"
    echo "[desktop] TIMEOUT after ${timeout}s - the job (pid $pid) may still be running"
    exit 1
  fi
  sleep 1
done
wait "$pid"; code=$?
cat "$log"
echo "[desktop] finished after $(( $(date +%s) - start ))s, exit $code"
exit "$code"
