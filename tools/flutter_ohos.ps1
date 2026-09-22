# Run from any directory with: & <repo>\tools\flutter_ohos.ps1 build hap --debug
# Uses a separate OHOS SDK; standard Flutter/FVM settings are unaffected.
$ErrorActionPreference = 'Stop'
$flutterSdk = $env:FLUTTER_OHOS_HOME
if (-not $flutterSdk) {
    $flutterSdk = Join-Path $env:USERPROFILE 'fvm\versions\ohos-3.35.7'
}
$studio = $env:DEVECO_STUDIO_HOME
if (-not $studio) {
    throw 'Set DEVECO_STUDIO_HOME to your DevEco Studio installation directory.'
}
$flutter = Join-Path $flutterSdk 'bin\flutter.bat'
if (-not (Test-Path $flutter)) {
    throw "OHOS Flutter not found at $flutter. See docs/ohos.md."
}
$names = @('Path', 'FLUTTER_STORAGE_BASE_URL', 'FLUTTER_OHOS_STORAGE_BASE_URL',
    'FLUTTER_GIT_URL', 'DEVECO_SDK_HOME', 'JAVA_HOME', 'NODE_HOME')
$saved = @{}
foreach ($name in $names) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
    if (-not $env:FLUTTER_STORAGE_BASE_URL) { $env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn' }
    if (-not $env:FLUTTER_OHOS_STORAGE_BASE_URL) {
        $env:FLUTTER_OHOS_STORAGE_BASE_URL = 'https://flutter-ohos.obs.cn-south-1.myhuaweicloud.com'
    }
    $env:FLUTTER_GIT_URL = 'https://gitcode.com/CPF-Flutter/flutter_flutter.git'
    $env:DEVECO_SDK_HOME = Join-Path $studio 'sdk'
    $env:JAVA_HOME = Join-Path $studio 'jbr'
    $env:NODE_HOME = Join-Path $studio 'tools\node'
    $paths = @("$flutterSdk\bin", "$studio\tools\node", "$studio\tools\ohpm\bin",
        "$studio\tools\hvigor\bin", "$studio\jbr\bin", "$studio\sdk\default\openharmony\toolchains")
    $env:Path = ($paths -join ';') + ';' + $env:Path
    & $flutter @args
    $result = $LASTEXITCODE
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
exit $result
