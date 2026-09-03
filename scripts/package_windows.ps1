#requires -Version 5.1
<#
.SYNOPSIS
    將 desktop_backup_server 打包成可直接解壓執行的 Windows zip。

.DESCRIPTION
    Flutter 的 Windows 產出不是單一執行檔：exe 只有 90 KB 左右，真正的引擎在
    flutter_windows.dll，Dart 程式碼在 data\app.so。整個 Release 資料夾少一個檔就
    開不起來，所以這裡壓的是整包，而不是挑幾個檔案。

    另外會嘗試把 VC++ 執行階段的三個 DLL 一起放進去（app-local 部署）。沒有它們的
    機器雙擊 exe 會沒有任何反應——這是最常見、也最難自行診斷的失敗方式。

.PARAMETER SkipBuild
    沿用既有的 build 產出，只重新打包。改了打包流程但沒改程式碼時用。

.EXAMPLE
    powershell -File scripts\package_windows.ps1
    powershell -File scripts\package_windows.ps1 -SkipBuild
#>
[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$projectDir = Join-Path $repoRoot 'desktop_backup_server'
$releaseDir = Join-Path $projectDir 'build\windows\x64\runner\Release'
$outDir = Join-Path $PSScriptRoot 'out'

# 版本取自 pubspec，去掉 +build 號。它同時也寫在 exe 的「檔案內容」頁裡，
# 所以檔名和內容頁永遠一致。
$versionLine = Get-Content (Join-Path $projectDir 'pubspec.yaml') |
    Where-Object { $_ -match '^version:' } |
    Select-Object -First 1
if (-not $versionLine) { throw 'pubspec.yaml 裡找不到 version:' }
$version = (($versionLine -replace '^version:\s*', '') -replace '\+.*$', '').Trim()

Write-Host "Comicdex Backup Server $version" -ForegroundColor Cyan

if (-not $SkipBuild) {
    Push-Location $projectDir
    try {
        flutter build windows --release
        if ($LASTEXITCODE -ne 0) { throw "flutter build windows 失敗（exit $LASTEXITCODE）" }
    } finally {
        Pop-Location
    }
}

$exePath = Join-Path $releaseDir 'ComicdexBackupServer.exe'
if (-not (Test-Path $exePath)) {
    throw "找不到 $exePath，請先不要加 -SkipBuild 跑一次。"
}

$stageName = "comicdex-backup-server-$version"
$stageDir = Join-Path $outDir $stageName
if (Test-Path $stageDir) { Remove-Item -Recurse -Force $stageDir }
New-Item -ItemType Directory -Force -Path $stageDir | Out-Null
Copy-Item -Path (Join-Path $releaseDir '*') -Destination $stageDir -Recurse -Force

# VC++ 執行階段：優先用 VS 的 redist 副本（微軟允許隨應用程式散布），
# 找不到就明講，不要靜靜產出一個在別台機器打不開的 zip。
$crtNames = @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')

# 用 vswhere 問 VS 裝在哪，而不是猜 C:\Program Files——這台機器就把 VS 裝在 E 槽，
# 寫死磁碟機代號的版本在這裡靜靜地找不到檔案。vswhere 自己的路徑才是微軟固定的。
$crtDir = $null
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (Test-Path $vswhere) {
    $vsPath = & $vswhere -latest -products * -property installationPath
    if ($vsPath) {
        $crtPattern = Join-Path $vsPath 'VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT'
        $crtDir = Resolve-Path -Path $crtPattern -ErrorAction SilentlyContinue |
            Sort-Object -Property Path |
            Select-Object -Last 1
    }
}

$copiedCrt = @()
if ($crtDir) {
    foreach ($name in $crtNames) {
        $source = Join-Path $crtDir.Path $name
        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $stageDir -Force
            $copiedCrt += $name
        }
    }
}

if ($copiedCrt.Count -eq $crtNames.Count) {
    Write-Host "  已附帶 VC++ 執行階段：$($copiedCrt -join ', ')" -ForegroundColor DarkGray
} else {
    Write-Warning @'
找不到完整的 VC++ 執行階段 DLL，zip 裡不會包含它們。
沒裝 VC++ Redistributable 的機器上，雙擊 exe 會完全沒有反應（不會跳錯誤）。
請一併告知使用者安裝：https://aka.ms/vs/17/release/vc_redist.x64.exe
'@
}

$zipPath = Join-Path $outDir "$stageName-windows-x64.zip"
if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
Compress-Archive -Path $stageDir -DestinationPath $zipPath

$zipMb = [math]::Round((Get-Item $zipPath).Length / 1MB, 1)
Write-Host ''
Write-Host "完成：$zipPath" -ForegroundColor Green
Write-Host "  大小 $zipMb MB，解壓後執行 $stageName\ComicdexBackupServer.exe"
Write-Host '  未簽章，第一次執行會跳 SmartScreen 警告（其他資訊 → 仍要執行）。'
