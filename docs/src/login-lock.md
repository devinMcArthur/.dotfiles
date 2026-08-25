# Login & lock

## The stack

| Stage | Component | Config |
|---|---|---|
| Boot menu | GRUB + Catppuccin Mocha theme | `/etc/default/grub` (`GRUB_THEME`) |
| Boot splash | Plymouth, `bgrt` theme (firmware logo + spinner) | `plymouth` hook in `/etc/mkinitcpio.conf`, `splash` kernel param |
| Greeter | greetd → cage (Wayland kiosk) → regreet (GTK4) | `/etc/greetd/config.toml`, `regreet.toml`, `regreet.css` |
| Session | regreet launches Hyprland | — |
| Lock | hyprlock (PAM + fingerprint in parallel) via hypridle | `~/.config/hypr/hyprlock.conf`, `hypridle.conf` |

Everything under `/etc/greetd` plus the Plymouth/GRUB wiring is managed by
`run_onchange_after_boot-theming.sh.tmpl` in the chezmoi repo. Every file it
touches gets a timestamped `.bak` sibling, and pre-change initramfs images are
kept as `/boot/*.img.bak`.

## Recovery runbook — "login is broken, get me to Hyprland"

Work down this list; each layer assumes the one above it failed.

### 1. The universal escape: TTY + manual Hyprland

**`Ctrl+Alt+F2`** (or F3…F6) always gives a text console — it works from the
greeter (cage runs with `-s` for exactly this), from a black screen, and from
a crashed session. Log in with username + **password** (the fingerprint
reader is not involved at a TTY). Then:

```
Hyprland
```

That's the whole trick: running `Hyprland` from a TTY bypasses greetd/regreet
entirely and gives you your full normal session. You can live like this
indefinitely while fixing the greeter at leisure.

### 2. Fix or bypass the greeter

From that TTY (or a terminal inside Hyprland):

```bash
ls /etc/greetd/                              # see available .bak files
sudo cp /etc/greetd/config.toml.bak.<newest> /etc/greetd/config.toml
sudo systemctl restart greetd
```

Fallbacks, in order of bluntness:

- **regreet looks broken but runs** (theme problem): edit
  `/etc/greetd/regreet.toml`, set `theme_name = "Adwaita-dark"`, restart greetd.
- **regreet/cage won't start at all**: swap to the text greeter —
  `sudo cp /etc/greetd/config.toml.bak.tuigreet /etc/greetd/config.toml`,
  restart greetd.
- **greetd itself is wedged**: `sudo systemctl disable greetd`, reboot, log in
  at the TTY, run `Hyprland` (layer 1). Re-enable once fixed.

### 3. Boot splash (Plymouth) hangs or black-screens the boot

At the GRUB menu, press **`e`** on the entry, find the `linux` line, delete
`splash` and append `plymouth.enable=0`, then **F10** to boot. Boot proceeds
with plain text. To make it permanent:

```bash
sudo sed -i 's/splash //' /etc/default/grub
sudo sed -i 's/ plymouth//' /etc/mkinitcpio.conf
sudo mkinitcpio -P && sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 4. Initramfs won't boot (kernel panic before login)

Pre-change images are kept next to the live ones. At GRUB press **`e`** and
change the `initrd` line's `/initramfs-linux.img` to
`/initramfs-linux.img.bak`, F10. Alternatively boot the **LTS kernel** entry
(separate kernel + separate initramfs = independent failure domain).

### 5. System-level breakage

- GRUB → **Arch Linux snapshots** submenu (grub-btrfs) boots a snapper
  snapshot of the root filesystem; `sudo snapper rollback` from inside makes
  it permanent. Caveat: `/boot` is FAT and **not** snapshotted — after a
  rollback the kernel on the ESP may be newer than the modules in the
  snapshot; the LTS entry usually bridges the gap.
- Last resort: Arch live USB → `mount -o subvol=@ /dev/nvme0n1p2 /mnt`,
  `mount /dev/nvme0n1p1 /mnt/boot`, `arch-chroot /mnt`, fix, reboot.

### Related

- Network-stack breakage has its own offline runbook: `sudo net-rollback`
  (or `--classic`) — see the header of `run_onchange_after_network-iwd.sh.tmpl`.
