# Windows installer for recent-tabs.js.
# Installs into (or removes with -Uninstall from) the newest installed Vivaldi version.
# Re-run after every Vivaldi update: updates overwrite window.html.
# Changes take effect after Vivaldi restart.
#
# Set VIVALDI_UI_DIR to point at a specific resources\vivaldi folder instead of auto-detection.

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$modName = 'recent-tabs.js'
$modSrc  = Join-Path $PSScriptRoot $modName
$tag     = "<script src=`"$modName`"></script>"

if ($env:VIVALDI_UI_DIR) {
  $uiDir = $env:VIVALDI_UI_DIR
  Write-Host "Vivaldi UI folder (from VIVALDI_UI_DIR): $uiDir"
} else {
  $roots = @(
    "$env:LOCALAPPDATA\Vivaldi\Application",
    "$env:ProgramFiles\Vivaldi\Application",
    "${env:ProgramFiles(x86)}\Vivaldi\Application"
  ) | Where-Object { $_ -and (Test-Path $_) }

  $versions = foreach ($r in $roots) {
    Get-ChildItem $r -Directory | Where-Object {
      $_.Name -match '^\d+(\.\d+)+$' -and (Test-Path (Join-Path $_.FullName 'resources\vivaldi\window.html'))
    }
  }
  if (-not $versions) { throw 'Vivaldi installation not found. Set VIVALDI_UI_DIR to its resources\vivaldi folder.' }

  $latest = $versions | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
  $uiDir  = Join-Path $latest.FullName 'resources\vivaldi'
  Write-Host "Vivaldi $($latest.Name): $uiDir"
}

$html = Join-Path $uiDir 'window.html'
if (-not (Test-Path $html)) { throw "window.html not found in $uiDir" }
$utf8    = New-Object System.Text.UTF8Encoding($false)
$content = [IO.File]::ReadAllText($html)

if ($Uninstall) {
  if ($content.Contains($tag)) {
    $cleaned = $content -replace ("[ \t]*" + [regex]::Escape($tag) + "\r?\n?"), ''
    [IO.File]::WriteAllText($html, $cleaned, $utf8)
    Write-Host '  removed script tag from window.html'
  } else {
    Write-Host '  window.html is not patched'
  }
  $dst = Join-Path $uiDir $modName
  if (Test-Path $dst) { Remove-Item $dst; Write-Host "  deleted $modName" }
  Write-Host 'Done. Restart Vivaldi.'
  return
}

Copy-Item $modSrc (Join-Path $uiDir $modName) -Force
Write-Host "  copied $modName"

if ($content.Contains($tag)) {
  Write-Host '  window.html already patched'
} else {
  $backup = "$html.bak"
  if (-not (Test-Path $backup)) { Copy-Item $html $backup; Write-Host '  backup: window.html.bak' }
  $patched = $content -replace '</body>', "  $tag`r`n</body>"
  if ($patched -eq $content) { throw 'No </body> found in window.html - format changed, patch manually.' }
  [IO.File]::WriteAllText($html, $patched, $utf8)
  Write-Host '  window.html patched'
}

Write-Host 'Done. Restart Vivaldi.'
