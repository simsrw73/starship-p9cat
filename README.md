# starship-p9cat

A [Starship](https://starship.rs) preset in the classic **powerlevel9k** style, using **[Catppuccin](https://catppuccin.com)** colors.

```
  ⟩ ~\projects\starship-p9cat ⟩  main ↑1 +2 !1 ?3             ◀ user@host ⟩ 14:02:11 
❯
```

- Line 1: a two-sided bar on Crust, like powerlevel9k. The left side shows the OS icon, the full path and git status. The right side shows user@host and the time.
- Line 2: a `❯` prompt character. It is green, and turns red after a command fails.
- The preset includes all four Catppuccin flavors. Mocha is the default.

It is a port of my oh-my-posh theme `catpow`.

## Requirements

- Starship 1.x
- A [Nerd Font](https://www.nerdfonts.com), enabled in your terminal

## Install

Copy `p9cat.toml` to Starship's config path:

```sh
# Linux / macOS
curl -fsSL https://raw.githubusercontent.com/simsrw73/starship-p9cat/main/p9cat.toml -o ~/.config/starship.toml
```

```powershell
# Windows (PowerShell)
Invoke-WebRequest https://raw.githubusercontent.com/simsrw73/starship-p9cat/main/p9cat.toml -OutFile "$HOME\.config\starship.toml"
```

Or leave it wherever you like and point `STARSHIP_CONFIG` at it.

Then initialize Starship in your shell, if you haven't yet:

| Shell      | Add to                          | Line                                             |
| ---------- | ------------------------------- | ------------------------------------------------ |
| PowerShell | `$PROFILE`                      | `Invoke-Expression (&starship init powershell)`  |
| bash       | `~/.bashrc`                     | `eval "$(starship init bash)"`                   |
| zsh        | `~/.zshrc`                      | `eval "$(starship init zsh)"`                    |
| fish       | `~/.config/fish/config.fish`    | `starship init fish \| source`                   |

## Flavors

Change a single line:

```toml
palette = "catppuccin_mocha"   # or catppuccin_macchiato, catppuccin_frappe, catppuccin_latte
```

## Git status legend

| Symbol | Meaning                  | Color  |
| ------ | ------------------------ | ------ |
| `↑n` `↓n` | ahead / behind upstream | green  |
| `≡`    | in sync with upstream    | green  |
| `+n`   | staged changes           | yellow |
| `!n`   | modified files           | yellow |
| `✘n`   | deleted files            | yellow |
| `»n`   | renamed files            | yellow |
| `?n`   | untracked files          | sky    |
| `*n`   | stashes                  | maroon |
| `=n`   | conflicts                | red    |

## Differences from the oh-my-posh original

Starship can't do everything oh-my-posh does, so a few details differ:

- **Root:** oh-my-posh swaps the OS icon for a ⚡ bolt when you are root. Here the username turns red instead.
- **WSL:** there is no `WSL at` prefix.
- **Modified and deleted files:** oh-my-posh sums them into one `!n`. Here they are two counts, `!n` and `✘n`.
- **Branch with no upstream:** oh-my-posh shows `≢`. Here nothing is shown.
- **Worktrees:** the git worktree count is not shown.

## License

[MIT](LICENSE). The color values come from [Catppuccin](https://github.com/catppuccin/palette), which is also MIT licensed.
