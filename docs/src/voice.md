# Voice — dictation, spoken replies, voice control

Three independent pieces, all local. Nothing here sends audio or text
off the machine.

| Direction | What | Tool |
|---|---|---|
| **In** | speak → text at the cursor | voxtype (whisper.cpp) |
| **Out** | Claude Code's replies read aloud | claude-tts (piper / Kokoro) |
| **Control** | speak or type → the machine acts | voice-control (whisper + a local LLM) |

## Voice in — dictation

**Super+X** starts and stops dictation; **Super+Shift+X** cancels it.
It is a toggle, not push-to-talk: a release-bind on a modifier chord
misfires whenever Super lifts before X.

Spoken formatting, handled in `[output.post_process]` of
[`dot_config/voxtype/config.toml`](https://github.com/devinMcArthur/.dotfiles/blob/master/dot_config/voxtype/config.toml):

| Say | Get |
|---|---|
| "new line" | a line break — typed as **Shift+Enter**, so it does not submit a chat box |
| "new paragraph" | a blank line |
| "submit" (at the end) | the word is stripped and **Enter** is pressed |

Whisper's own punctuation is left on; only line breaks are spoken.
Whisper brackets the spoken phrase with invented punctuation (", new
line," one run, ". New line." the next), so conversion and debris
cleanup happen in **one** sed pass that still sees the phrase — a
two-stage version could never win.

`initial_prompt` feeds whisper this machine's proper nouns (repos,
hostname, tooling). That is what stopped "bow mark" transcribing as
"bullmark", and it helps ordinary dictation too.

### Auto-stop — `voxtype-autostop`

Dictation ends when you say **"submit"**, without a second Super+X.
voxtype has no stop-on-silence, and local whisper cannot hear the word
until recording ends, so this watcher supplies the stop: it reads a
parallel capture of the mic, and ~1s after you go quiet it transcribes
just the last 4s with `tiny.en` and stops only if the tail really ends
on the trigger word.

Thinking pauses are therefore free — a pause not followed by the word
costs one cheap check and nothing else, since the buffer cannot change
while you are silent. A 20s silence stops the recording anyway, for
walking away mid-sentence.

```bash
voxtype-autostop status      # armed? window? trigger word?
voxtype-autostop word send   # change the trigger word
voxtype-autostop secs 30     # walk-away limit
voxtype-autostop off         # back to Super+X only
```

## Voice out — `claude-tts`

Claude Code's replies read aloud, via hooks registered by hand in
`~/.claude/settings.json` (app-managed, so **not** chezmoi-tracked):

| Hook | Speaks |
|---|---|
| `Stop` | the final message of a turn |
| `PreToolUse` | interim progress text, once per message |
| `Notification` | work **finishing** (background session, quota resume) |

Notifications that mean *you are needed* (permission prompts, idle) are
deliberately silent — they interrupted the reply being read, and the
screen already shows them.

**Hooks never read the transcript directly.** The transcript is written
*after* the hooks fire, so reading it at hook time returns the previous
message — which is exactly what made replies arrive stale or half-read.
Each hook logs, spawns a detached waiter, and returns instantly; the
waiter polls for an entry newer than the last one spoken (monotonic on
timestamp, so speech can never walk backwards) and reads it. Messages
queue rather than chop each other off.

### Voices

Two engines behind one selector. Kokoro sounds markedly better; piper
starts faster.

```bash
claude-tts voice                     # list (piper + kokoro)
claude-tts voice kokoro-af_heart     # switch (active default)
claude-tts voice en_US-ryan-high     # piper: ~1s faster to first word
claude-tts setup-kokoro              # fresh machine: venv + models (~340MB)
```

Kokoro synthesises sentence-by-sentence with a producer thread running
ahead of playback, clause-splits anything over ~90 characters, and
banks ~2s of audio before the first byte — three fixes that together
removed the mid-message stalls.

### Muting

**Super+Ctrl+V**, the **Claude Voice pill** in the bar, or
`claude-tts off` — all flip the same flag file, so they stay in sync
and take effect mid-sentence.

## Voice control — `voice-control`

Say **"turing"** (or "computer"), then a command — in one breath, or
pause after the wake word and wait for the beep. Or press **Super+;**
and type it.

Three tiers, escalating only when needed:

1. **Grammar** (~30 phrases, instant): workspaces, windows, launchers,
   panels, volume, brightness, media, theme, lock, tmux sessions.
   `voice-control list` prints them.
2. **Destinations** (instant): open tabs first, then Firefox bookmarks,
   then `~/.config/voice-control/places.conf`. A tab answers to its
   title *and* to the words in its domain, so "the bow mark app" finds
   `paving.bowmark.ca` — including localhost dev servers no bookmark or
   model could know.
3. **Local LLM** (`qwen2.5:3b` via ollama, ~2-3s): anything unmatched.

### The safety model

The model **never emits a shell command.** It fills in one typed action
— url, gh, app, hypr, dms, tmux, script — and every field is validated
against an allowlist before anything runs, so a hallucination is a
rejected plan rather than an arbitrary command.

Layers, in order:

- Destructive wording (`sudo`, `rm`, `delete`, `format`, …) is refused
  **before the model sees it**. It will map any utterance onto
  *something*: "run sudo rm -rf" came back as a screenshot.
- The catalog is non-destructive by construction — the blast radius of
  a bad plan is a surprising action, not a dangerous one.
- Scripts carry safe default arguments. "show me the backup status"
  dropped the word `status`, and bare `laptop-backup` **runs a backup**;
  an omitted field must not escalate what a command does.
- It ignores its own voice by **content**, comparing what it hears
  against the text claude-tts is currently speaking — muzzling the mic
  outright made commands impossible for the 30-60s it takes to read a
  long reply.

### Feedback

| Channel | Success | Failure |
|---|---|---|
| Voice | rising chime | low buzz |
| Typed (Super+;) | notification naming the action | notification saying why not |

Commands whose result lives in a window (a URL, a tmux session, an app)
focus that window afterwards, switching workspace if needed.

```bash
voice-control status         # listening? asleep? wake word? model?
voice-control ask "..."      # full path incl. the model, no mic
voice-control test "..."     # grammar only
voice-control llm off        # grammar + destinations only
voice-control debug          # log EVERY utterance heard (privacy: off when done)
voice-control off            # stop listening
```

Spoken **"turing sleep"** stops it acting; **"turing wake up"** resumes.

## Logs

| File | Contents |
|---|---|
| `~/.local/state/voice-control/log` | what was heard, the plan, what ran, why it was refused |
| `~/.local/state/claude-tts/hook.log` | which hook fired, and whether it spoke |
| `journalctl --user -u voxtype -f` | the dictation daemon |

## Lessons learned

- **`pkill -f` matches any process whose command line *mentions* the
  pattern** — including the shell testing the script. It repeatedly
  killed test runs (exit 144). Playback now runs in its own process
  group, tracked per launch, so stop and interrupt are exact.
- **Discarded stderr hid three separate bugs** in one evening: a
  rejected model argument, a missing `HYPRLAND_INSTANCE_SIGNATURE`, and
  a bash syntax error in a generated command. All three failed silently
  into `/dev/null` while appearing to work.
- **A daemon thread dies with its process.** Focus-follow ran in one,
  and the typed path exits immediately after launching a command, so it
  silently never fired — and passed a test once, by luck of timing.
- **Desktop commands need their environment resolved at run time**, not
  inherited: a daemon started from the wrong shell has no Hyprland
  signature, and a session's signature goes stale after a reboot.
- **`voxtype --model` wants a model NAME**, not a path; given a path it
  warns and silently falls back to the configured model.
- **Observation beats inference.** "The bow mark app" needed no smarter
  model — the app was open in a tab, and nothing had bothered to look.

## See also

- [Secrets & 1Password](./secrets.md) — how the API key reaches Claude Code
- [Keybinds](./keybinds.md) — every binding, auto-generated

## Editing this page

Source: [`docs/src/voice.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/voice.md)
