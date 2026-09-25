#!/usr/bin/env bash
# core_tray_icon_events_test_linux.sh — the Linux tray icon's menu export and click events,
# driven the way the shell drives them: over D-Bus. A StatusNotifierItem is clicked by the
# host calling its methods (gnome-shell's AppIndicator extension: Activate on a double
# click, the menu on a single one; KDE: Activate on a click, ContextMenu on a right click),
# so calling those methods is the click, minus the pointer the input driver may not send
# to the top bar. Checks that the menu is exported for the host to show, that the host's
# dbusmenu events come back as menu events (opened, closed, an item's click), that each
# call reaches the app as the event it stands for, and that the calls with no event yet
# (SecondaryActivate, Scroll) report nothing.
#
#   $R linux run tools/gui/build_core_example_linux.sh tray_icon_example
#   $R linux desktop tools/gui/core_tray_icon_events_test_linux.sh 60
set -uo pipefail
source "$(dirname "$0")/env.sh"
exe="$REMOTE_SCRATCH/core-build/examples/tray_icon_example/tray_icon_example"
log="$REMOTE_SCRATCH/tray_icon_events.log"
failures=0

"$exe" > "$log" 2>&1 &
pid=$!
trap 'kill $pid 2>/dev/null' EXIT

item=""
for _ in $(seq 20); do
  item=$(gdbus call --session --dest org.kde.StatusNotifierWatcher \
      --object-path /StatusNotifierWatcher \
      --method org.freedesktop.DBus.Properties.Get \
      org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null \
    | grep -o "org\.kde\.StatusNotifierItem-$pid-[0-9]*" | head -1)
  [ -n "$item" ] && break
  sleep 0.5
done
if [ -z "$item" ]; then
  echo "FAIL the shell lists the icon"
  exit 1
fi
echo "PASS the shell lists the icon ($item)"

call() {
  gdbus call --session --dest "$item" --object-path /StatusNotifierItem \
    --method "org.kde.StatusNotifierItem.$1" "${@:2}" > /dev/null
}

# The events the app printed since the last step, as a space-separated list in $got.
seen=0
events() {
  sleep 0.8  # well past the double-click time, so steps do not pair up
  local all
  all=$(grep -o 'TRAY ICON [A-Z]* CLICKED' "$log" | awk '{print $3}')
  got=$(echo "$all" | tail -n +$((seen + 1)) | paste -sd' ' -)
  seen=$(echo "$all" | grep -c .)
}

check() {  # check <what> <expected> <got>
  if [ "$2" = "$3" ]; then
    echo "PASS $1: ${3:-nothing}"
  else
    echo "FAIL $1: expected '${2:-nothing}', got '${3:-nothing}'"
    failures=$((failures + 1))
  fi
}

# The example sets a menu with the RightClicked trigger: exported for the host to show on
# a secondary click (GNOME shows an empty one without it), but not as ItemIsMenu.
prop() {
  gdbus call --session --dest "$item" --object-path /StatusNotifierItem \
    --method org.freedesktop.DBus.Properties.Get org.kde.StatusNotifierItem "$1"
}
check "the menu is exported" "(<objectpath '/StatusNotifierItem/Menu'>,)" "$(prop Menu)"
check "ItemIsMenu is off" "(<false>,)" "$(prop ItemIsMenu)"
layout=$(gdbus call --session --dest "$item" --object-path /StatusNotifierItem/Menu \
  --method com.canonical.dbusmenu.GetLayout -- 0 -1 '[]')
for label in 'Settings...' 'About' 'Exit'; do
  case "$layout" in
    *"'label': <'$label'>"*) check "the menu has \"$label\"" "yes" "yes" ;;
    *) check "the menu has \"$label\"" "yes" "no" ;;
  esac
done
# gnome-shell's extension reads WindowId as an int32 and warns about anything else.
check "WindowId is an int32" "(<0>,)" "$(prop WindowId)"

# The host shows the exported menu itself and tells the app through dbusmenu events.
menu_event() {  # menu_event <id> <opened|closed|clicked>
  gdbus call --session --dest "$item" --object-path /StatusNotifierItem/Menu \
    --method com.canonical.dbusmenu.Event -- "$1" "$2" '<0>' 0 > /dev/null
}
menu_lines() {  # the number of lines the app printed so far that match $1
  sleep 0.5
  grep -c "$1" "$log"
}
menu_event 0 opened; menu_event 0 opened
check "\"opened\" on the root is one MenuOpened, however often it comes" "1" "$(menu_lines 'Tray menu opened')"
settings=$(echo "$layout" | grep -o "([0-9]*, {[^}]*'label': <'Settings...'>" | grep -o '^([0-9]*' | tr -d '(')
menu_event "${settings:-0}" clicked
check "\"clicked\" on an item is its click" "1" "$(menu_lines 'Settings clicked from context menu')"
menu_event 0 closed; menu_event 0 closed
check "\"closed\" on the root is one MenuClosed" "1" "$(menu_lines 'Tray menu closed')"

# gdbus is not gnome-shell: these are the calls of any other host (KDE). gnome-shell's
# Activate is a double click, which only a real click in the top bar can show.
call Activate 10 10
events
check "Activate is a click" "LEFT" "$got"

call Activate 10 10; call Activate 10 10
events
check "two quick Activates are a click, then a double click" "LEFT DOUBLE" "$got"

call Activate 10 10; call Activate 10 10; call Activate 10 10
events
check "a third quick Activate starts a new pair" "LEFT DOUBLE LEFT" "$got"

call Activate 10 10; sleep 1; call Activate 10 10
events
check "two slow Activates are two clicks" "LEFT LEFT" "$got"

call ContextMenu 10 10
events
check "ContextMenu is a right click" "RIGHT" "$got"

call SecondaryActivate 10 10; call Scroll 1 vertical
events
check "SecondaryActivate and Scroll report nothing" "" "$got"

if ! kill -0 $pid 2>/dev/null; then
  echo "FAIL the app is still running"
  failures=$((failures + 1))
fi

echo "$failures failure(s)"
exit $((failures > 0))
