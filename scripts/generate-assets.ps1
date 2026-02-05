<#
generate-assets.ps1

Generates PNG assets from the SVG sources in ./assets.
Tries ImageMagick `magick` first, then falls back to `npx sharp` if Node is available.

Outputs:
 - icons: icon-192-maskable.png, icon-512-maskable.png
 - adaptive layers: adaptive-foreground-512.png, adaptive-background-512.png
 - iOS splash images (multiple sizes) like apple-splash-2048x2732.png

Usage:
 1. Run in repo root: powershell -ExecutionPolicy Bypass -File .\scripts\generate-assets.ps1
 2. If using Node: `npm install sharp-cli --no-save` may be required
#>

$repo = (Get-Location).Path
$assets = Join-Path $repo 'assets'
$out = Join-Path $repo '.'

$svgs = @{ 
  foreground = Join-Path $assets 'icon-foreground.svg'
  background = Join-Path $assets 'icon-background.svg'
  splash = Join-Path $assets 'apple-splash.svg'
}

$sizes = @(
  @{ name='icon-192-maskable.png'; w=192; h=192 },
  @{ name='icon-512-maskable.png'; w=512; h=512 },
  @{ name='adaptive-foreground-512.png'; w=512; h=512 },
  @{ name='adaptive-background-512.png'; w=512; h=512 }
)

$splashSizes = @(
  @{ name='apple-splash-2048x2732.png'; w=2048; h=2732 },
  @{ name='apple-splash-1668x2388.png'; w=1668; h=2388 },
  @{ name='apple-splash-1536x2048.png'; w=1536; h=2048 },
  @{ name='apple-splash-1125x2436.png'; w=1125; h=2436 },
  @{ name='apple-splash-1242x2688.png'; w=1242; h=2688 },
  @{ name='apple-splash-828x1792.png'; w=828; h=1792 },
  @{ name='apple-splash-640x1136.png'; w=640; h=1136 }
)

function Run-Magick($infile, $output, $w, $h) {
  if (Get-Command magick -ErrorAction SilentlyContinue) {
    Write-Host "magick convert $infile -resize ${w}x${h} $output"
    & magick convert $infile -resize ${w}x${h} $output
    return $LASTEXITCODE -eq 0
  }
  return $false
}

function Run-Sharp($infile, $output, $w, $h) {
  if (Get-Command npx -ErrorAction SilentlyContinue) {
    $temp = Join-Path $env:TEMP "sharp-out"
    New-Item -ItemType Directory -Force -Path $temp | Out-Null
    $base = [System.IO.Path]::GetFileNameWithoutExtension($infile)
    Write-Host "npx sharp -i $infile -o $temp resize $w $h"
    & npx sharp -i $infile -o $temp resize $w $h
    if ($LASTEXITCODE -ne 0) { return $false }
    $generated = Join-Path $temp "${base}.png"
    if (-Not (Test-Path $generated)) { return $false }
    Move-Item -Force $generated $output
    return $true
  }
  return $false
}

# Create outputs
foreach ($s in $sizes) {
  $outPath = Join-Path $out $s.name
  $src = if ($s.name -like 'adaptive-background*') { $svgs.background } else { $svgs.foreground }
  $ok = Run-Magick $src $outPath $s.w $s.h
  if (-not $ok) { $ok = Run-Sharp $src $outPath $s.w $s.h }
  if ($ok) { Write-Host "Generated $outPath" } else { Write-Warning "Failed to generate $outPath. Install ImageMagick or Node+sharp-cli to generate." }
}

foreach ($s in $splashSizes) {
  $outPath = Join-Path $out $s.name
  $ok = Run-Magick $svgs.splash $outPath $s.w $s.h
  if (-not $ok) { $ok = Run-Sharp $svgs.splash $outPath $s.w $s.h }
  if ($ok) { Write-Host "Generated $outPath" } else { Write-Warning "Failed to generate $outPath. Install ImageMagick or Node+sharp-cli to generate." }
}

Write-Host 'Done. Add generated PNGs to manifest/index.html where required and commit them.'