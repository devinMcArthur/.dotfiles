# Virtualization — Win11 KVM VM

A permanent Windows 11 Pro VM lives on this laptop, managed by libvirt
and accessed via a SPICE display. It exists so I can run Office-bound
Windows tooling (Teltonika Configurator first, then Office/Teams when
IT licenses them) without dual-booting or carrying a second machine.

## The stack

| Layer | What | Why |
|---|---|---|
| Hypervisor | QEMU/KVM | Native to Linux, hardware-accelerated via Intel VT-x |
| Management | libvirt + virt-manager | Standard, scriptable, GUI fallback when needed |
| Display | SPICE + virt-viewer | Clipboard sync, dynamic resize, USB redirection |
| Guest paravirt | virtio (storage, net, video, balloon) | Performance vs. emulated devices |
| Win11 prerequisites | OVMF (UEFI) + swtpm (TPM 2.0) | Both required by Win11 setup |
| Linux glue | A `win` launcher script + Hyprland binds | Hotkey access from anywhere |

All packages are in `run_onchange_before_install-packages.sh.tmpl` and
reproduce on a fresh laptop via `chezmoi apply`.

## File locations

| Path | What | Managed by |
|---|---|---|
| `~/vms/win11/win11.qcow2` | VM disk (80 GB virtual, sparse). Read-only baseline once snapshotted. | Manual — state, not chezmoi |
| `~/vms/win11/win11.clean-install` | Active overlay (external snapshot delta). All current writes go here. | Manual — state, not chezmoi |
| `~/Downloads/iso/Win11_25H2_*.iso` | Windows installer ISO | Manual (Microsoft download) |
| `/var/lib/libvirt/images/virtio-win.iso` | Paravirt drivers + guest-tools | AUR `virtio-win` |
| `/var/lib/libvirt/qemu/nvram/win11_VARS.fd` | UEFI variable store (per-VM) | libvirt |
| `/etc/libvirt/qemu.conf` | Sets qemu to run as `dev:dev` so it can access `~/vms/` | chezmoi (idempotent edit in bootstrap) |

## The `win` launcher

Lives at `~/.local/bin/win` (chezmoi-managed at
`dot_local/bin/executable_win`). Subcommands:

| Command | Behavior |
|---|---|
| `win` *(or `win attach`)* | Start the VM if it's stopped, then open `virt-viewer` fullscreen. Idempotent — focuses an existing viewer instead of spawning a second one. |
| `win stop` | Graceful ACPI shutdown (Windows sees a power-button press). |
| `win force` | Hard power-off (use only if `stop` hangs). |
| `win snap [NAME]` | Snapshot the VM. Defaults to a timestamped name. Disk-only external snapshot — works with the UEFI NVRAM layout. |
| `win restore NAME` | Revert to a named snapshot. Discards everything written since. |
| `win snaps` | List snapshots. |
| `win status` | Show domain state. |

`WIN_WINDOWED=1 win` skips fullscreen for one launch (rare — when you
want side-by-side with Linux work).

## Keybinds

| Chord | What it does | Bypasses virt-viewer's keyboard grab? |
|---|---|---|
| `Super+W` | Attach / focus virt-viewer | n/a (used from Linux side) |
| `Super+Shift+W` | Escape from the VM → workspace 1, viewer keeps running | ✅ (`bindp`) |
| `Super+Shift+Q` | Graceful VM shutdown via `win stop` | ✅ (`bindp`) |

When virt-viewer is fullscreen and focused, it uses the Wayland
`keyboard-shortcuts-inhibit-v1` protocol to grab **all** keys including
Super. Hyprland honors that by default, so normal binds (Super+1,
Super+Q, etc.) stop working while focused on the VM. The two `bindp`
binds above are the only ones that override the grab — they always
reach Hyprland.

To get out of the VM, hit `Super+Shift+W`. Normal binds work again
once virt-viewer loses focus.

## Snapshot model — external, NOT internal

UEFI VMs (pflash NVRAM) cannot use libvirt's *internal* snapshots
without a separate NVRAM format conversion. So we use **external
disk-only snapshots**:

- The original `win11.qcow2` becomes a **read-only baseline** that
  captures the snapshot point in time.
- A new **overlay file** (e.g. `win11.clean-install`) becomes the
  active disk. All future writes go to the overlay.
- Reverting means discarding the overlay and starting writes against
  a new overlay based on the baseline.

The `clean-install` snapshot is the "fresh OOBE done, virtio-win
guest tools installed, Chrome installed" rollback point. Always there
as a safety net.

To take a new snapshot at any future "clean enough" moment (e.g.
after Office is installed and licensed):

```bash
win stop                                  # bring VM to a clean state
win snap office-baseline "Office installed, IT licensed"
win                                       # boot the VM back up
```

Then if you ever wreck the VM trying something risky:

```bash
win stop
win restore office-baseline
win
```

## Common virsh recipes

`virsh -c qemu:///system` is implicit in your env once you're in the
`libvirt` group (which `chezmoi apply` puts you in).

```bash
# Inspect state of all VMs
virsh list --all

# Edit the VM XML (e.g. tweak vCPU count, add hardware)
virsh edit win11           # opens in $EDITOR; VM must be shut down to apply

# Hot-detach the network (useful for OOBE workarounds)
virsh detach-interface win11 network --live

# Attach a USB device by host vendor:product
virsh attach-device win11 /path/to/usb-redirect.xml --live

# See the firmware/NVRAM/disk layout
virsh dumpxml win11 | less
```

## Known degraded behavior

- **Cursor jitter inside the VM.** No GPU acceleration; cursor is
  CPU-rendered every frame. We removed `--reconnect` so the viewer
  cleans up properly on shutdown but the underlying rendering path is
  the same. Acceptable for a config tool.
- **Resolution doesn't auto-fit on first launch.** Manually picking
  1920×1080 in Windows Display Settings is the workaround. Dynamic
  resize *should* work via spice-vdagent but is finicky.
- **`Super` doesn't reach Windows by default.** virt-viewer's keyboard
  grab is automatic. Use `Super+Shift+W` to escape; otherwise Super
  goes to Windows naturally because of the grab.
- **PS/2 mouse still in the VM XML alongside USB tablet.** Cosmetic;
  removing it (requires reboot) may marginally improve cursor handling
  but hasn't been tried yet.

## IT licensing handoff

Currently the VM is **unactivated** Windows 11 Pro. When the office IT
team is ready:

1. They provide a Windows 11 Pro product key (or KMS/MAK info, or join
   the org's Azure AD).
2. Inside the VM: Settings → System → Activation → Change product key
   → enter their key. If they use volume licensing, follow their
   onboarding doc instead.
3. No reinstall needed. The same VM continues with proper licensing.
4. If they also want Office: install via their portal once Windows is
   activated (Office activation typically follows from the org sign-in).

## Future work

| Item | Why | Status |
|---|---|---|
| Install Teltonika Configurator + verify USB redirect | The original driver for setting this up | Blocked on having the GPS dongle in hand |
| USB hot-plug filter for the Teltonika dongle | Auto-redirect by USB vendor:product, no manual menu click | Trivial once we know the IDs |
| WinApps | Run individual Windows apps as native Hyprland windows (Teltonika in a Wayland window, no Windows desktop chrome) | Separate future session |
| spice-webdavd shared folder | Host↔guest file transfer | When the friction shows up |
| Migrate `hyprland.conf` to `hyprland.lua` | Hyprland 0.55+ deprecated hyprlang; v2-style window rules and combined class+title filters don't work in hyprlang anymore | Triggered if another hyprlang rule breaks |
| Remove the PS/2 mouse from the VM XML | Cosmetic — reduce input arbitration | Try if cursor jitter gets annoying |
