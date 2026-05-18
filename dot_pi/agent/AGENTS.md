# Pi context for Devin McArthur

Loaded automatically into every pi session. Keep facts here that pi
should always know; correction-driven `## Lessons learned` entries are
auto-appended by the `lessons` extension.

---

## About me

- **Name**: Devin McArthur
- **Git email**: assortedgerm@gmail.com (1Password login uses a separate
  itsdevinmcarthur@gmail.com).
- **GitHub**: [@devinMcArthur](https://github.com/devinMcArthur)
- **Hostname**: `turing`
- **Hardware**: Framework laptop + 2× Acer KA272 external monitors.

## Environment

- **OS**: Arch Linux
- **Desktop**: Hyprland (Wayland)
- **Terminal**: Ghostty (daily driver). Kitty was removed; `nmtui` now
  runs via `ghostty --class=nmtui -e nmtui`.
- **Shell**: zsh + [antidote](https://getantidote.github.io/) (AUR
  `zsh-antidote`) + starship prompt. Plugin list:
  `~/.zsh_plugins.txt`.
- **Multiplexers**: tmux (Catppuccin Mocha), zellij.
- **Editor**: Neovim (LazyVim-based, config at `~/.config/nvim`).
- **Status bar**: waybar
- **Launcher**: wofi (Catppuccin Mocha rice in
  `~/.config/wofi/style.css`)
- **Notifications**: swaync
- **Logout menu**: wlogout (AUR)
- **Lock + idle**: hyprlock + hypridle
- **Wallpaper**: hyprpaper (image at
  `~/Pictures/wallpapers/evening-landscape.jpg`, deep blue/mauve dusk
  with a moon).
- **AUR helper**: yay (`zsh-antidote`, `1password`, `wlogout` come from
  AUR; everything else from official repos).

## Dotfiles

- **Managed by**: chezmoi (v2.70.3+).
- **Source tree**: `~/.local/share/chezmoi/`.
- **Remote**: `git@github.com:devinMcArthur/.dotfiles.git`.
- **Branches**: `master` (chezmoi, default), `legacy-stow` (the previous
  GNU-Stow layout), `pre-chezmoi-archive` (final stow snapshot with
  uncommitted drift).
- **Per-host config**: `~/.config/chezmoi/chezmoi.toml` — *not*
  committed. Contains name/email + 1Password integration (`prompt =
  false` for desktop-app CLI integration).
- **Bootstrap**: `run_onchange_before_install-packages.sh.tmpl` installs
  pacman + AUR packages on first apply (and any time the script
  content changes).
- **Goal**: every part of this laptop should be chezmoi-managed.

## Secrets

- Stored in **1Password** (`op` CLI + desktop-app integration).
- Vault: `Dev Secrets` for dev API keys (e.g. `anthropic_api_key`).
- Pulled into config at `chezmoi apply` time via templates, e.g.
  `{{ "{{" }} onepasswordRead "op://Dev Secrets/foo/credential" {{ "}}" }}`.
- **Never** commit secrets to the dotfiles repo.

## Pi-agent setup

- **Extensions** live in `~/.pi/agent/extensions/` and are
  chezmoi-managed:
  - `sudo-gate.ts` — confirmation gate for `sudo`/`yay` invocations
    via pi's `bash` tool. Also installs a compact footer with a
    shield-check glyph.
  - `lessons.ts` — `/lesson` command + `save_lesson` tool. See **How to
    use the lessons system** below.
- **Sudoers**: `/etc/sudoers.d/pi-agent` allowlists `pacman`, `yay`,
  `chsh`, `hostnamectl` with `NOPASSWD`. Pi can run those without a
  password prompt; sudo-gate enforces per-call human confirmation.

## How to use the lessons system

When the user corrects you, expresses a durable preference, or tells you
a fact about themselves / their setup that future sessions should know,
call the **`save_lesson`** tool:

- `scope = "global"` writes to `~/.pi/agent/AGENTS.md` (this file). Use
  for cross-project facts and preferences.
- `scope = "project"` writes to `<git-root>/AGENTS.md` if cwd is inside
  a git repo. Use for project-specific conventions.
- Be specific and short. One bullet per lesson, dated. Examples:
  - "Prefers `eza` over `exa` (exa is unmaintained)."
  - "Doesn't use SDKMAN; never propose installing it."
  - "Wallpaper-based theming: only suggest accent colors that pair with
    the current wallpaper."

User can also save manually with `/lesson [global|project] <text>`.

Lessons save **silently** (no confirm prompt). Don't over-call this —
prefer to capture durable, repeatable corrections, not one-off
preferences for the current task.

## Conventions

- Personal projects under `~/personal/`; work projects under `~/work/`.
- Wallpapers live in `~/Pictures/wallpapers/`, screenshots in
  `~/Pictures/Screenshots/`.
- chezmoi-manage anything I might want on another machine.
- Prefer concise tool outputs. If a command will spew >5KB, pipe
  through `head`, `tail`, `wc`, `--summary`, etc. Large outputs cause
  real UI delays.
- Steelman alternatives before recommending one.
- Phase-by-phase pace on big changes; commit at each checkpoint.
- Rotate any credential that's been logged anywhere visible (chat,
  terminal scrollback, git history).
- When you need library/framework docs (Hyprland, chezmoi, nvim plugins,
  framework APIs, etc.), reach for **Context7** via the `mcp` proxy
  first (`mcp({ search: "..." })` then `mcp({ tool: "context7_..." })`).
  Fall back to web search only when Context7 has no entry for that
  project.

## Tools I actively use

minikube, skaffold, kubectl, helm, AWS CLI, doctl, gh, docker, go, rust,
node (via nvm), bun, python (via uv).

Do **not** assume I use: SDKMAN, kitty, swaylock, neofetch, hermes CLI,
or the `npm`/`nvm`/`aws`/`kubectl`/`helm` oh-my-zsh plugins (replaced
with native `<tool> completion zsh`, cached weekly under `~/.cache/zsh/`).

---

## Lessons learned

<!-- Auto-appended by `save_lesson`. Newest first. -->
- 2026-05-18: Don't put `{{ onepasswordRead "..." }}` in chezmoi templates if 1Password's Allow/Deny prompt is annoying — chezmoi apply triggers a prompt every time. Instead, declare secrets in ~/.config/op-dev.env (using op:// URIs) and resolve at runtime via `op run --env-file=... -- <cmd>` or the `with-secrets` zsh helper.
- 2026-05-18: When user asks about a library/framework's API, syntax, or config, query Context7 via mcp({ search: "..." }) then mcp({ tool: "context7_..." }) before falling back to web search or training data. Context7 has indexed docs for Hyprland, chezmoi, neovim, and ~6000 other projects.
