# p9cat transient prompt for PowerShell 7+ (PSReadLine).
#
# When you press Enter, the two-line prompt collapses to a single line that stays in
# scrollback:
#
#     11:40:07 ~\projects ❯ git status
#
# The time is taken the moment Enter is pressed, i.e. when the command ran. The ❯ is
# red when the previous command failed, matching the live prompt. Colors come from the
# active starship config's palette, so switching flavor in p9cat.toml carries over.
#
# Commands that run longer than a threshold get a dim line under their output:
#
#     11:40:07 ~\projects ❯ Start-Sleep 3
#       took 3.00 s
#
# Default threshold is 2 seconds. Change it with $P9CatTookThreshold (seconds; 0 prints
# it after every command, a negative value turns it off), set before or after loading.
#
# Usage: dot-source this AFTER `starship init powershell` has run:
#     . ~/.config/starship/p9cat.transient.ps1

if (-not (Get-Command Enable-TransientPrompt -ErrorAction Ignore)) {
    Write-Warning 'p9cat.transient: Enable-TransientPrompt not found; run starship init first.'
    return
}

# --- Colors from the active palette (falls back to Catppuccin Mocha) ---------------
# Runs in its own scope (& { }) so nothing leaks into the session that dot-sources this.
$global:__p9cat_colors = & {
    $hexes = @{ teal = '#94e2d5'; sapphire = '#74c7ec'; green = '#a6e3a1'; red = '#f38ba8'; overlay1 = '#7f849c' }
    $configPath = if ($env:STARSHIP_CONFIG) { $env:STARSHIP_CONFIG } else { Join-Path $HOME '.config/starship.toml' }
    if (Test-Path $configPath) {
        $toml = Get-Content $configPath -Raw
        if ($toml -match '(?m)^\s*palette\s*=\s*"([^"]+)"') {
            $table = [regex]::Match($toml, '(?ms)^\[palettes\.' + [regex]::Escape($Matches[1]) + '\]\s*$(.*?)(?=^\[|\z)')
            if ($table.Success) {
                foreach ($name in @($hexes.Keys)) {
                    $m = [regex]::Match($table.Groups[1].Value, "(?m)^\s*$name\s*=\s*""(#[0-9a-fA-F]{6})""")
                    if ($m.Success) { $hexes[$name] = $m.Groups[1].Value }
                }
            }
        }
    }
    $ansi = @{}
    foreach ($name in $hexes.Keys) {
        $hex = $hexes[$name]
        $ansi[$name] = "`e[38;2;{0};{1};{2}m" -f
            [Convert]::ToInt32($hex.Substring(1, 2), 16),
            [Convert]::ToInt32($hex.Substring(3, 2), 16),
            [Convert]::ToInt32($hex.Substring(5, 2), 16)
    }
    $ansi
}

# --- After each command: remember failure, report slow commands -------------------------
if ($null -eq (Get-Variable P9CatTookThreshold -Scope Global -ErrorAction Ignore)) {
    $global:P9CatTookThreshold = 2
}

function global:Format-P9CatDuration([TimeSpan]$Duration) {
    if ($Duration.TotalSeconds -lt 1) { return '{0:N2} ms' -f $Duration.TotalMilliseconds }
    if ($Duration.TotalMinutes -lt 1) { return '{0:N2} s' -f $Duration.TotalSeconds }
    if ($Duration.TotalHours -lt 1) { return '{0}m {1:N1}s' -f $Duration.Minutes, ($Duration.TotalSeconds % 60) }
    '{0}h {1:D2}m {2:D2}s' -f [int][Math]::Floor($Duration.TotalHours), $Duration.Minutes, $Duration.Seconds
}

# Called by the prompt wrapper once per finished command (not on the transient redraw).
# Redefined on every load, so re-dot-sourcing picks up changes.
function global:__p9cat_OnCommandFinished($Entry, [bool]$Ok) {
    $global:__p9cat_lastFailed = -not $Ok
    $threshold = $global:P9CatTookThreshold
    if ($threshold -lt 0 -or $null -eq $Entry.Duration -or $Entry.Duration.TotalSeconds -lt $threshold) { return }
    # Start on a fresh line if the command's output didn't end with a newline.
    $lead = try { if ($Host.UI.RawUI.CursorPosition.X -ne 0) { "`n" } else { '' } } catch { '' }
    Write-Host ("{0}  {1}took {2}`e[0m" -f $lead, $global:__p9cat_colors.overlay1, (Format-P9CatDuration $Entry.Duration))
}

# starship computes the status inside its own module, out of reach, so wrap prompt and
# capture $? as the very first statement. Act only when history advanced (a real command
# ran): the transient redraw calls prompt again and must not repeat anything.
if (-not (Get-Variable __p9cat_innerPrompt -Scope Global -ErrorAction Ignore)) {
    $global:__p9cat_innerPrompt = $function:prompt
    $global:__p9cat_lastFailed = $false
    $global:__p9cat_lastHistoryId = -1
    function global:prompt {
        $ok = $?
        $entry = Get-History -Count 1
        if ($entry -and $entry.Id -ne $global:__p9cat_lastHistoryId) {
            $global:__p9cat_lastHistoryId = $entry.Id
            try { __p9cat_OnCommandFinished $entry $ok } catch { }
        }
        # Restore $? for the wrapped prompt: it mirrors the last statement, and looking
        # up a missing variable fails without touching $Error.
        if ($ok) { $null = $true } else { Get-Variable '__p9cat_NoSuchVariable__' -ErrorAction Ignore }
        & $global:__p9cat_innerPrompt
    }
}

# --- The collapsed line --------------------------------------------------------------
function global:Invoke-Starship-TransientFunction {
    $c = $global:__p9cat_colors
    $dir = $executionContext.SessionState.Path.CurrentLocation.Path
    if ($dir -eq $HOME) { $dir = '~' }
    elseif ($dir.StartsWith($HOME + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        $dir = '~' + $dir.Substring($HOME.Length)
    }
    $char = if ($global:__p9cat_lastFailed) { $c.red } else { $c.green }
    "{0}{1} {2}{3} {4}❯`e[0m " -f $c.teal, (Get-Date -Format 'HH:mm:ss'), $c.sapphire, $dir, $char
}

Enable-TransientPrompt
