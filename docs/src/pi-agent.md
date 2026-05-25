# Pi agent

The pi-coding-agent CLI plus chezmoi-managed extensions and configs.

Config root: `~/.pi/agent/`
- `AGENTS.md` — cross-session memory + behavioral policy (Vault use, Subagent delegation, Git discipline, etc.)
- `extensions/` — TypeScript extensions (auto-discovered)
- `knowledge-search.json` — pi-knowledge-search config (vault path, Ollama provider)
- `keybindings.json` — (optional) custom keybind overrides

## Extensions

Auto-loaded from `~/.pi/agent/extensions/*.ts`. All three are chezmoi-managed.

### sudo-gate.ts

Confirmation gate for `sudo`/`yay` invocations from pi's `bash` tool.
Also installs a compact footer with a shield-check glyph.
Opens zenity dialog before privileged commands run; allowlist of
NOPASSWD binaries (systemctl, fw-ectool) skips the password path.

See also [Secrets](./secrets.md) for the faillock + sudoers story.

### lessons.ts

- `/lesson [global|project] <text>` slash command
- `save_lesson` tool that pi can call autonomously when detecting a
  correction or stable preference

Writes to `AGENTS.md` (global = `~/.pi/agent/AGENTS.md`, project =
`<git-root>/AGENTS.md`). If the target is chezmoi-managed, edits the
source file and commits; otherwise writes the live file directly.

### edit-last-message.ts (CC parity)

Claude-Code-style "edit your last message" workflow:

- **`alt+e`** — rewinds session to before your most recent user message,
  restores that message text into the editor for editing
- **`/edit-last`** — same effect, slash-command form

Implementation note: pi's `ctx.fork(entryId, { position: "before" })`
forks before a message AND auto-restores its text. Shortcut handlers
only receive `ExtensionContext` (no `fork()`), so the `alt+e` keybind
dispatches via `pi.sendUserMessage("/edit-last")` — the input pipeline
matches the extension command first, routing to the proper Command
context.

## Knowledge search + Ollama

Separate page: [Obsidian + knowledge search](./obsidian.md).

## Subagents

Pi supports a full subagent system (`scout`, `researcher`, `planner`,
`oracle`, `reviewer`, `worker`, `delegate`, `context-builder`) plus
custom agents. Behavior policy in `~/.pi/agent/AGENTS.md` under
**Subagent delegation policy**. The headline rule: subagents are
*specialists* — use them when the task benefits from a focused
system prompt, not just to save context or parallelize.

## Settings

`~/.pi/agent/settings.json` is **NOT** chezmoi-managed (pi writes to
it at runtime; chezmoi would revert it). Listed in `.chezmoiignore`.

For portable config preferences, use `AGENTS.md` instead — it's
human-edited (not app-written) and survives chezmoi apply.

## Editing this page

Source: [`docs/src/pi-agent.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/pi-agent.md)
