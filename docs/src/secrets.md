# Secrets & 1Password

Secrets live in **1Password**. The `op` CLI talks to the desktop app
via the local IPC integration (Settings → Developer → "Integrate with
1Password CLI") — no separate `op signin` flow, no API tokens, just
the desktop app's session.

## Why this design

Three constraints shaped it:

1. **Shell startup must be instant.** No `op read` calls in `.zshrc`
   or `.zprofile` — those would block on IPC every login.
2. **Secrets must survive offline.** 1Password's local vault cache
   means `op read` works without internet as long as the desktop app
   is unlocked.
3. **TUI apps need a real TTY.** `op run --env-file=...` masks
   secrets by pipe-interposing on stdout/stderr, which destroys
   `isatty()` and breaks pi, claude, and other interactive consumers.
   We use a different pattern.

## The `with-secrets` wrapper

Defined in [`dot_zshrc.tmpl`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_zshrc.tmpl).
Resolves `op://` refs at command-invocation time, exports them in a
subshell, and `exec`s into the target. The target inherits env
normally AND keeps its real TTY.

```bash
with-secrets() {
  (
    while IFS='=' read -r key ref; do
      [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || continue
      ref=${ref#\"}; ref=${ref%\"}
      [[ "$ref" == op://* ]] || continue
      val=$(op read "$ref" 2>/dev/null) || return 1
      [[ -n "$val" ]] && export "$key=$val"
    done < "$HOME/.config/op-dev.env"
    exec "$@"
  )
}
```

## The env file

`~/.config/op-dev.env` — keys mapping shell-env names to `op://` refs.
Format:

```
ANTHROPIC_API_KEY=op://Dev Secrets/anthropic/credential
OPENAI_API_KEY=op://Dev Secrets/openai/credential
```

**This file is NOT a `.env` you `source`** — it's a *mapping* file the
`with-secrets` function parses. Each value is an op:// reference,
resolved per-line per-invocation. The actual secret values never
touch disk in the dotfiles.

## Auto-injection for TUI consumers

```bash
alias pi='with-secrets pi-safe'
alias claude='with-secrets claude'
```

So typing `pi` automatically resolves Anthropic + OpenAI keys before
exec'ing into pi. Adding a new TUI consumer that needs secrets =
one-line alias.

## Adding a new secret

1. Store it in 1Password under `Dev Secrets/<service>/credential`.
2. Add one line to `~/.config/op-dev.env`:
   ```
   FOO_API_KEY=op://Dev Secrets/foo/credential
   ```
3. Any command run via `with-secrets <cmd>` now sees `$FOO_API_KEY`
   in its env. No restart needed.

## Why NOT `op run --env-file=...`

`op run` interposes pipes on the child's stdout/stderr to do its
secret-masking pass. That makes `isatty()` return false in the child.
Result:

- pi → renders half-screen, doesn't accept input
- claude → errors with "use stdin or --print"
- any TUI → broken

Codified in `AGENTS.md` lessons. **Never** wrap interactive commands
in `op run`. Use the `with-secrets` pattern instead. `op run` is fine
for non-interactive scripts (CI tasks, cron jobs).

## Offline behavior

`op read` and `op run` work offline as long as the 1Password desktop
app is **running AND unlocked** (vault is cached locally). When the
app is locked or not running, calls fail with a clear error rather
than silently returning empty strings.

In practice: I lock my laptop, walk away, unlock, immediately use
`pi` — works. I shut the lid for a flight, open in the air, unlock 1P,
use `pi` — works. The cabin-in-the-woods case is covered.

## chezmoi 1Password integration

`~/.config/chezmoi/chezmoi.toml` has:

```toml
[onepassword]
prompt = false
```

This makes `chezmoi apply` invocations that include `{{ onepasswordRead
"op://..." }}` template calls silent-resolve via the desktop CLI
integration. Without `prompt = false`, chezmoi blocks waiting for TTY
auth.

## The faillock trap (important)

Three failed sudo password attempts will lock the dev user out for 10
minutes (`pam_faillock` default `unlock_time = 600`). Our defense:

- `/etc/sudoers.d/pi-agent` sets `Defaults passwd_tries=1` so a single
  wrong password from a zenity/askpass dialog = single strike, not
  three.
- Frequently-used binaries (`systemctl`, `fw-ectool`) are NOPASSWD,
  so they use the sudo-gate's confirm-only path (no password dialog).

Diagnose locks with `faillock --user dev` (no sudo needed). Recovery
takes 10min by default or `faillock --reset` from a recovery session.

## See also

- [Shell](./shell.md) — the wrapper lives in zshrc, auto-aliased for
  pi/claude
- [Pi agent](./pi-agent.md) — sudo-gate extension is part of pi
  config

## Editing this page

Source: [`docs/src/secrets.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/secrets.md)
