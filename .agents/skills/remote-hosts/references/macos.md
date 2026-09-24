# macOS hosts

**Status: designed, not yet run against a remote Mac.** `desktop.sh` (including
`launchctl asuser`) was exercised on the local Mac only. Verify each step the first
time and update this file.

For the Mac you are already on, do not use this skill: run things directly.

## Two places a script can run

**SSH session (`exec`, `run`)**: needs Remote Login enabled (System Settings ›
General › Sharing). Runs outside the user's Aqua session: no window server access
for many APIs. Fine for git, builds, logs.

**Logged-on desktop (`desktop`)**: `scripts/posix/desktop.sh` starts the script with
`launchctl asuser <uid>`, which places it in the logged-on user's GUI bootstrap
namespace so apps it launches appear on screen. The same user must be logged on.

Scripts start with:

```bash
. "$(dirname "$0")/env.sh"      # REMOTE_WORKSPACE, REMOTE_SCRATCH, PYTHON, PATH additions
```

## Expected traps

- **TCC permissions follow the responsible process.** Synthetic input (Accessibility)
  and `screencapture` (Screen Recording) are granted per app; for an SSH-launched
  chain the responsible process is `sshd-keygen-wrapper` (`/usr/libexec/`), which has
  to be added in System Settings › Privacy & Security on that Mac by its user. Without
  it, input calls succeed silently and nothing moves; `screencapture` exits at once.
- The keychain is locked in SSH sessions: code signing during `flutter build macos`
  may prompt or fail; build with the user logged on, or `security unlock-keychain`.
- `gui-test`'s macOS driver compiles `input.m` on first use: Xcode command line tools
  must be installed on the host.
