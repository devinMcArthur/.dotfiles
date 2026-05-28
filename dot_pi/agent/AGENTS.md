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

## Vault use policy

Obsidian vault at `~/personal/SecondBrain`, indexed by pi-knowledge-search
via Ollama (`nomic-embed-text`, 768-dim, local on `127.0.0.1:11434`).
Config: `~/.pi/knowledge-search.json` (chezmoi-managed).

The vault is reserved for things that are about Devin — ideas,
projects, positions, relationships, observed patterns. It is NOT for
laptop configuration docs (those live in `~/.local/share/chezmoi/docs/`,
future work), ephemeral session scratch (use pi-memory / `ctx_search`),
behavioral corrections (use `save_lesson` → this file), or per-repo
project state (use that repo's `ROADMAP.md`).

### Three behaviors that distinguish "indexed notes" from "knows me"

**1. Re-surface before being asked.** When the user mentions a topic
that may have prior context in the vault — projects, people, ideas,
decisions, places, recurring themes — call `knowledge_search` FIRST,
then answer. Local Ollama makes this ~50ms; treat it as cheap and run
it speculatively.

When referencing a vault fact, ALWAYS cite the source note in wikilink
form: "Per [[Okotoks Property Search]], you said..." Never assert
vault-derived facts without citation. This makes them verifiable,
correctable, and strengthens the link graph.

**2. Capture with texture, not facts.** When writing a daily entry or
an evergreen note, capture the *why* and the *connections*, not just
the *what*. Bad: "Considering Okotoks." Good: "Chewing on Okotoks since
2026-04. Pull: land cost, family proximity. Push: distance from work
hub. Open question: partner alignment." The texture is what makes
future recall feel like memory, not retrieval.

Use `[[wikilinks]]` liberally inside captures — link to people, places,
projects, prior concepts. The graph is the brain; search is the
fallback.

**3. Synthesize, don't just accumulate.** Dailies grow forever and
nobody re-reads them. The unlock is rolling distillation: when
`knowledge_search` for a topic returns 3+ daily-note hits spanning 2+
weeks, propose an evergreen note that absorbs the fragments and links
back. Dailies become citations; evergreens become the readable layer.

### Capture rules

**Daily journals — `Dailies/YYYY-MM-DD.md`**

At first substantive turn of a session, ensure today's daily exists
(create with `# YYYY-MM-DD` header if not). Accumulate proposed entries
internally — when a notable thing happens (decision made, problem
solved, plan formed, idea articulated, project milestone), draft a
2–3 line bullet under a `## HH:MM — <topic>` header.

Friction model: **BATCHED**, not per-bullet. Surface accumulated
bullets at:
- End of session
- After major-event triggers (multi-phase work completes, user makes a
  significant decision, session crosses ~30min mark)

User approves/edits the batch; pi writes after approval.

**Evergreen personal notes — `Ideas/`, `Development/<project>/`,
top-level concept notes, `People/`**

Always propose-then-write (vs. dailies which can be batched). These
are claims about who the user is — higher stakes than a timestamped
bullet.

Before proposing a new note, `knowledge_search` for related existing
notes. Prefer updating an existing note (linked from the daily) over
creating a new one. Only create new when the topic is genuinely
distinct.

**Meta-layer — `About Me/`**

Pi maintains a small set of evergreen observations about the user's
patterns, recurring themes, and current focus. Examples:
- `About Me/Current focus.md` — what user is actively working on
- `About Me/Work patterns.md` — observed habits across sessions
- `About Me/Recurring ideas.md` — patterns noticed across sessions

Strict norms for `About Me/` entries:
- ALWAYS date the entry
- ALWAYS cite the daily/session that prompted the observation
- NEVER state certainty you don't have — use "noticed across N sessions"
  not "Devin is X"
- ALWAYS propose; NEVER auto-write

**People — `People/`**

Note per person who matters in user's life. Capture: how they're
connected, last meaningful context, recurring themes when mentioned.
When user mentions a person by name, auto-surface their note via
`knowledge_search`. Existing `Relationships/` folder may already cover
some of this — check first, complement, don't duplicate.

### Git discipline (non-negotiable)

The vault is a git repo with origin `git@github.com:devinMcArthur/SecondBrain.git`
(private). It is the transport layer for Raphael (the cloud agent),
so lapsed commits = stale cloud side, AND missed pulls = stale
local view of what Raphael wrote.

**Pull before every batch of vault writes.** No judgment call, no
"long session" carve-out. Every time a turn produces one or more
vault writes, the FIRST action of that turn is:

```bash
cd ~/personal/SecondBrain && git pull --rebase
```

- **Batch = the writes in a single turn.** Pull once at the top of
  the turn, then perform all the writes for that turn, then
  commit + push each (separate commits per the granularity rules
  below).
- A turn with zero vault writes does not need a pull. A new turn
  later with another write needs another pull.
- `--rebase` avoids merge-commit noise.
- If the pull surfaces conflicts, STOP and ask the user how to
  resolve. Don't auto-resolve vault conflicts — they're meeting
  minutes, decisions, observations, not code.

The ~100–300ms cost of a current-repo pull is trivial; the cost of
writing on top of stale state (and silently overwriting Raphael's
just-pushed contribution) is not.

**Push after every write.** When to commit:
- One commit per evergreen note write (each is a separate decision)
- One commit per `About Me/` entry
- One commit per `People/` entry
- Batch dailies: one commit at end-of-session-batch-surface, not per
  bullet
- Never mix unrelated writes into the same commit

**Commit + push procedure:**

```bash
cd ~/personal/SecondBrain
git add -A <path(s) just written>
git commit -m "vault: <what changed, one line>"
git push
```

**Commit message format:** `vault: <one-line summary>`. Body optional
but welcome for context (the *why*, not just the *what* — same
texture rule as the notes themselves).

**If push fails because remote moved** (Raphael got there first):
`git pull --rebase` then retry the push. This is normal and not an
error.

**If push fails for other reasons** (offline, auth lapse, etc.):
say so EXPLICITLY in the response to the user. Never silently
swallow a failed push — that's exactly how lapsed-commit drift
starts. Commits accumulate locally and push goes through on next
try; that's fine, just surface the state.

**Mid-session re-index after pulling.** When new notes arrive via
`git pull --rebase` mid-session, pi-knowledge-search does NOT
auto-reindex — it walks the vault only at session startup. To make
Raphael's just-pulled writes searchable in this session, the user
must run the `/knowledge-sync` slash command. Surface that prompt:

> Pulled N new notes from Raphael. Run `/knowledge-sync` to make
> them searchable in this session.

Ollama itself is passive — it only embeds when asked. pi-knowledge-
search is the driver; it asks Ollama to embed new chunks during
indexing. The local vector DB lives in `~/.pi/...` (NOT in the
vault, NOT chezmoi-managed).

**Don't manage `.obsidian/`:** the vault has `.gitignore` rules
excluding `workspace.json` and other constantly-touched Obsidian
state. Don't override them; that noise is what made commits feel
unproductive and caused the workflow to lapse in the first place.

---

## Subagent delegation policy

**Core principle:** subagents are *specialists*. Use them when the
task benefits from a focused, specialized system prompt — not
primarily as context-savers, not as a way to parallelize for its own
sake. The unique value is the agent's pre-loaded role.

### Builtin specialists (when each shines)

| Agent | Use when |
|---|---|
| **researcher** | Web research with multiple unknowns; comparing options; verifying training-data recall against current sources |
| **planner** | Designing an implementation from requirements + codebase context; *forked* so it sees what we've discussed |
| **oracle** | Validating a risky decision against accumulated session state; protects against drift; *forked* |
| **reviewer** | Reviewing a diff, plan, proposed solution, or PR; second-guessing my own work |
| **scout** | Fast codebase recon — "where does X live, what calls Y" — returns compressed context, not raw files |
| **worker** | Implementation work on a well-specified change; *forked* so it inherits decisions |
| **delegate** | Lightweight pass-through; inherits parent model with no defaults |
| **context-builder** | Generates a meta-prompt for a downstream agent when the framing itself is part of the work |

### Positive triggers (spawn a subagent when ANY hold)

1. **The task needs a specialized stance.** Reviewing my own work
   benefits from a reviewer's adversarial framing; planning a refactor
   benefits from a planner's structured framing. Stance > my
   default.
2. **The task is well-defined research with a deliverable shape.**
   "Compare embedding models on retrieval quality and licensing" is
   a researcher task. "What's that one library called" is not.
3. **Decision validation on a risky / load-bearing change.** Fire
   `oracle` before executing irreversible work — vault schema
   changes, infra topology shifts, security policy edits.
4. **Parallel exploration of N independent options.** Steelmanning
   3 architectures is 3 parallel `researcher`s, then I synthesize.
   Linear reasoning misses things parallel exploration catches.
5. **The task would consume >5KB of raw output** I'd otherwise read.
   `scout` returns the compressed summary; the bytes stay in its
   session.

### Anti-triggers (do NOT spawn a subagent when)

- The task is one-and-done shell work I'd execute inline anyway
- The task requires the conversational state of THIS session and
  context-fork doesn't capture it (rare but happens — e.g.,
  evolving design decisions over many turns)
- The task is small enough that subagent overhead (spawn latency,
  separate token budget, context shipping) dominates the work itself
- I'm already mid-execution on a sequential plan; switching to a
  subagent mid-flow breaks the user's mental model

### Custom agents (the real long-term lever)

The builtins are generalists within their specialties. The bigger
unlock is **defining custom agents** for recurring workflows in
Devin's specific stack. Propose a custom agent when:

- The same kind of task recurs across sessions with similar shape
- A specialized prompt + skill set + default tool list would
  meaningfully outperform a generic builtin
- The agent has a recognizable identity ("the bow-mark reviewer,"
  "the chezmoi-config auditor," "the vault curator")

Candidates worth proposing as they come up:

- **bow-mark-reviewer** — knows bow-mark conventions, test
  protocol, deploy pipeline; reviews diffs against those
- **chezmoi-auditor** — reviews dotfiles changes for the patterns
  in this repo (sudo-gate, lessons, secrets layout)
- **vault-curator** — follows the Vault use policy strictly;
  used for end-of-session daily distillation, evergreen proposals,
  About Me synthesis
- **raphael-architect** — knows raphael's docs/plans/ structure,
  reviews proposed changes against the Vision doc and existing
  plans

Don't create speculatively. Wait until I'm about to do the work
for the second or third time, then propose: "This is the third
bow-mark review this month — want to spin up a `bow-mark-reviewer`
so this gets the right stance every time?"

### Visibility

Subagents run as visible child tasks in pi's UI — progress
indicators, identifiable by agent name. They are NOT stealthy.
If the user is surprised to see one, that's a signal I'm
delegating too aggressively or without explaining why; surface
the intent first when in doubt.

---

## Lessons learned

<!-- Auto-appended by `save_lesson`. Newest first. -->
- 2026-05-28: Prefer wrapper scripts in ~/.local/bin (which is ahead of /usr/bin in PATH) over zsh aliases for shadowing system commands. Aliases only work in interactive shells, don't compose with sudo/xargs/env, and don't survive non-shell launchers (Hyprland binds, .desktop Exec=, systemd units).
- 2026-05-28: Empty `.mcp.json` files crash pi at startup (`pi-mcp-adapter: Unexpected end of JSON input` on `JSON.parse("")`). Recurring root cause: tools like Claude Code scaffold batches of 0-byte stubs in repos (`./.mcp.json`, `.claude/{agents,commands,settings.json,skills}`) and never fill them — seen in both `~/personal/raphael` (May 1) and `~/work/bow-mark` (May 5). They don't regenerate, but each new repo with that history crashes pi on first entry. `pi-safe` now auto-repairs empty `./.mcp.json` to `{"mcpServers":{}}` at startup — if pi still complains about the file, check it's actually 0 bytes (the wrapper only repairs empty ones, not invalid-JSON ones).
- 2026-05-27: When a Wayland app (virt-viewer in fullscreen, mpv with --input-keyboard-grab, etc.) uses the keyboard-shortcuts-inhibit-v1 protocol, ALL keys including Super flow to that app — Hyprland's normal binds AND submap-toggle binds become unreachable. The fix isn't a submap (toggle never reaches Hyprland). The fix is the `bindp` flag (hyprlang) / `bypass = true` (Lua), which makes a specific bind override the inhibit request and always fire. Wiki's "passthrough submap" example in the FAQ is for the OPPOSITE problem (apps that don't grab, where Hyprland keeps intercepting Super). Diagnose with `hyprctl submap` (default = not stuck) + check `hyprctl clients` for the focused window to confirm it's grabbing.
- 2026-05-27: Hyprland 0.55+ deprecated hyprlang config in favor of Lua (hyprland.lua), and along the way (a) removed windowrulev2 entirely — errors hard, not just warns — and (b) broke the hyprlang `windowrule` parser for v2-style filters (`class:^(foo)$`) AND bare value-less actions (`float`, `tile`, `fullscreen`, `noborder`) because the unified parser confuses them with v2 filter field names ("invalid field float: missing a value"). In 0.55 hyprlang, `windowrule` only parses cleanly when the action takes a value-arg (opacity, workspace, size) and the filter uses v1 `match:class FOO` syntax. Combined class+title rules and float-as-action rules are NOT expressible in hyprlang anymore — need Lua. Wiki: "Looking for the old hyprlang syntax? Check the 0.54 wiki pages."
- 2026-05-27: Hyprland deprecated the separate `windowrulev2` directive — the unified `windowrule` now takes v2-style filters (`class:^(...)$`, `title:^(...)$`) directly. Use `windowrule = float, class:^(foo)$` not `windowrulev2 = float, class:^(foo)$`. Old name still parses but warns on every reload.
- 2026-05-27: oh-my-zsh ssh-agent plugin + tmux session-restore = passphrase prompt per pane. The plugin's per-shell spawn-or-attach logic races on ~/.ssh/environment-$SHORT_HOST when many panes restore simultaneously post-reboot: each sees a dead cached socket, each spawns its own ssh-agent, each clobbers the cache file, each runs ssh-add. Same anti-pattern as the existing oh-my-zsh+antidote lessons. Fix: 1Password SSH agent (single stable socket at ~/.1password/agent.sock, conditional `export SSH_AUTH_SOCK=~/.1password/agent.sock` in zshrc, kill the plugin entirely). Works for ssh, git, scp, rsync — anything that consults SSH_AUTH_SOCK.
- 2026-05-25: DAILIES ARE NEVER OPT-IN. Stop asking variants of "want me to update the daily?" — that's friction the user explicitly rejected twice on 2026-05-25. The Vault use policy's "propose before write" rule is for EVERGREEN notes, About Me/, and People/. Dailies are continuous append-as-noteworthy-things-happen, no permission required. If something is noteworthy enough that I'd ask, that's the signal to JUST WRITE IT.
- 2026-05-25: Vault git is BIDIRECTIONAL — Raphael (cloud agent) also pushes. Pull at session start (`git pull --rebase`) before any vault work. For long sessions, pull again before writes if Raphael may have pushed. After pulling new notes mid-session, prompt user to run `/knowledge-sync` because pi-knowledge-search only indexes on session startup. Ollama is passive — it just embeds when asked; pi-knowledge-search is what drives indexing.
- 2026-05-25: After ANY write to the Obsidian vault at ~/personal/SecondBrain, immediately git add + commit + push to the github.com:devinMcArthur/SecondBrain origin. The vault is now the transport layer for Raphael (the cloud agent) and lapsed commits leave the cloud side stale. Conventions: one commit per evergreen/About Me/People write (separate decisions); batch dailies into one commit at end-of-session-batch-surface. Commit message format: `vault: <what changed in one line>`. If push fails (offline), say so explicitly — don't silently swallow.
- 2026-05-25: Don't ask permission to update today's daily in the vault — it's a living document by design and asking adds friction. The "batched proposal at session end" rule from the Vault use policy is about *evergreen* notes; dailies are continuous appends.
- 2026-05-25: Never wrap TUI/interactive commands with `op run --env-file=... -- <cmd>`. `op run` interposes pipes on the child's stdout/stderr to do secret-masking, which makes isatty() return false in the child. Result: TUI apps render half-screen and don't accept input (pi), or refuse to start ("use stdin or --print" — claude). For interactive consumers, instead use a shell-function pattern that runs `op read` per op:// reference inside a subshell, exports the values, and `exec`s into the target — that way the child inherits the env normally AND keeps its real TTY. `op run` is only safe for non-interactive child processes that don't care about TTY (CI tasks, batch scripts).
- 2026-05-25: When user signals multi-phase / multi-item work ("let's tackle 1-4", "phased plan", "step-by-step incremental phases"), PROACTIVELY write a roadmap doc to a persistent location at the START of the work, not the end. Conventional path: `<project-repo-root>/ROADMAP.md` or similar. Capture (a) full numbered plan as proposed, (b) reasoning per item, (c) non-decisions ("we chose X over Y because..."). Update it inline as items complete — move them to a Done section with a one-line outcome. This is critical for chezmoi/dotfiles/infra projects where work spans many sessions: in-context plans evaporate when sessions end, but committed markdown survives and any future pi session reads it from the repo. AGENTS.md captures cross-cutting lessons; ROADMAP.md captures project-specific state-of-the-work. Do both.
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
