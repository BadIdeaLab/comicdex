#requires -Version 5.1
<#
.SYNOPSIS
    由 App 圖示產生桌面端的 windows/runner/resources/app_icon.ico（多尺寸）。

.DESCRIPTION
    來源是主 App 的 assets/icon/icon.png，所以桌面端的 exe 圖示和手機端永遠一致，
    不會有兩份各自演化的圖檔。

    刻意產成多尺寸而不是單張 256：Windows 會用 16 px 畫工作列、24 px 畫檔案總管
    詳細清單。只給一張 256 的話那些尺寸全靠即時縮圖，細節多的圖會糊掉。這裡預先
    用高品質縮放產好每個尺寸，讓系統直接挑最合適的那張。

    ICO 內每張圖以 PNG 存放（Windows Vista 起支援），256 的那張若用 BMP 會多出
    近 300 KB。

.EXAMPLE
    powershell -File scripts\build_desktop_icon.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $repoRoot 'assets\icon\icon.png'
$targetPath = Join-Path $repoRoot 'desktop_backup_server\windows\runner\resources\app_icon.ico'

if (-not (Test-Path $sourcePath)) { throw "找不到來源圖示：$sourcePath" }

# ICO 目錄項的寬高各只有一個 byte，256 要以 0 表示，所以不能超過 256。
$sizes = @(16, 24, 32, 48, 64, 128, 256)

$source = [System.Drawing.Image]::FromFile($sourcePath)
Write-Host "來源 $($source.Width)x$($source.Height)  ->  $($sizes -join ', ')" -ForegroundColor Cyan

$pngBlobs = @()
try {
    foreach ($size in $sizes) {
        $bitmap = New-Object System.Drawing.Bitmap($size, $size)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.DrawImage($source, 0, 0, $size, $size)
        } finally {
            $graphics.Dispose()
        }

        $stream = New-Object System.IO.MemoryStream
        try {
            $bitmap.Save($stream, [System.Drawing.Imaging.ImageFormat]::Png)
            $pngBlobs += , $stream.ToArray()
        } finally {
            $stream.Dispose()
            $bitmap.Dispose()
        }
    }
} finally {
    $source.Dispose()
}

$output = New-Object System.IO.MemoryStream
$writer = New-Object System.IO.BinaryWriter($output)
try {
    # ICONDIR：保留欄位、類型 1（圖示）、張數
    $writer.Write([uint16]0)
    $writer.Write([uint16]1)
    $writer.Write([uint16]$sizes.Count)

    # 每個目錄項 16 bytes，影像資料接在全部目錄項之後
    $offset = 6 + (16 * $sizes.Count)
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $size = $sizes[$i]
        $blob = $pngBlobs[$i]
        $dimension = if ($size -ge 256) { 0 } else { $size }

        $writer.Write([byte]$dimension)      # 寬
        $writer.Write([byte]$dimension)      # 高
        $writer.Write([byte]0)               # 調色盤色數（0 = 不使用）
        $writer.Write([byte]0)               # 保留
        $writer.Write([uint16]1)             # 色彩平面
        $writer.Write([uint16]32)            # 每像素位元數
        $writer.Write([uint32]$blob.Length)
        $writer.Write([uint32]$offset)
        $offset += $blob.Length
    }

    foreach ($blob in $pngBlobs) { $writer.Write($blob) }
    $writer.Flush()

    [System.IO.File]::WriteAllBytes($targetPath, $output.ToArray())
} finally {
    $writer.Dispose()
    $output.Dispose()
}

$kb = [math]::Round((Get-Item $targetPath).Length / 1KB, 1)
Write-Host "完成：$targetPath（$($sizes.Count) 種尺寸，$kb KB）" -ForegroundColor Green
Write-Host '  改完圖示要重新 flutter build windows 才會套用。'
