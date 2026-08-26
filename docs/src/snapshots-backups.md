# Snapshots & backups

Two independent layers:

1. **Snapshots (same disk):** Snapper takes filesystem snapshots;
   snap-pac auto-creates pre/post snapshots around every pacman
   transaction; grub-btrfs adds a "boot into snapshot" menu under
   GRUB. The LTS kernel is installed as a fallback boot option.
   Protects against *bad changes* — not disk loss.
2. **Offsite backup (off disk):** daily encrypted `restic` backup of
   `/home` to Cloudflare R2. Protects against *disk death, theft,
   fire*. See [Offsite backup](#offsite-backup--restic--cloudflare-r2)
   below.

## Snapper

`/` is a btrfs subvolume on this system. Snapper config name: `root`.

| Retention class | Count |
|---|---|
| Timeline (hourly) | 10 |
| Timeline (daily) | 7 |
| Timeline (weekly) | 4 |
| Timeline (monthly) | 6 |

Inspect:

```bash
sudo snapper -c root list                  # all snapshots
sudo snapper -c root list --type single    # single-snapshot ones
sudo snapper -c root diff <pre>..<post>    # what a pacman txn changed
```

**`/home` is deliberately NOT under snapper.** Rolling back home
would nuke active work. Home is covered by the offsite restic backup
instead. Codified decision.

## snap-pac — wraps pacman transactions

Every `pacman -S` (and `yay -S`) creates:

- A **pre** snapshot before downloading packages
- A **post** snapshot after the transaction commits

Description field of the snapshot includes the pacman command. Easy
to find "what did I install yesterday" via `snapper -c root list`.

Installed via the `snap-pac` package (pacman). Configured by default;
nothing to tune.

## grub-btrfs + grub-btrfsd — boot into a snapshot

After every snapper transaction, `grub-btrfsd` regenerates GRUB's
config to include each snapshot as a bootable submenu entry.

On boot, hold `Shift` (or whatever your platform needs) to get GRUB's
menu. Pick "Arch Linux snapshots → \<snapshot ID> \<timestamp> \<desc>".

The booted system is **read-only** by default. To make a rollback
permanent:

```bash
# inside the booted snapshot
sudo snapper rollback                      # marks current as new default
sudo reboot
```

Without `rollback`, the snapshot was a temporary diagnostic boot; the
next normal boot returns to mainline.

## LTS kernel — installed fallback

`linux-lts` + `linux-lts-headers` are in the bootstrap package list.
The boot menu always offers it as an alternative to `linux`.

When mainline kernel updates break something (driver regression,
suspend issue), reboot, pick LTS from the menu, and the system works.
LTS receives security updates separately from mainline — leave it
installed permanently.

## Offsite backup — restic → Cloudflare R2

Daily client-side-encrypted backup of `/home` to the R2 bucket
`turing-backup` (Standard storage class). First full backup:
2026-08-25, ~1.5h. Incrementals are minutes.

**Why this shape:** R2 because the Cloudflare account/billing already
exists (a service used *only* for backup gets forgotten); restic
because it encrypts client-side (Cloudflare never sees plaintext),
dedups/compresses, and speaks S3 natively.

### Pieces

| File | Role |
|---|---|
| `~/.local/bin/laptop-backup` | run / status / list / init / restore |
| `~/.config/op-backup.env` | `op://` secret refs (R2 keys, restic password, endpoint) — resolved per-run, never on disk in plaintext |
| `~/.config/restic/excludes.txt` | caches, node_modules, build dirs, VMs (~130G excluded of 251G) |
| `laptop-backup.timer` (user) | daily, `Persistent=true`, 20min jitter |
| `laptop-backup.service` (user) | oneshot, `Nice=10`, idle IO, 6h timeout |
| `~/.local/state/laptop-backup/` | log, last-success, last-check, last-skip |

Secrets live in 1Password (`Dev Secrets` → `cloudflare-turing-backup`).
They are deliberately in `op-backup.env`, **not** `op-dev.env` — the
R2 keys and restic password must never enter claude/pi agent
environments. If the vault is locked at run time, the backup **skips
cleanly** (touches `last-skip`, exits 0) and the next unlocked run
catches up (`Persistent=true`).

### Retention & integrity

After every backup: `restic forget --keep-daily 7 --keep-weekly 5
--keep-monthly 12 --prune`. Weekly (state-gated): `restic check` on
repo metadata.

### Commands

```bash
laptop-backup status          # last success/check; warns if >3 days stale
laptop-backup list            # snapshots
laptop-backup run             # manual backup now
laptop-backup restore <snapshot> <path> <dest>   # e.g. latest ~/foo /tmp/r
journalctl --user -u laptop-backup -n 20         # recent run output
```

`laptop-update` also prints backup age as one of its steps.

### Disaster recovery (new machine / dead disk)

1. Install restic; unlock 1Password (`Dev Secrets` vault).
2. `chezmoi apply` deploys `laptop-backup` + `op-backup.env` — or
   copy the two files by hand; nothing else is required.
3. `laptop-backup list` to confirm access, then
   `laptop-backup restore latest / /mnt/recover` (or a subpath).

Everything needed to decrypt lives in 1Password — losing the laptop
loses nothing. Losing the 1Password account **loses the backup**
(restic password is the only key; there is no recovery without it).

## reflector.timer — weekly mirrorlist refresh

`reflector.service` (timed weekly) regenerates `/etc/pacman.d/mirrorlist`
with the fastest mirrors. Reduces stale-mirror frustration during
`pacman -Syu`.

## faillock unlock — tuned down

Default `pam_faillock` on Arch is `unlock_time = 600` (10 minutes after
3 wrong sudo password attempts). We have it tuned to **60 seconds** so
typos don't lock you out for 10min while the laptop is open in front
of you. See [Secrets](./secrets.md) for the full faillock + sudoers
story.

## Sudoers expanded

`/etc/sudoers.d/pi-agent` (chezmoi-deployed in a planned phase):

- `Defaults passwd_tries=1` — typoed password = 1 strike, not 3
- NOPASSWD for `pacman`, `yay`, `chsh`, `hostnamectl`, `systemctl`,
  `fw-ectool` — frequently-used and confirm-only via sudo-gate

## Lessons learned

- **Don't chezmoi-manage app-written state.** `.pi/agent/settings.json`
  and similar self-modifying files are listed in `.chezmoiignore`.
  Same rule applies to btrfs subvolume mountpoints, snapshot indexes,
  etc. — those are filesystem state, not config.
- **Snapshots are not durability.** Disk dies = snapshots die with
  it. The restic → R2 backup is the real-durability story.
- **Backup secrets get their own env file.** `op-backup.env` is
  separate from `op-dev.env` so R2/restic credentials never leak
  into agent (claude/pi) environments via `with-secrets`.

## Recovery cheat sheet

| Symptom | Fix |
|---|---|
| Boot loops after `pacman -Syu` | GRUB → LTS kernel; if LTS boots, downgrade the offending package or wait for upstream fix |
| Package broke userland but boots | `snapper -c root list`, find pre-snapshot of offending txn, `snapper rollback <id>` |
| Both kernels fail | GRUB → boot into snapshot, then `snapper rollback` from within |
| Sudo locked out | Wait 60s, OR `faillock --reset` from a recovery shell |
| Deleted/corrupted a file in `~` | `laptop-backup restore latest ~/path /tmp/recover` (unlock 1Password first) |
| Disk dead / laptop gone | New machine → unlock 1Password → `laptop-backup restore` (see Disaster recovery above) |

## See also

- [Power & battery](./power.md) — also touches reliability
- [Secrets](./secrets.md) — the 1Password / `with-secrets` machinery

## Editing this page

Source: [`docs/src/snapshots-backups.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/snapshots-backups.md)
