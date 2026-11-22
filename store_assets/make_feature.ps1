[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Drawing

$bmp = New-Object System.Drawing.Bitmap(1024, 500)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

$rect = New-Object System.Drawing.Rectangle(0, 0, 1024, 500)
$c1 = [System.Drawing.ColorTranslator]::FromHtml('#081912')
$c2 = [System.Drawing.ColorTranslator]::FromHtml('#14422D')
$brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, 45.0)
$g.FillRectangle($brush, $rect)

# Gold borders
$goldColor = [System.Drawing.ColorTranslator]::FromHtml('#D4AF37')
$goldPen = New-Object System.Drawing.Pen($goldColor, 3.0)
$innerRect = New-Object System.Drawing.Rectangle(16, 16, 992, 468)
$g.DrawRectangle($goldPen, $innerRect)

$accentColor = [System.Drawing.ColorTranslator]::FromHtml('#66D4AF37')
$accentPen = New-Object System.Drawing.Pen($accentColor, 1.2)
$accentRect = New-Object System.Drawing.Rectangle(24, 24, 976, 452)
$g.DrawRectangle($accentPen, $accentRect)

# Draw app icon
$iconPath = Join-Path $PSScriptRoot "icon_512x512.png"
if (Test-Path $iconPath) {
    $iconImg = [System.Drawing.Image]::FromFile($iconPath)
    $g.DrawImage($iconImg, 70, 90, 320, 320)
    $iconImg.Dispose()
}

# Typography
$titleFont = New-Object System.Drawing.Font("Segoe UI", 48, [System.Drawing.FontStyle]::Bold)
$subFont = New-Object System.Drawing.Font("Segoe UI", 21, [System.Drawing.FontStyle]::Bold)
$badgeFont = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)

$goldBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#FFD54F'))
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#B3000000'))
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#F0F4F8'))

$g.DrawString("ADA BATAK", $titleFont, $shadowBrush, 432, 132)
$g.DrawString("ADA BATAK", $titleFont, $goldBrush, 430, 130)

$g.DrawString("Klasik & Ihaleli Turk Batak Oyunu", $subFont, $whiteBrush, 434, 222)

# Badges
$badgeBg = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0E291E'))
$badgeBorder = New-Object System.Drawing.Pen($goldColor, 1.5)

# Badge 1: 100% Çevrimdışı
$g.FillRectangle($badgeBg, 434, 285, 160, 44)
$g.DrawRectangle($badgeBorder, 434, 285, 160, 44)
$g.DrawString("100% INTERNETSIZ", $badgeFont, $goldBrush, 446, 297)

# Badge 2: 5 Oyun Modu
$g.FillRectangle($badgeBg, 610, 285, 175, 44)
$g.DrawRectangle($badgeBorder, 610, 285, 175, 44)
$g.DrawString("5 FARKLI OYUN MODU", $badgeFont, $goldBrush, 622, 297)

# Badge 3: Gelismis Botlar
$g.FillRectangle($badgeBg, 800, 285, 155, 44)
$g.DrawRectangle($badgeBorder, 800, 285, 155, 44)
$g.DrawString("GELISMIS BOTLAR", $badgeFont, $goldBrush, 814, 297)

$outPath = Join-Path $PSScriptRoot "feature_graphic_1024x500.png"
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)

$g.Dispose()
$bmp.Dispose()
Write-Output "Regenerated: $outPath"
