# Obsidian + knowledge search

The personal knowledge vault and how pi reads/writes it. **This page
is about the wiring.** The *content* of the vault — what pi knows
about Devin, daily journals, evergreen notes — lives in
`~/personal/SecondBrain` and is intentionally NOT documented here.

## Topology

```
┌────────────────────────┐    ┌──────────────────────┐
│ ~/personal/SecondBrain │    │ ~/.pi/knowledge-     │
│ (vault, ~63 .md notes) │◄───┤  search.json         │
│ Obsidian Sync handles  │    │ (chezmoi-managed)    │
│ laptop ↔ mobile        │    └──────────┬───────────┘
└────────────┬───────────┘               │
             │                           │ points at vault
             │                           ▼
             │                ┌──────────────────────┐
             │                │ pi-knowledge-search  │
             │                │ (part of             │
             │                │  pi-total-recall)    │
             │                └──────────┬───────────┘
             │                           │
             │                           │ embeds via
             │                           ▼
             │                ┌──────────────────────┐
             └────────────────┤ ollama daemon        │
                              │ 127.0.0.1:11434      │
                              │ nomic-embed-text     │
                              │ (274MB, 768-dim)     │
                              └──────────────────────┘
```

## Stack

| Layer | Choice | Why |
|---|---|---|
| Vault editor | **Obsidian** (AUR `obsidian-bin`) | Already in use; Sync subscription active |
| Cross-device sync | **Obsidian Sync** | E2E encrypted, native to Obsidian, mobile included |
| Search backend | **pi-knowledge-search** (via `pi-total-recall`) | Already installed; hybrid vector + BM25 fused via RRF |
| Embedding provider | **Ollama** with `nomic-embed-text` | Local, free, offline-tolerant — matches the rest of the stack |
| Config | `~/.pi/knowledge-search.json` (chezmoi-managed) | Static config; deploy via chezmoi |

## What pi exposes

Two tools available in every pi session once the index is built:

- **`knowledge_search`** — hybrid vector + BM25 search across the
  vault. Returns ranked excerpts. Use for "find anything about X."
- **`kb_read`** — resolves a `[[wikilink]]`, basename, or relative
  path to a specific note and returns its full content. Use when you
  know the name but not the path.

On session start, pi-knowledge-search also injects a vault overview
(folders + top keywords per folder) as a custom message — so the
model knows the vault's shape before searching.

## Config — `~/.pi/knowledge-search.json`

```json
{
  "dirs": ["~/personal/SecondBrain"],
  "fileExtensions": [".md", ".txt"],
  "excludeDirs": [
    "node_modules", ".git", ".obsidian", ".trash",
    "PDFs", "Excalidraw"
  ],
  "provider": {
    "type": "ollama",
    "url": "http://127.0.0.1:11434",
    "model": "nomic-embed-text"
  },
  "overview": {
    "inject": true,
    "maxDepth": 2,
    "maxFoldersPerDir": 20,
    "maxKeywordsPerFolder": 5
  }
}
```

**Adding more sources** (future): append to `dirs`. The chezmoi `docs/`
folder itself is a candidate to add here later — would make laptop
docs searchable from pi.

## Ollama daemon

Installed via `pacman -S ollama`. System service:

```bash
systemctl status ollama.service        # active
ss -tlnp | grep 11434                  # listening on 127.0.0.1
ollama list                            # installed models
```

Model storage: `/usr/share/ollama/.ollama/models/`. The `ollama` user
account owns this directory; pacman creates both on install.

**First-install gotcha (codified):** if `/usr/share/ollama` exists from
a stale prior install (no package owns it), `pacman -S ollama` refuses
to clobber it. Fix: `rm -rf /usr/share/ollama` before install. The
service generates its ed25519 keypair on first start.

### RAM cost

Daemon idle: ~50MB. Model loaded on demand: ~1GB peak. Released after
~5min of inactivity. Acceptable budget on this laptop.

### Other models

We're only using embeddings today. Ollama can also host generative
models (`ollama pull llama3`, `ollama run llama3 "..."`). Pi uses
Anthropic for generation; Ollama is purely the local embedding
provider here.

## Vault use policy

`~/.pi/agent/AGENTS.md` has a full "Vault use policy" section
governing how pi reads from and writes to the vault. Summary:

- **Re-surface before being asked** — pi auto-searches the vault when
  relevant topics emerge, doesn't wait to be told
- **Cite via `[[wikilinks]]`** — every vault-derived fact is cited
- **Capture with texture, not facts** — the *why* and connections,
  not just the *what*
- **Synthesize, don't just accumulate** — rolling distillation from
  dailies into evergreen notes when patterns emerge
- **Categories**: `Dailies/` (batched, accumulated then surfaced at
  session end), evergreens (propose-then-write), `About Me/` (strict
  calibration/citation norms), `People/` (per-person notes)
- **Anti-scope**: laptop docs DON'T go in vault (they're here); pi
  internal state DOESN'T go in vault (use pi-memory); per-repo
  project state DOESN'T go in vault (use that repo's `ROADMAP.md`)

The vault is reserved for things that are about *Devin* — ideas,
projects, positions, relationships, observed patterns.

## The triage that preceded this setup

Before wiring pi to the vault, we found a **nested duplicate vault**
at `~/personal/SecondBrain/SecondBrain/` — Obsidian Sync had stacked
a re-clone inside the existing vault. Inner had zero unique content
(62/63 files bit-identical). One real conflict on `The Savoy/Board
Meetings.md` preserved as `.INNER.md` / `.OUTER.md`.

Cleanup: deleted inner, deleted redundant `.OUTER.md` marker, kept
`.INNER.md` for manual merge, repointed `obsidian.json` at the outer
vault. Backup at `/tmp/SecondBrain-inner-backup.tar.gz` retired after
24h.

Lesson: **don't trust Obsidian Sync's conflict resolution silently.**
The `.INNER.md`/`.OUTER.md` markers it creates are easy to miss and
they sit alongside real notes. If you see them, fix immediately.

## Future work

Open in `LAPTOP-ROADMAP.md`:

- **Raphael integration** — bring the cloud agent into the same vault
  via git as transport. Plan doc:
  `~/personal/raphael/docs/plans/2026-05-25-vault-integration.md`
- **Add chezmoi `docs/` to `dirs`** — make laptop docs pi-searchable
- **Periodic synthesis** — automated weekly "propose evergreens from
  this week's dailies" pass

## See also

- [Pi agent](./pi-agent.md) — sudo-gate, lessons extension
- `~/.pi/agent/AGENTS.md` — full Vault use policy
- `LAPTOP-ROADMAP.md` — open Obsidian-related threads

## Editing this page

Source: [`docs/src/obsidian.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/obsidian.md)
