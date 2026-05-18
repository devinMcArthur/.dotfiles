# Dotfiles

Personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

**Current target:** Arch Linux + Hyprland + Ghostty + zsh + Neovim.

## Bootstrap on a new machine

Two commands. The first installs chezmoi; the second clones this repo and
applies it (including a `run_onchange_` script that installs all required
packages and switches your login shell to zsh).

```bash
sudo pacman -S --needed chezmoi
chezmoi init --apply git@github.com:devinMcArthur/.dotfiles.git
```

That's it. Subsequent updates:

```bash
chezmoi update     # git pull + apply
chezmoi apply -v   # apply without pulling
```

### Prerequisites for a truly fresh install

The `chezmoi init` above assumes:

1. You can `git clone` over SSH (your key is on GitHub).
2. `yay` is installed (the AUR helper). If not, install it once:
   ```bash
   sudo pacman -S --needed base-devel git
   git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si
   ```
3. The 1Password desktop app is installed and **CLI integration is enabled**
   (Settings → Developer → "Integrate with 1Password CLI"). Without this,
   templates that pull secrets at apply time will fail. The `1password` AUR
   package is part of the bootstrap, but you must sign in and enable the
   integration manually after first install.

## Secrets

Secrets are **not** stored in the repo. They are resolved at `chezmoi apply`
time via the 1Password CLI. References look like:

```go-template
export ANTHROPIC_API_KEY={{ "{{" }} onepasswordRead "op://Dev Secrets/anthropic_api_key/credential" {{ "}}" }}
```

To add a new secret:

1. Create the item in 1Password (e.g. in the `Dev Secrets` vault).
2. Right-click → "Copy Secret Reference" to get the `op://...` path.
3. Use `{{ "{{" }} onepasswordRead "op://..." | quote {{ "}}" }}` in a `.tmpl` file.
4. `chezmoi apply` resolves it.

## Per-host configuration

Host-specific values live in `~/.config/chezmoi/chezmoi.toml`, which is **not**
committed. Example (mirrors the current `turing` machine):

```toml
[data]
  name    = "Devin McArthur"
  email   = "assortedgerm@gmail.com"
  profile = "personal"     # or "work"

[onepassword]
  command = "op"
  prompt  = false          # required for desktop-app CLI integration

[edit]
  command = "nvim"
```

Templates can branch on `.profile`, `.chezmoi.hostname`, `.chezmoi.os`, etc.

## Layout

```
.chezmoiignore                              # what NOT to manage
chezmoi.toml.example                        # per-host template (not used yet)
run_onchange_before_install-packages.sh.tmpl  # bootstrap packages

dot_zshrc.tmpl                              # → ~/.zshrc      (templated)
dot_gitconfig                               # → ~/.gitconfig
dot_tmux.conf                               # → ~/.tmux.conf
dot_tmux.conf.local                         # → ~/.tmux.conf.local
dot_antigenrc                               # → ~/.antigenrc
dot_zshenv                                  # → ~/.zshenv
dot_bashrc                                  # → ~/.bashrc

dot_config/
  ghostty/config                            # terminal
  hypr/                                     # window manager
  waybar/                                   # status bar
  wofi/                                     # launcher
  starship.toml                             # prompt
  zellij/                                   # multiplexer
  nvim/                                     # editor (LazyVim-based)
  lazygit/, lazydocker/, htop/              # TUIs
```

## Common commands

| Action                                                  | Command                       |
|---------------------------------------------------------|-------------------------------|
| Edit a managed file (source, in `$EDITOR`)              | `chezmoi edit ~/.zshrc`       |
| Add a new file to be managed                            | `chezmoi add ~/.foo`          |
| Add as a template (templating syntax allowed)           | `chezmoi add --template ~/.foo` |
| Re-add changes made directly to the live file           | `chezmoi re-add`              |
| Preview what `apply` would change                       | `chezmoi diff`                |
| Apply changes                                           | `chezmoi apply -v`            |
| Confirm live matches source (silent = OK)               | `chezmoi verify`              |
| Pull + apply                                            | `chezmoi update`              |
| Show resolved template data                             | `chezmoi data`                |

## Branches

| Branch                 | Purpose                                                                                   |
|------------------------|-------------------------------------------------------------------------------------------|
| `master`               | Current chezmoi-managed dotfiles. Default.                                                |
| `legacy-stow`          | Final state of the previous GNU Stow layout. Kept for historical reference; do not merge. |
| `pre-chezmoi-archive`  | Snapshot of stow layout *with* uncommitted drift captured. Pre-migration safety net.      |

## Notable design choices

- **chezmoi over stow/yadm/bare-git** because of templating + 1Password
  integration (see commit history).
- **Wallpapers live in `~/Pictures/wallpapers/`**, not the repo. `hyprpaper.conf`
  references the absolute path. Bring your own image of the same name, or edit
  the path.
- **`Super+I` opens nmtui via ghostty** (was previously kitty); kitty has been
  removed from the package list.
- **Antigen + oh-my-zsh** are still in use (via `~/antigen.zsh`, not in repo).
  Migration to a leaner plugin manager (zinit, zcomet, or built-in) is a
  candidate future improvement.
