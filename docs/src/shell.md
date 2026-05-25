# Shell — zsh, antidote, prompt

Login shell is zsh (`chsh` happens automatically on first `chezmoi
apply`). Config: [`dot_zshrc.tmpl`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_zshrc.tmpl).

## Plugin manager — antidote

[antidote](https://getantidote.github.io/) loads plugins from
[`dot_zsh_plugins.txt`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_zsh_plugins.txt).
Distinct from the (unrelated) French app named "Antidote." We
deliberately *don't* use oh-my-zsh's plugin loader.

Compdef-registering plugins (e.g. zsh-completions) require `compinit`
to run before antidote loads, which `dot_zshrc.tmpl` does at the top.

## Prompt — starship

[starship](https://starship.rs/) prompt; config defaults until a
specific need emerges. Don't heavily customize until familiar with the
full feature set.

## History — atuin

Encrypted, searchable shell history with FTS5 indexing. **Offline
mode** — no sync, no telemetry, no remote registration.

- Config: [`dot_config/atuin/config.toml`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_config/atuin/config.toml)
- DB: `~/.local/share/atuin/history.db` (NOT chezmoi-managed —
  app-written state)

### Bindings

| Key | Action |
|---|---|
| `Ctrl-R` | Atuin fuzzy picker over full history |
| `↑` | Traditional zsh history (kept as fallback via `--disable-up-arrow`) |
| Tab (in picker) | Accept and run |
| Enter (in picker) | Insert into prompt, don't run (gives chance to edit) |

### Filter modes (cycle inside picker)

Default starts in `session`; up-arrow inside the picker cycles
`session → host → global → directory`.

### Captured commands

Commands starting with a space (POSIX `ignorespace` convention) are
NOT recorded. Use this for one-off secrets-ish invocations.

### Imports

Initial import from `~/.zsh_history` was run once at install
(`atuin import zsh`). The native zsh history file continues to grow
in parallel — atuin imports new entries on every shell start. Safe to
re-run `atuin import zsh` anytime; it deduplicates by hash.

## Directory jumping — zoxide

`z <partial>` jumps to the most frecent matching directory; `zi`
opens an fzf picker over the same DB. Sesh (the tmux session
picker) shares this DB — both contribute to and read from the same
frecency state.

```bash
z bow      # → ~/work/bow-mark
z chezmoi  # → ~/.local/share/chezmoi
zi         # interactive picker
```

## Autosuggestions

`zsh-autosuggestions` shows greyed-out completions inline as you type.

| Key | Action |
|---|---|
| `→` or `End` | Accept full suggestion |
| `Ctrl-Space` | Accept full suggestion (custom binding) |
| `Ctrl-→` | Accept one word |

Highlight color is set to Catppuccin overlay0 (`#6c7086`) — default
`fg=8` is invisible on many terminals. Strategy is
`(history completion)` — combines past commands with completion-system
suggestions.

## ls replacement — eza

```bash
ls   # eza --group-directories-first --icons=auto
ll   # eza -l ... --git
la   # eza -la ... --git
lt   # eza --tree --level=2 --icons=auto
lta  # eza --tree --level=2 --icons=auto -a
```

Don't suggest installing `exa` — it's the unmaintained predecessor.

## Git diffs — delta

[delta](https://github.com/dandavison/delta) syntax-highlights git
diffs, adds line numbers, and supports zdiff3 conflict style. Wired
in [`dot_gitconfig`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_gitconfig):

```
[core]
    pager = delta
[interactive]
    diffFilter = delta --color-only
[delta]
    navigate = true
    line-numbers = true
[merge]
    conflictstyle = zdiff3
[diff]
    colorMoved = default
```

Inside `git log -p` or `git diff` the pager:
- `n` / `N` — jump between files
- standard `less` motions work

## Greeting — fastfetch

Runs only in interactive terminals that are NOT inside tmux, zellij,
or SSH. The check is in `dot_zshrc.tmpl`:

```bash
if [[ -o interactive && -z "$TMUX" && -z "$ZELLIJ" && -z "$SSH_TTY" ]]
```

Keeps the SSH and tmux experiences clean while still showing the
fastfetch summary on the bare terminal.

## tmux helpers (replaces omz tmux plugin)

```bash
ts                 # new tmux session
ts <name>          # new tmux session named <name>
ta                 # attach to latest
ta <name>          # attach to named
```

Defined as zsh functions, not aliases, so they handle the
"`-` prefix means it's a flag, not a name" edge case correctly.

## Node version management — nvm (lazy)

Sourcing `nvm.sh` is slow (~250ms). The zshrc instead:

1. Eagerly prepends the *default* node version's bin dir to PATH (free,
   no subprocess). Globally installed npm CLIs (`pi`, `tsc`, `prettier`)
   work immediately.
2. Lazy-loads `nvm.sh` on first `nvm` invocation. So `nvm use 18` works,
   it just takes the 250ms hit once.

Means daily-driver workflows pay zero `nvm` startup cost. Only the
rare version-switch hits the lazy load.

## Tool completions

Completion files for `kubectl`, `helm`, `minikube`, `skaffold` are
generated on demand via `<tool> completion zsh > ~/.cache/zsh/_<tool>.zsh`
and refreshed weekly (`find -mtime +7`). Cache dir: `~/.cache/zsh/`.

AWS CLI uses `aws_completer` via `bashcompinit` (bash-style completion
proxied to zsh).

Do **not** install the omz `npm`/`nvm`/`aws`/`kubectl`/`helm` plugins —
those are explicitly replaced by this native-completion-cache pattern.

## PATH

Deduplicated via `typeset -U PATH path`. Order (leftmost wins):

1. `/opt/nvim-linux64/bin`
2. `$HOME/.local/bin`
3. `$HOME/.bun/bin`
4. `$HOME/go/bin`
5. `/usr/local/go/bin`
6. `$ANDROID_HOME/{platform-tools,emulator,tools,tools/bin}`
7. Everything inherited from system

## Secrets injection — with-secrets

See [Secrets & 1Password](./secrets.md). Briefly: shell startup is
secret-free (no `op read` at login = instant `zsh`); the
`with-secrets <cmd>` function resolves `op://` refs from
`~/.config/op-dev.env` at invocation time and `exec`s into the
command. Aliased automatically for `pi` and `claude` so they "just
work."

## Editing this page

Source: [`docs/src/shell.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/shell.md)

Anything new added to the shell stack (history tool, prompt, picker,
init line in `dot_zshrc.tmpl`) should get a section here.
