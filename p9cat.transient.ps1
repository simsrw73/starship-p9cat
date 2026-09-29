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
# Usage: dot-source this AFTER `starship init powershell` has run:
#     . ~/.config/starship/p9cat.transient.ps1

if (-not (Get-Command Enable-TransientPrompt -ErrorAction Ignore)) {
    Write-Warning 'p9cat.transient: Enable-TransientPrompt not found; run starship init first.'
    return
}

# --- Colors from the active palette (falls back to Catppuccin Mocha) ---------------
# Runs in its own scope (& { }) so nothing leaks into the session that dot-sources this.
$global:__p9cat_colors = & {
    $hexes = @{ teal = '#94e2d5'; sapphire = '#74c7ec'; green = '#a6e3a1'; red = '#f38ba8' }
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

# --- Remember whether the last command failed ---------------------------------------
# starship computes the status inside its own module, out of reach, so wrap prompt and
# capture $? as the very first statement. Only record it when history advanced (a real
# command ran): the transient redraw calls prompt again and must not overwrite it.
if (-not (Get-Variable __p9cat_innerPrompt -Scope Global -ErrorAction Ignore)) {
    $global:__p9cat_innerPrompt = $function:prompt
    $global:__p9cat_lastFailed = $false
    $global:__p9cat_lastHistoryId = -1
    function global:prompt {
        $ok = $?
        $entry = Get-History -Count 1
        if ($entry -and $entry.Id -ne $global:__p9cat_lastHistoryId) {
            $global:__p9cat_lastHistoryId = $entry.Id
            $global:__p9cat_lastFailed = -not $ok
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
