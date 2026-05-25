# Turing — laptop reference

This is a reference manual for **turing** — Devin's Framework 13 laptop
running Arch + Hyprland. It's the *what & why* layer on top of the
configs in this chezmoi repo.

## What this is

A categorical reference. Every page covers one capability area:
*shell*, *window manager*, *power*, *secrets*. Each page says what's
installed, what each piece does, why it's there, and how to invoke it.

## What this is NOT

- **Not a roadmap.** Project state for this laptop's evolution lives in
  [`LAPTOP-ROADMAP.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/LAPTOP-ROADMAP.md)
  at the repo root. Roadmap = what's planned + done in order; this
  reference = what currently *exists*.
- **Not personal knowledge.** Notes about *Devin* — ideas, projects,
  positions, observations — live in the Obsidian vault at
  `~/personal/SecondBrain`, not here. See [Obsidian + knowledge
  search](./obsidian.md) for the boundary.
- **Not exhaustive config docs.** The configs themselves are
  self-documenting (commented). This site is the *index* — it tells
  you which file to open and why.

## How to read this

- **Looking for a keybind?** Jump to [Keybinds](./keybinds.md) —
  auto-generated from `hyprland.conf`, `tmux.conf`, and zshrc aliases,
  so it never lies.
- **Looking for *what tool does X*?** Sidebar nav is by capability.
- **Looking by name?** Top-right search (mdBook indexes all pages).
- **Looking for project status?** Open
  [`LAPTOP-ROADMAP.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/LAPTOP-ROADMAP.md)
  in the repo root instead.

## How to launch this site

```bash
cd ~/.local/share/chezmoi/docs
mdbook serve --open
```

Hyprland keybind: see [Window manager](./window-manager.md). The site
also rebuilds in real time as you edit — `mdbook serve` watches
`src/*.md` and reloads the browser on change.

## How to update this

When you add a new tool or capability, update the relevant page (or
add a new one + register it in `src/SUMMARY.md`). The auto-generated
[Keybinds](./keybinds.md) page rebuilds on `chezmoi apply` — you never
edit it by hand.
