# Claude Token Bar - uninstaller
$ErrorActionPreference = 'Stop'

$claudeDir = Join-Path $env:USERPROFILE '.claude'
$target    = Join-Path $claudeDir 'statusline.ps1'
$settings  = Join-Path $claudeDir 'settings.json'

if (Test-Path $settings) {
    $text = Get-Content -Path $settings -Raw
    if ($text -and $text.Trim()) {
        $cfg = $text | ConvertFrom-Json
        if ($cfg.PSObject.Properties.Name -contains 'statusLine') {
            $cfg.PSObject.Properties.Remove('statusLine')
            $json = $cfg | ConvertTo-Json -Depth 20
            [System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding($false)))
        }
    }
}
if (Test-Path $target) { Remove-Item $target -Force }

Write-Host 'Claude Token Bar removed. Restart Claude Code.' -ForegroundColor Green
