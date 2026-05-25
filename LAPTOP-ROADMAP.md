# Laptop improvement roadmap

Living document. Tracks what's done, what's planned, and the reasoning
behind each item. Picked up by future pi sessions as part of the
chezmoi repo context.

## Done ✅

### Tmux modernization
- continuum auto-restore (15min interval) + systemd-user `tmux.service`
- sesh session picker bound to `prefix + T`
- Scratch popup on `Alt-g`
- `extended-keys always` + csi-u (kills pi warning)
- OSC 52 system clipboard
- undercurl + underline-color passthrough for nvim LSP
- allow-passthrough for kitty graphics
- monitor-activity highlighting

### Secrets / 1Password
- Removed `.zprofile` op-read loop (no more login-time IPC)
- `with-secrets <cmd>` wrapper + auto-aliases for `pi`, `claude`
- Lazy resolution: shells start instantly, secrets fetched on-demand
- Offline-tolerant when 1Password desktop app is unlocked

### Hypr drift codified
- env = PATH, XDG_* exported for exec bindings + portals
- hyprpolkitagent replacing polkit-gnome (with systemctl --user kick)
- xdg-desktop-portal-{hyprland,gtk} via package, replaces manual script
- hyprlock parallel PAM + fingerprint auth
- greetd-regreet + cage in bootstrap

### Power & battery
- `power-profiles-daemon` enabled + waybar module (cycles balanced/performance/power-saver)
- Framework EC charge limit: 80%
- systemd oneshot (`framework-charge-limit.service`) re-applies on every boot
- `fw-ectool-git` in bootstrap

### Rolling-release safety net
- snapper root config (timeline: hourly 10 / daily 7 / weekly 4 / monthly 6)
- snap-pac for auto pre/post snapshots wrapping pacman txns
- grub-btrfs + grub-btrfsd for boot-into-snapshot menu
- `linux-lts` + headers as fallback kernel
- reflector.timer for weekly mirrorlist refresh
- faillock unlock_time 600s → 60s
- Sudoers expanded: NOPASSWD for systemctl + fw-ectool; passwd_tries=1

### Chezmoi hygiene
- `.pi/agent/settings.json` removed from management (self-modifying state)
- Lesson saved: never chezmoi-manage app-written state files

---

## Planned 🟡

### Phase 4 — Backups (next big item)
Goal: offsite encrypted backup of `~/work/`, `~/personal/`, dotfiles
state not in git, browser profiles, ~/.ssh.

Steps:
1. Pick a remote. Candidates:
   - Hetzner Storage Box (~$3/mo for 1TB, EU, SSH+SFTP+borg)
   - Borgbase (purpose-built for borg, ~$2/mo for 250GB, US/EU)
   - rsync.net (~$3/mo for 800GB, US, "borg-friendly")
   - Backblaze B2 (~$5/mo for 1TB, S3-API, need rclone bridge)
2. Install borg + borgmatic
3. Initial encrypted repo init on remote
4. Define exclude list (node_modules, build artifacts, caches)
5. Initial backup — runs hours for ~223G; do overnight on AC
6. systemd timer for nightly incremental
7. **Restore drill** — actually pull a file back, verify
8. Codify in chezmoi (`run_onchange_after_borg-setup.sh.tmpl`)

Stake: only insurance against disk death / catastrophic corruption.
Snapshots don't cover this.

---

### Tier 2 — Real QoL upgrades (pick when interested)
- **atuin** — encrypted searchable shell history with sync (`Ctrl-R` fuzzy)
- **direnv** — per-directory `.envrc` auto-load (better than `with-secrets` for repo-scoped)
- **delta** — syntax-highlighted git diffs (~3 lines of gitconfig)
- **zoxide verify** — already implied by sesh; confirm `z` is wired
- **Hibernate** — needs swapfile ≥ RAM (~32GB on btrfs subvolume), one kernel param. Eliminates standby battery drain.
- **mise** — unified version manager for node/python/go/etc. (replaces nvm + uv with one tool). Maybe-worth-it.

---

### Tier 3 — Security / network hygiene
- **nftables + ufw** — firewall for travel (cafes, hotels). Default Arch has none.
- **1Password SSH agent** — move `~/.ssh/` keys into 1Password (touch-ID auth, no key files on disk).
- **Wireguard / Mullvad** — VPN for travel.
- **LUKS** — full disk encryption. Big project (re-encrypt root in place, half-day with risk). Real travel-theft risk gap.

---

### Tier 4 — Niche / exploratory
- **yazi** — TUI file manager with image previews
- **swww** — wallpaper rotation through `~/Pictures/wallpapers/`
- **gammastep / hyprsunset** — auto warm-tone after sunset
- **distrobox** — run Fedora/Ubuntu containers seamlessly
- **mission-center** — GTK4 system monitor

---

## How to use this doc

- Each `### Phase N` or `### Tier N` section is a discrete unit of work.
- "Pick when interested" items are not blockers; do in any order.
- After completing an item, move it to "Done" with a one-line summary.
- Reasoning behind each item is preserved so future-you (or pi) doesn't have to re-derive it.

## Decisions worth remembering

- **Don't switch to zellij.** Tmux setup is dialed in; sesh+continuum cover the use cases.
- **Skip mise for now.** nvm-lazy-load + uv already work; switch only if version-management pain emerges.
- **`/home` is not in snapper-root.** Use backups for /home, not snapshots (rolling back /home would nuke work).
- **No charge-limit auto-bump.** 80% is the Framework-recommended set-and-forget value.
