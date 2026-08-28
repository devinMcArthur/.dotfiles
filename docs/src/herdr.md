# herdr — agent multiplexer

A tmux-like multiplexer built around AI coding agents. It detects agents
running in its panes (Claude Code and others) and shows each one's state
in the sidebar — **working, blocked, done, idle** — rolled up per
workspace. The point is answering "which agent is waiting on me?"
without visiting every pane.

**tmux is still installed and still configured.** It keeps the SSH and
long-haul-persistence role, where twenty years of tmux beats a young
project; herdr owns the local agent workflow. The two nest fine if you
want both (see below).

## The model

| herdr | roughly |
|---|---|
| **Workspace** | one project/repo — the sidebar entries |
| **Tab** | a layout within a workspace (`agents`, `logs`, `server`) |
| **Pane** | a real terminal, splittable, surviving detach |

`cd` into a project and run `herdr`; it creates or attaches to that
project's workspace. Panes inherit the workspace root, so a split beside
an agent is already in that agent's repo — no `-c "#{pane_current_path}"`
equivalent needed. It tracks `foreground_cwd` separately from the pane's
start directory, so "where the agent actually is" stays accurate.

## Keys

Prefix is `ctrl+b` (tmux here is `ctrl+a`, so nesting never collides).
`prefix+?` shows the live keymap — the authority, since it reflects the
rendered config.

| Do | Press |
|---|---|
| Next / previous **agent** | `prefix+a` / `prefix+shift+a` |
| Jump to agent N | `prefix+alt+1..9` |
| Next / previous **workspace** | `prefix+shift+l` / `prefix+shift+h` |
| Jump to workspace N | `prefix+shift+1..9` |
| Pane focus | `prefix+h/j/k/l` |
| Split right / down | `prefix+v` / `prefix+minus` |
| New tab | `prefix+c` |
| Workspace picker / goto | `prefix+w` / `prefix+g` |
| Detach | `prefix+q` |
| Scratch popup | `alt+g` (or `prefix+alt+g`) |
| Scrollback into nvim | `prefix+e` |

Agent hopping, workspace stepping and indexed switching all ship
**unbound** upstream; they are set in the managed config.

## Across a restart

| Survives | Does not |
|---|---|
| Workspaces, tabs, panes, cwd, layout, focus | Running processes — panes come back as fresh shells |
| Agent *conversations*, resumed automatically for supported agents (Claude Code included) | Scrollback, unless history replay is enabled |

Screen-history replay is deliberately **off** (upstream default): restored
panes would re-render old output, and these panes carry 1Password
material, tokens and command output.

The server starts at login (`exec-once` in hyprland.conf), headless — no
window until you attach. So the session shape is already restored and
agent conversations already resumed by the time you open a terminal and
run `herdr`; rebuilding workspaces by hand is not part of the morning.

**The vault is locked at login**, which matters because agent panes are
resumed then. `claude` is a shell function rather than a plain
`with-secrets` alias for exactly this reason: with-secrets returns 1
*before* exec when it cannot read a secret, so an alias would leave
every restored pane dead on arrival. The function uses the injected key
when 1Password answers and starts Claude Code on its own stored login
when it does not, printing one line to say so.

Lid close hibernates rather than reboots (see [Power](./power.md)), so
the common overnight case restores every process anyway — real restarts
are mostly kernel updates.

## How it is managed

| Piece | Where |
|---|---|
| Binary | `run_onchange_after_herdr-install.sh.tmpl` — pinned version from the GitHub release into `~/.local/bin`, no sudo. Bump `HERDR_VERSION` to upgrade |
| Config | `dot_config/herdr/config.toml.tmpl` — rendered from `.chezmoidata` theme tokens |
| Theme | `theme set` re-renders it and calls `herdr server reload-config`, which applies live |

Five of the six themes map to a herdr built-in by name; matte-black
borrows `vesper`. Either way the accent, sidebar, selection and status
colours come from the same palette everything else uses.

`herdr config check` validates; `herdr server reload-config` applies
without restarting.

## The agent skill

`herdr --skill` emits a Claude Code skill that lets an agent drive herdr
— inspect neighbouring panes, create layout, start agents and commands,
read output, wait on state changes. The installer writes it to
`~/.claude/skills/herdr/SKILL.md` straight from the binary, so it always
matches the installed version.

It self-gates on `HERDR_ENV=1` and is inert outside a herdr pane, and
its own description says to use it only when herdr is explicitly
mentioned — so it will not quietly start spawning agents.

## Worth exploring, not yet configured

- **Worktrees** (`prefix+shift+g`, `herdr worktree create`) — a git
  worktree opened as its own workspace, so two agents on one repo cannot
  collide over the working tree. The obvious next step for parallel work
  on a monorepo.
- **Notifications and sounds** — `[ui.sound]` plus background popup
  delivery (`terminal` or `system`) when an agent in a background
  workspace goes blocked or done. Overlaps with the spoken notifications
  in [Voice](./voice.md); pick one rather than both.

## Lessons learned

- **Never bind `ctrl+h`.** It is ASCII backspace — a terminal cannot tell
  them apart, so the binding silently never fires. It validated fine and
  did nothing. Plain letters and shift chords survive; `alt` chords are
  the first to break when nested under tmux.
- Its own `--help` points AI agents at `herdr.dev/agent-guide.md` for
  setup and `herdr.dev/llms.txt` for debugging — faster than guessing at
  the keymap.

## See also

- [tmux](./tmux.md) — still the tool for SSH and resurrect-on-login
- [Voice](./voice.md) — spoken notifications solve the same
  "which agent needs me" problem by ear

## Editing this page

Source: [`docs/src/herdr.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/herdr.md)
