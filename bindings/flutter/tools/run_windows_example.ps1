param(
  [ValidateSet('desktop', 'window', 'menu', 'tray')]
  [string]$Example = 'desktop',
  [switch]$WinUI3,
  [switch]$BuildOnly
)
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path "$PSScriptRoot/..").Path
$core = Join-Path $repo 'packages/cnativeapi/cxx_impl'
$paths = @{
  desktop = 'packages/nativeapi/example'
  window = 'examples/window_example'
  menu = 'examples/menu_example'
  tray = 'examples/tray_icon_example'
}
$names = @('NATIVEAPI_ENABLE_WINUI3', 'NATIVEAPI_WINAPPSDK_DIR',
           'NATIVEAPI_CPPWINRT_EXE', 'NATIVEAPI_WEBVIEW2_DIR')
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  $env:NATIVEAPI_ENABLE_WINUI3 = if ($WinUI3) { 'ON' } else { 'OFF' }
  if ($WinUI3) {
    $packages = Join-Path $repo 'build/winui3-packages'
    & "$core/cmake/RestoreWinUI3.ps1" -Destination $packages
    $env:NATIVEAPI_WINAPPSDK_DIR = "$packages/winappsdk"
    $env:NATIVEAPI_CPPWINRT_EXE = "$packages/cppwinrt/bin/cppwinrt.exe"
    $env:NATIVEAPI_WEBVIEW2_DIR = "$packages/webview2"
  }
  Push-Location (Join-Path $repo $paths[$Example])
  try {
    $flutterArgs = if ($BuildOnly) { @('build', 'windows', '--debug') } else { @('run', '-d', 'windows') }
    if ($Example -eq 'desktop') { $flutterArgs += @('--target', 'lib/desktop_features.dart') }
    & flutter @flutterArgs
    if ($LASTEXITCODE -ne 0) { throw "Flutter exited with code $LASTEXITCODE" }
  } finally { Pop-Location }
} finally {
  foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
