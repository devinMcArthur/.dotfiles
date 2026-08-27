# Power

## Lid close — suspend-then-hibernate

Closing the lid (undocked) suspends instantly (s2idle, the only mode this
Framework offers). After **60 minutes** asleep, systemd wakes the machine
briefly, writes RAM to `/swap/swapfile`, and powers off — zero drain from
then on. Opening the lid resumes the whole session: every process,
terminal, and Claude Code conversation exactly where it was (live TCP
connections like SSH will have died; tmux on the remote end is the cure).

**Docked (external monitors attached), lid close does nothing** — the
laptop keeps running (`HandleLidSwitchDocked=ignore`).

Set up by `run_onchange_after_hibernate-setup.sh.tmpl`:

| Piece | Detail |
|---|---|
| `@swap` subvolume | top-level (rollback-proof: snapper swaps `@`, never touches siblings), mounted `/swap` |
| `/swap/swapfile` | 32G, `btrfs fs mkswapfile`, `pri=0` (4G zram at pri=100 stays first for paging) |
| kernel cmdline | `resume=UUID=<root> resume_offset=<n>` (offset from `btrfs inspect-internal map-swapfile`) |
| initramfs | `resume` hook after `block` (udev-based HOOKS) |
| policy | `logind.conf.d/50-lid-hibernate.conf` + `sleep.conf.d/50-suspend-then-hibernate.conf` |

Test: `systemctl hibernate` with a terminal open — machine powers off,
comes back with the terminal still there.

Backups and snapshots never see the swapfile: restic only reads `/home`,
and btrfs snapshots don't descend into other subvolumes.

## Security note

The hibernation image is all of RAM written to unencrypted disk —
including whatever secrets were in memory (e.g. unlocked 1Password
session material). Same exposure class as the unencrypted disk generally;
revisit if LUKS ever lands.

## The touchpad comes back silent

Hibernate restores RAM perfectly, but the i2c-HID touchpad controller
does not resume: the device node, both drivers and the libinput entry
all survive — and it emits **nothing** (measured: zero bytes from
`/dev/input/eventN` over 45 seconds). Nothing in the kernel log
complains, which is what makes it confusing.

`50-touchpad-rebind` (installed under `/usr/lib/systemd/system-sleep/`
by the hibernate setup script) unbinds and rebinds the controller on
every resume from hibernate. It finds the device by looking for an
input named "Touchpad" rather than hardcoding this laptop's
`PIXA3854`, and never touches the keyboard controller.

To do it by hand if the hook is ever missing:

```bash
echo -n i2c-PIXA3854:00 | sudo tee /sys/bus/i2c/drivers/i2c_hid_acpi/unbind
echo -n i2c-PIXA3854:00 | sudo tee /sys/bus/i2c/drivers/i2c_hid_acpi/bind
```

The keyboard keeps working throughout — it is a separate controller —
so this is always recoverable without a mouse.

## Lessons learned

- **Never restart systemd-logind under a live session.** v1 of the setup
  script ended with `systemctl restart systemd-logind`; the restart
  rebuilt seat0, revoked Hyprland's input/DRM leases, and froze the
  desktop solid — indistinguishable from a crash from the chair
  (2026-08-26; power button was a *clean* logind poweroff, journal
  confirmed). logind drop-ins apply at next boot; that's the way.
- s2idle drain is ~1–2%/h — that's what the hibernate hand-off exists for.

## Recovery cheat sheet

| Symptom | Fix |
|---|---|
| Boot hangs at resume | GRUB entry → `e` → delete `resume=` + `resume_offset=` → F10; boots fresh, image ignored |
| Trackpad dead after resume | the rebind hook should handle it; by hand, see above. Keyboard still works |
| Hibernate refuses ("no swap") | `swapon --show` must list `/swap/swapfile`; `swapon /swap/swapfile` or check fstab |
| Undo everything | script header documents the full teardown |

## Idle / screensaver / lock (hypridle)

Battery: dim @2.5min, screensaver @4min, lock @5min. AC: dim @10min,
screensaver @15min. Lock before every sleep; DPMS restored on wake. See
`dot_config/hypr/hypridle.conf`.

## Editing this page

Source: [`docs/src/power.md`](https://github.com/devinMcArthur/.dotfiles/blob/master/docs/src/power.md)
