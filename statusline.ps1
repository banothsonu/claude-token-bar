# Claude Token Bar - status line for Claude Code (Windows PowerShell 5.1+ / PowerShell 7)
# Claude Code pipes a JSON object to stdin; whatever we print becomes the status bar.
# Shows: model | context window (tokens used / left) | 5-hour limit | weekly limit | cost
# Anything Claude Code does not send (for example plan limits on API or Ollama setups)
# is simply left out, so the script never errors.

$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ---- settings (override with environment variables) ----
$BarWidth = 10
if ($env:CC_BAR_WIDTH -match '^\d+$') { $BarWidth = [int]$env:CC_BAR_WIDTH }
$ShowCost = ($env:CC_SHOW_COST -ne '0')

# ---- helpers ----
$ESC   = [char]27
$FULL  = [string][char]0x2588   # full block
$EMPTY = [string][char]0x2591   # light shade
$SEP   = " $([char]0x2502) "    # vertical bar separator

function Paint([string]$text, [string]$code) { return "$ESC[$($code)m$text$ESC[0m" }

function Get-Color([double]$usedPct) {
    if ($usedPct -ge 80) { return '31' }   # red
    if ($usedPct -ge 50) { return '33' }   # yellow
    return '32'                            # green
}

function Get-Bar([double]$usedPct) {
    if ($usedPct -lt 0) { $usedPct = 0 }
    if ($usedPct -gt 100) { $usedPct = 100 }
    $filled = [int][math]::Round($usedPct / 100 * $BarWidth)
    $bar = ($FULL * $filled) + ($EMPTY * ($BarWidth - $filled))
    return (Paint $bar (Get-Color $usedPct))
}

function Format-Tokens([double]$n) {
    if ($n -ge 1000000) { return ('{0:0.0}M' -f ($n / 1000000)) }
    if ($n -ge 1000)    { return ('{0:0}K' -f ($n / 1000)) }
    return ('{0:0}' -f $n)
}

function Format-Remaining([double]$epochSeconds) {
    $reset = [DateTimeOffset]::FromUnixTimeSeconds([long]$epochSeconds)
    $span = $reset - [DateTimeOffset]::UtcNow
    if ($span.TotalSeconds -le 0) { return 'now' }
    if ($span.TotalHours -ge 24) { return ('{0}d{1}h' -f [int]$span.Days, $span.Hours) }
    if ($span.TotalHours -ge 1)  { return ('{0}h{1:00}m' -f [int][math]::Floor($span.TotalHours), $span.Minutes) }
    return ('{0}m' -f [int][math]::Ceiling($span.TotalMinutes))
}

# ---- read input ----
$raw = [Console]::In.ReadToEnd()
$data = $null
if ($raw) { $data = $raw | ConvertFrom-Json }
if (-not $data) { Write-Output 'Claude Token Bar: waiting for data...'; exit 0 }

$parts = @()

# ---- model ----
$model = $data.model.display_name
if (-not $model) { $model = $data.model.id }
if ($model) { $parts += (Paint $model '35') }

# ---- context window ----
$cw = $data.context_window
if ($cw) {
    $size = [double]$cw.context_window_size
    $usedPct = $null
    if ($null -ne $cw.used_percentage) { $usedPct = [double]$cw.used_percentage }

    $usedTokens = $null
    if ($cw.current_usage) {
        $u = $cw.current_usage
        $usedTokens = [double]$u.input_tokens + [double]$u.cache_creation_input_tokens + [double]$u.cache_read_input_tokens
    }
    if ($null -eq $usedPct -and $size -gt 0 -and $null -ne $usedTokens) { $usedPct = $usedTokens / $size * 100 }
    if ($null -eq $usedTokens -and $size -gt 0 -and $null -ne $usedPct) { $usedTokens = $usedPct / 100 * $size }

    if ($null -ne $usedPct -and $size -gt 0) {
        $left = [math]::Max(0, $size - $usedTokens)
        $txt = 'ctx {0} {1:0}% ({2} used, {3} left)' -f (Get-Bar $usedPct), $usedPct, (Format-Tokens $usedTokens), (Format-Tokens $left)
        $parts += $txt
        if ($usedPct -ge 80) { $parts += (Paint 'run /compact soon' '31') }
    } elseif ($size -gt 0) {
        $parts += ('ctx {0} 0% ({1} left)' -f (Get-Bar 0), (Format-Tokens $size))
    }
}

# ---- plan limits (sent by Claude Code for subscription plans) ----
$rl = $data.rate_limits
if ($rl) {
    if ($rl.five_hour -and $null -ne $rl.five_hour.used_percentage) {
        $p = [double]$rl.five_hour.used_percentage
        $t = '5h {0} {1:0}%' -f (Get-Bar $p), $p
        if ($rl.five_hour.resets_at) { $t += ' (resets ' + (Format-Remaining $rl.five_hour.resets_at) + ')' }
        $parts += $t
    }
    if ($rl.seven_day -and $null -ne $rl.seven_day.used_percentage) {
        $p = [double]$rl.seven_day.used_percentage
        $t = '7d {0} {1:0}%' -f (Get-Bar $p), $p
        if ($rl.seven_day.resets_at) { $t += ' (resets ' + (Format-Remaining $rl.seven_day.resets_at) + ')' }
        $parts += $t
    }
}

# ---- cost ----
if ($ShowCost -and $data.cost -and $null -ne $data.cost.total_cost_usd -and [double]$data.cost.total_cost_usd -gt 0) {
    $parts += ('${0:0.00}' -f [double]$data.cost.total_cost_usd)
}

Write-Output ($parts -join $SEP)
