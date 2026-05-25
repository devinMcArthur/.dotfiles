# Snapshots & rollback

Rolling-release safety net for an Arch system. Snapper takes
filesystem snapshots; snap-pac auto-creates pre/post snapshots
around every pacman transaction; grub-btrfs adds a "boot into
snapshot" menu under GRUB. The LTS kernel is installed as a
fallback boot option.

**This is NOT a backup strategy.** Snapshots only protect against
filesystem corruption on the same disk. For off-disk durability, see
`LAPTOP-ROADMAP.md` → Phase 4 (Backups), which is queued but not yet
implemented (borg/borgmatic to a remote).

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
would nuke active work. Home goes in the (future) borg backup
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
  it. The Phase 4 borg work is the real-durability story.

## Recovery cheat sheet

| Symptom | Fix |
|---|---|
| Boot loops after `pacman -Syu` | GRUB → LTS kernel; if LTS boots, downgrade the offending package or wait for upstream fix |
| Package broke userland but boots | `snapper -c root list`, find pre-snapshot of offending txn, `snapper rollback <id>` |
| Both kernels fail | GRUB → boot into snapshot, then `snapper rollback` from within |
| Sudo locked out | Wait 60s, OR `faillock --reset` from a recovery shell |

## See also

- [Power & battery](./power.md) — also touches reliability
- `LAPTOP-ROADMAP.md` → Phase 4 — backups (queued)

## Editing this page

Source: [`docs/src/snapshots-backups.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/snapshots-backups.md)
