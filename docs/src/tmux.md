# tmux — sessions, sesh, scratch popup

Source: [`dot_tmux.conf`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_tmux.conf)
(~150 lines, hand-written, no framework). Palette: Catppuccin Mocha.

## Why this exists

Replaces a previous gpakosz/oh-my-tmux setup. The framework was hiding
what tmux actually does; this config is short enough to read top to
bottom and own completely.

## Prefix

`C-a` (remapped from `C-b`). Press once to send to the inner shell.

## Sessions — sesh + continuum + scratch

Three patterns layered together:

### sesh (smart session picker)

`prefix + T` opens a fzf popup over sessions. Sesh is zoxide-aware —
it suggests sessions named after frecent directories you've visited,
even ones not currently open. AUR: `sesh-bin`.

The bind guards against missing binary so the popup closes cleanly
instead of hanging:

```bash
bind -N "sesh session picker" T display-popup -E -w 80% -h 70% "\
  if ! command -v sesh >/dev/null; then ...; fi; \
  sesh connect \"\$(sesh list -t -c | fzf --no-border --prompt '⚡ ')\""
```

### continuum (auto-restore across reboots)

Every 15 minutes tmux-continuum saves the full session state (windows,
panes, working dirs, plus nvim sessions and pane scrollback via
tmux-resurrect). On boot, continuum auto-starts a tmux server AND
restores last state. So you never lose layout to a reboot or update.

Installs `~/.config/systemd/user/tmux.service` automatically when the
plugin first runs.

### Scratch popup — `Alt-g`

Prefix-less. Drops a floating 80%×80% terminal that inherits the
current pane's cwd. Closes on exit. Perfect for "I need to run one
quick thing without disturbing my layout."

```bash
bind -n M-g display-popup -E -w 80% -h 80% -d "#{pane_current_path}"
```

## Keybinds

### Window/pane management

| Key | Action |
|---|---|
| `prefix &` | Kill window (no confirm) |
| `prefix x` | Kill pane (no confirm) |
| `prefix "` | Split horizontal (inherits cwd) |
| `prefix %` | Split vertical (inherits cwd) |
| `prefix h/j/k/l` | Switch pane (vim-style, repeatable) |
| `prefix ^` | Toggle last window |
| `prefix C-h` | Previous window |
| `prefix C-l` | Next window |
| `prefix r` | Reload config in place |

### Pickers / popups

| Key | Action |
|---|---|
| `prefix T` | sesh session picker |
| `Alt-g` | Scratch terminal popup |

### Copy mode (vi)

| Key | Action |
|---|---|
| `prefix [` | Enter copy mode |
| `v` | Begin selection |
| `C-v` | Rectangle selection toggle |
| `y` | Copy selection + cancel |

## Mouse on

Click panes to focus, drag borders to resize, drag windows in the
status line to reorder, scroll wheel enters copy mode and scrolls
scrollback. (Mouse on does NOT disable terminal selection — modifier
key trick passes through.)

## Modern terminal features

Several `set` lines exist purely to make tmux not get in the way of
modern terminal capabilities:

- **True color (24-bit RGB)** — `tmux-256color` + `Tc` override
- **Undercurl + underline color** — nvim LSP diagnostics render
  squigglies with the right color
- **Extended keys** — `extended-keys always` + `csi-u` format. **pi
  requires csi-u**; without it you'll see a startup warning and
  modified keys (Shift+Enter, Ctrl+Enter) may not pass through.
- **OSC 52 system clipboard** — `set-clipboard on`. Copy from inside
  tmux (or SSH'd into a host) and it lands in Wayland's clipboard via
  Ghostty's OSC 52 handler.
- **Allow passthrough** — `allow-passthrough on` lets nested apps emit
  raw escape sequences. Required for nvim's `image.nvim` plugin (kitty
  graphics protocol via Ghostty).

## Status line

- Catppuccin Mocha palette (defined once at top, referenced below —
  hex literals stay together)
- Position: bottom
- Left: session name + hostname
- Right: weekday/month/day + HH:MM
- Window: mauve background for current, peach for any with activity
- Monitor-activity highlighting on — windows with output get peach-bold
  in the status line (no popup, just visual mark)

## Plugins (tpm)

- `tmux-sensible` — baseline defaults the upstream maintainer agrees with
- `tmux-yank` — system clipboard integration (paired with OSC 52)
- `tmux-resurrect` — save/restore session contents (panes, scrollback,
  nvim sessions)
- `tmux-continuum` — auto-save every 15min, auto-restore on tmux start,
  auto-boot tmux server at login

First-time setup needed: `prefix + I` (capital I) to install all
plugins via tpm.

## Helper functions (in zsh, not tmux)

See [Shell](./shell.md):

```bash
ts                 # new tmux session
ts <name>          # named
ta                 # attach to latest
ta <name>          # attach to named
```

## Lessons learned the hard way

- **csi-u format is NOT optional for pi.** The default xterm format
  silently drops modified keys for pi's TUI. Codified in
  `AGENTS.md` lessons.
- **`allow-passthrough on` matters even if you don't think you use
  kitty graphics** — nvim plugins that show images use it.
- **Don't switch to zellij.** tmux+sesh+continuum covers everything
  zellij was tempting for, and the muscle memory is dialed in.

## Editing this page

Source: [`docs/src/tmux.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/tmux.md)
