---
name: remote-hosts
description: Build, run, and GUI-test on another machine over SSH — the user's Windows laptop today, Linux or other macOS machines tomorrow — with one symmetric CLI for every OS: push scripts, run them either in the bare SSH session or inside the real logged-on desktop session (needed for anything with windows, input, screen capture, and on Windows even for builds), and pull results back. Use this whenever a task says "test on Windows/Linux/the other Mac", "does it work on <platform>", "build it there", "record on Windows", or needs to verify a platform-specific change on real hardware, even if the user only mentions the other machine in passing. It knows the traps per OS (Windows session 0, GBK output and PowerShell 5.1 encodings; X11 vs Wayland; macOS TCC) and how to leave the remote checkout clean.
---

# remote-hosts

Every remote machine is a **host**: a name, an OS, an SSH target, and a few paths, in
`hosts/<name>.env`. The directory is git-ignored (the repo is public — keep real
addresses out of commits); templates for each OS are in `hosts.example/`. Everything
goes through one script with the same verbs on every OS:

```bash
R=.agents/skills/remote-hosts/scripts/remote.sh
$R hosts                                   # what is configured: name, os, ssh target
$R <host> setup                            # once per session: scratch dir, env file, helper kit
$R <host> exec '<snippet>'                 # quick command in the SSH session (PowerShell / bash)
$R <host> run my_script.ps1|.sh|.py [args] # push + run in the SSH session
$R <host> desktop my_gui_test.ps1 400      # push + run in the logged-on desktop session, wait <= 400 s
$R <host> pull frames ./frames             # copy results back from the scratch dir
```

If the host the user means is not configured, ask for its SSH target and paths and
create `hosts/<name>.env` from the matching template; key-based SSH login must
already work (`ssh -o BatchMode=yes <target> echo ok`).

## The model (same on every OS)

- **Scratch directory** on the host: everything you push lands there, flat. Put build
  trees and results there too — never in the host's checkout.
- **Env file**, written by `setup`, loaded first by every script: `env.ps1`
  (`$RemoteWorkspace`, `$RemoteScratch`, `$Python`) on Windows, `env.sh`
  (`REMOTE_WORKSPACE`, `REMOTE_SCRATCH`, `PYTHON`) elsewhere; both apply
  `HOST_PATH_PREPEND`.
- **Kit**, pushed by `setup` by convention, so skills stay symmetric without a list to
  maintain: every skill's `scripts/<os>/*` (plus `scripts/posix/*` on Linux and
  macOS) and every portable `scripts/*.py`. A new OS-specific helper dropped into
  `<skill>/scripts/<os>/` is picked up automatically. Re-run `setup` after editing
  kit files. `run`/`desktop` push only the one script you name, so keep test scripts
  self-contained apart from the kit (or `push` extra files first).
- **Two places a script can run.** The *SSH session* has no desktop on any OS: use
  it for git, files, logs, and (except on Windows) builds. The *desktop session* is
  where windows, input and screen capture work; `desktop` gets a script in there
  (Windows: one-shot scheduled task; Linux: the X session's environment; macOS:
  `launchctl asuser`), captures everything it prints, waits, and ends with
  `[desktop] finished after Ns, exit C`. It needs the user logged on at the console
  and cannot unlock a screen. Output goes through one shared `job.log` in the scratch
  dir, so two sessions driving the same host at once read each other's output — check
  `ls -lt` in the scratch dir for fresh files before assuming a host is yours alone. On `TIMEOUT` the job may still be running — check
  before starting another, since both would fight over the mouse. For long jobs write
  progress to a file in the scratch dir and poll it with `exec`.

Then read the notes for the host's OS — this is where the hours go:

| OS | Notes | Status |
| --- | --- | --- |
| Windows | [references/windows.md](references/windows.md) — session 0, encodings, MSBuild, fvm, CRLF | verified, used for real test and recording runs |
| Linux | [references/linux.md](references/linux.md) — X11 vs Wayland, XAUTHORITY | designed, not yet run on a real host |
| macOS | [references/macos.md](references/macos.md) — TCC for SSH-launched input/capture | designed, not yet run on a remote host |

When you bring up a Linux or macOS host for the first time, expect to fix things, and
write what you learn into its reference file.

## The host's checkout

- Same repository layout as here. Get changes there with `git pull` in each repo; for
  unpushed commits or an unreliable network, fetch between checkouts on the host, or
  `scp` a patch / the changed files.
- **Leave it as you found it.** Record `git status --short` of every repo you will
  touch *before* you start; at the end `git checkout --` only the files you changed and
  compare. Pre-existing local changes on that machine are the user's — do not revert
  them.

## After the work

Fix what the test found in the local checkout, copy the changed files over to re-test,
and only then commit locally. Clean up big artifacts in the scratch dir (`frames/`,
build trees) when the user is done with them — ask before deleting builds that take
minutes to recreate. Report per host what actually ran there.
