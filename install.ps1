# Claude Token Bar - installer (Windows PowerShell 5.1+ / PowerShell 7)
# Copies statusline.ps1 to ~\.claude and adds a "statusLine" entry to settings.json.
# Your existing settings are kept, and a backup is saved as settings.json.bak.

$ErrorActionPreference = 'Stop'

$claudeDir = Join-Path $env:USERPROFILE '.claude'
$target    = Join-Path $claudeDir 'statusline.ps1'
$settings  = Join-Path $claudeDir 'settings.json'
$source    = Join-Path $PSScriptRoot 'statusline.ps1'

if (-not (Test-Path $source)) { throw "statusline.ps1 not found next to install.ps1" }
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir | Out-Null }

Copy-Item -Path $source -Destination $target -Force

$cfg = $null
if (Test-Path $settings) {
    Copy-Item -Path $settings -Destination "$settings.bak" -Force
    $text = Get-Content -Path $settings -Raw
    if ($text -and $text.Trim()) { $cfg = $text | ConvertFrom-Json }
}
if (-not $cfg) { $cfg = New-Object PSObject }

$status = [ordered]@{
    type    = 'command'
    command = "powershell -NoProfile -ExecutionPolicy Bypass -File `"$target`""
}
$cfg | Add-Member -NotePropertyName 'statusLine' -NotePropertyValue ([pscustomobject]$status) -Force

$json = $cfg | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ''
Write-Host 'Claude Token Bar installed.' -ForegroundColor Green
Write-Host "Script:   $target"
Write-Host "Settings: $settings (backup: settings.json.bak)"
Write-Host 'Restart Claude Code to see the bar at the bottom.'
