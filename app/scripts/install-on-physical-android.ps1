param(
    [string]$Apk = (Join-Path $PSScriptRoot '..\build\app\outputs\flutter-apk\app-debug.apk')
)

$adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
if (-not (Test-Path -LiteralPath $adb)) { throw 'Không tìm thấy Android SDK platform-tools/adb.exe.' }
$apkPath = (Resolve-Path -LiteralPath $Apk -ErrorAction Stop).Path

$lines = & $adb devices
$physical = @($lines | Where-Object { $_ -match '^([^\s]+)\s+device$' -and $Matches[1] -notmatch '^emulator-' } | ForEach-Object { ($_ -split '\s+')[0] })
if ($physical.Count -ne 1) {
    throw "Cần đúng một điện thoại Android đã bật USB debugging và được ADB cho phép; hiện thấy $($physical.Count). Chạy 'adb devices' để kiểm tra."
}

$serial = $physical[0]
$model = (& $adb -s $serial shell getprop ro.product.model).Trim()
$version = (& $adb -s $serial shell getprop ro.build.version.release).Trim()
Write-Output "Thiết bị: $model; Android $version"

& $adb -s $serial install -r $apkPath
if ($LASTEXITCODE -ne 0) { throw 'Cài APK không thành công.' }

& $adb -s $serial shell monkey -p com.checkluadao.app_checkluadao_ttnt -c android.intent.category.LAUNCHER 1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Không mở được CheckLuaDao.' }
Write-Output 'Đã cài và mở CheckLuaDao. Tiếp tục checklist trong docs/PHYSICAL_DEVICE_SMOKE_TEST.md.'
