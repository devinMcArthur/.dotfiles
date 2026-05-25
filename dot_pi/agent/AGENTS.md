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
- 2026-05-25: Rule when driving sudo via pi's sudo-gate (zenity): NEVER issue multiple separate sudo invocations in one bash tool call. Each `sudo ...` pops its own zenity dialog, and dialogs that appear while user focus is elsewhere will silently consume partial/empty input and burn faillock strikes. Always consolidate ALL elevated work (setup + verification + cleanup) into ONE `sudo sh -c '...'` block. Single dialog, single auth, single failure mode.
- 2026-05-25: Prefer driving sudo invocations through pi's sudo-gate (zenity password dialog) rather than handing the user a "run this in your terminal" instruction. The user has sudo-gate set up exactly so pi can execute privileged commands; bouncing back to the terminal defeats the purpose. Only ask the user to run something themselves when sudo-gate genuinely can't handle it (e.g. interactive visudo editing, recovery from auth lockout).
- 2026-05-25: pam_faillock locks the dev user out of sudo after 3 failed attempts (default 600s/10min unlock_time on Arch). Sudo's built-in `passwd_tries=3` means ONE wrong password from a zenity/askpass dialog can trigger all 3 strikes in a single invocation, causing immediate lockout. Diagnose with `faillock --user dev` (no sudo needed). Auto-unlocks after 10min; or boot to recovery and `faillock --reset`. Prevention: set `Defaults passwd_tries=1` in /etc/sudoers.d/pi-agent, OR add frequently-used binaries (systemctl, fw-ectool) to NOPASSWD so they use the Tier 1 confirm path and never touch a password dialog.
- 2026-05-25: When emitting Nerd Font / non-ASCII glyphs from a script written via an LLM file-write tool, prefer bash `$'\uXXXX'` / `$'\UXXXXXXXX'` escapes over raw multi-byte UTF-8 literals. Raw glyphs occasionally get silently stripped to empty strings during the write path; \u escapes reconstruct the codepoint at runtime and survive any mangling.
- 2026-05-25: If waybar (or any wlroots layer-shell widget) is not interactable on Hyprland, check for `"passthrough": true` in its config — that setting forwards all input to the layer below, making the bar decorative-only. It's a common template artifact from copy-pasted rice configs.
- 2026-05-25: Never chezmoi-manage self-modifying state files (e.g. .pi/agent/settings.json, nvim shada, browser session state). Apps write to them; chezmoi reverts them on apply. Symptom: app behaves as if "amnesia'd" (re-shows changelogs, loses caches). Fix: add the path to .chezmoiignore and remove the source-tree copy. Rule of thumb: if an app *writes* to the file at runtime, chezmoi must not own it.
- 2026-05-25: 1Password desktop app caches the vault locally — `op read` and `op run` work offline as long as the desktop app is running AND unlocked. They fail (not silently) when the app is locked or not running. So lazy `with-secrets <cmd>` wrappers are offline-safe in the cabin-in-the-woods case; the only failure mode is "I forgot to unlock 1Password," which surfaces as a clear op error rather than a missing env var.
- 2026-05-25: pi requires tmux extended-keys-format csi-u (not the default xterm). Add `set -s extended-keys-format csi-u` alongside `set -s extended-keys always` in tmux.conf — without it pi emits a warning at startup and modified keys (Shift/Ctrl+Enter) may not pass through correctly.
- 2026-05-20: cage (the embedded Wayland kiosk used by greetd-regreet) only offers `-m extend` (spread login across all monitors) or `-m last` (pick last DRM-enumerated output). On Framework laptop with externals, last-enumerated = eDP-1 (internal panel). For multi-monitor setups, always use `cage -s -d -m last -- regreet` — never the default `-m extend`, which spreads the UI across all displays and centers the login box across monitor borders.
- 2026-05-20: hyprpolkitagent.service is `WantedBy=graphical-session.target`, which only activates under UWSM. On a plain `start-hyprland` setup, the service is enabled but never starts — add `exec-once = systemctl --user start hyprpolkitagent.service` to hyprland.conf as the explicit kick. Same pattern likely applies to other Hyprland-ecosystem user services.
- 2026-05-20: `hyprctl reload` re-reads config but does NOT re-run `exec-once` lines and does NOT propagate new `env =` directives to running children. To apply env or exec-once changes you must fully restart Hyprland. Avoid half-applying changes across multiple `hyprctl reload` cycles — it leaves session env, dbus activation env, and child-process env out of sync, which can crash-loop dependent services like hyprpolkitagent and break apps mid-session.
- 2026-05-20: Hyprland's PATH (when launched from display manager/TTY) does NOT include ~/.local/bin — interactive shell rc files aren't sourced. Scripts in ~/.local/bin bound via `exec, my-script` silently fail (sh exits 127, Hyprland swallows it). Fix: use absolute paths in binds OR add `env = PATH,$HOME/.local/bin:$PATH` at top of hyprland.conf (env = only applies on Hyprland start, not hyprctl reload).
- 2026-05-18: zsh-autosuggestions default highlight is fg=8 (very dark gray), often invisible against modern terminal palettes. Set ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE explicitly to a visible-but-dim color (e.g. Catppuccin overlay0 #6c7086) after antidote loads.
- 2026-05-18: Don't put `{{ onepasswordRead "..." }}` in chezmoi templates if 1Password's Allow/Deny prompt is annoying — chezmoi apply triggers a prompt every time. Instead, declare secrets in ~/.config/op-dev.env (using op:// URIs) and resolve at runtime via `op run --env-file=... -- <cmd>` or the `with-secrets` zsh helper.
- 2026-05-18: When user asks about a library/framework's API, syntax, or config, query Context7 via mcp({ search: "..." }) then mcp({ tool: "context7_..." }) before falling back to web search or training data. Context7 has indexed docs for Hyprland, chezmoi, neovim, and ~6000 other projects.
