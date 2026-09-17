# Windows hosts

Verified on a Windows 11 laptop (VS 2022, PowerShell 5.1, OpenSSH server).

## Two places a script can run

**SSH session (`exec`, `run`)** is Windows *session 0*: no desktop, no windows, no
input, no screen. Fine for git, file operations, `cmake` configure, reading logs.

**Logged-on desktop (`desktop`)** runs the script hidden inside the user's interactive
session through a one-shot scheduled task (`schtasks /IT` -> `wscript job.vbs` ->
`powershell job.ps1`, see `scripts/windows/`). Use it for:

- anything that creates windows, sends input, or captures the screen;
- **builds**: a parallel MSBuild (`cmake --build`, `flutter build windows`) hung
  forever in session 0. Build on the desktop too.

It needs the user to be logged on at the console — check with
`remote.sh <host> exec 'Get-Process explorer | Select Id, SessionId'` (a session other
than 0; `query user` is not reachable from the SSH shell). It cannot unlock a locked
screen. Do not name your own script `job.ps1`.

Scripts start with:

```powershell
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\env.ps1"      # $RemoteWorkspace, $RemoteScratch, $Python, PATH additions
```

## Encoding and quoting traps

- The default SSH shell is `cmd` with GBK output. `remote.sh` wraps everything in
  PowerShell with UTF-8 console output; do not call `ssh host "some command"` raw
  and trust the text.
- **Keep `.ps1` files ASCII.** Windows PowerShell 5.1 reads BOM-less scripts in the
  system codepage; a `·` or `…` in a string silently becomes garbage and title
  matches fail. Match window titles with wildcards (`"*Settings"`) instead of
  typing the non-ASCII part.
- Write result files with `Out-File -Encoding utf8`; `*>` redirection writes UTF-16.
- Avoid inline quoting through ssh → cmd → powershell. If a snippet needs quotes
  beyond single quotes, put it in a file and use `run`.
- The scratch path must not contain spaces (it is passed unquoted to `schtasks /TR`).

## The checkout on a Windows host

- Same layout as here (`core/`, `bindings/*` on `main`). Get changes there with
  `git pull` in each repo — but **GitHub over HTTPS is flaky from that network**.
  For unpushed or unreachable commits, fetch between local checkouts instead (for the
  Flutter binding's nested core: `git -C …\cxx_impl fetch $RemoteWorkspace\core main`),
  or `scp` a patch / the changed files.
- Tooling: VS 2022 (generator `"Visual Studio 17 2022" -A x64`; there is no ninja),
  CMake, Python 3, Flutter via fvm. The `fvm\default` junction does not resolve over
  SSH — point `HOST_PATH_PREPEND` at a concrete `fvm\versions\<channel>\bin`. The
  multi-window examples need the `main` channel with `flutter config --enable-windowing`.
- Put CMake build trees in the scratch dir (`-B $RemoteScratch\core-build`), not in the
  checkout.
- `core.autocrlf` makes `git status` noisy and `flutter pub get` rewrites
  `analysis_options.yaml` files. Judge real changes with
  `git diff --ignore-cr-at-eol --stat`.
- **Leave it as you found it.** Record `git status --short` for the workspace,
  `core`, `bindings/flutter` (and its `cxx_impl`) *before* you start; at the end
  `git checkout --` only the files you touched and compare. Pre-existing local
  changes on that machine are the user's — do not revert them.

## Building

```powershell
# core example (desktop session)
cmake -S $RemoteWorkspace\core -B $RemoteScratch\core-build -G "Visual Studio 17 2022" -A x64
cmake --build $RemoteScratch\core-build --config Debug --target <example> -- /m /nologo /v:minimal

# Flutter example (desktop session)
cd $RemoteWorkspace\bindings\flutter; flutter pub get
cd examples\<name>; flutter build windows --debug
# → build\windows\x64\runner\Debug\<name>.exe
```

A cold Flutter Windows build takes several minutes; give `desktop` a generous
timeout (900+).
