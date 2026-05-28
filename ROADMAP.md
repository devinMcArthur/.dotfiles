# Laptop roadmap

State-of-the-work for the chezmoi-managed Framework 13 Arch+Hyprland
laptop. AGENTS.md captures cross-cutting lessons; this file captures
project-specific phase status. Update inline as items complete (move
to the **Done** section with a one-line outcome).

---

## Active

### Win11 KVM VM track

Phase 1–7 + 10 complete (see Done). Open items:

**Phase 8 — Teltonika Configurator install + USB redirect verification**
*Blocked: needs the GPS dongle in hand.*

When unblocked:
1. Acquire USB-A → Micro-USB-B data cable (recommended:
   [AmazonBasics B0711PVX6Z](https://www.amazon.ca/AmazonBasics-Male-Micro-Cable-Black/dp/B0711PVX6Z),
   3 ft, real data cable, ~$8).
2. Plug tracker into laptop; `lsusb | grep -i teltonika` to capture
   the USB vendor:product ID (we'll need that for Phase 9).
3. `Super+W` to attach the VM.
4. virt-viewer top-edge toolbar → Virtual Machine → Redirect USB
   device → tick the Teltonika entry → OK.
5. Inside Windows: install Teltonika's USB driver (`Driver.exe` from
   their site) → tracker appears as a virtual COM port.
6. Download + install **Teltonika Configurator** (from the Teltonika
   Telematics website, version matches the tracker firmware).
7. Connect, verify config read works end-to-end.
8. Take a new snapshot: `win snap teltonika-ready "Configurator installed, USB redirect verified"`.

**Phase 9 — USB hot-plug filter for the Teltonika dongle**
*Depends on Phase 8 (need the vendor:product IDs).*

Add a libvirt redirect filter that auto-attaches the tracker to the VM
whenever plugged in (no manual "Redirect USB device" click). Pattern:

```xml
<redirfilter>
  <usbdev class='0xff' vendor='0x...' product='0x...' allow='yes'/>
  <usbdev allow='no'/>
</redirfilter>
```

Added to the win11 VM XML, then redirfilters take effect on next boot
of the viewer.

### Deferred (no current trigger)

**Phase 11 — Migrate `hyprland.conf` to `hyprland.lua`**
*Trigger: another hyprlang feature breaks, or a Lua-only feature is wanted.*

Hyprland 0.55 deprecated hyprlang in favor of Lua. Already hit twice
in the VM track:
- `windowrulev2` removed entirely
- Bare value-less actions (`float`, `tile`, `fullscreen`) don't parse
  in the unified `windowrule`
- v2-style class regex (`class:^(...)$`) only works in Lua

Migration scope:
1. Translate `dot_config/hypr/hyprland.conf` → `dot_config/hypr/hyprland.lua`.
   Mostly mechanical: `bind =` → `hl.bind(...)`, `windowrule =` →
   `hl.window_rule({...})`, etc.
2. Rewrite `dot_config/hypr/regen-keybinds.sh` to source binds from
   `hyprctl binds -j` (live introspection) instead of grep/sed'ing
   the config file. Side benefit: cheatsheet stays accurate even
   for hyprctl-keyword-injected binds.
3. Take the chance to refactor the 9 repetitive workspace-bind pairs
   into a single helper function.
4. Add per-host conditional (`if hl.system.hostname == "turing" ...`)
   for things currently templated by chezmoi but better expressed
   inline.

Estimated 2–4 focused hours. Out-of-scope for the VM track sessions.

**Phase 12 — WinApps**
*Trigger: actually want Teltonika Configurator as a native window.*

Run individual Windows apps as native Hyprland windows (no surrounding
Windows desktop chrome) via FreeRDP. Win11 VM stays as the host;
WinApps just paints individual app windows over RDP. The current full
SPICE viewer experience continues working alongside.

### Quality-of-life (do when friction shows up)

- **Remove PS/2 mouse from VM XML** — currently coexists with USB
  tablet; may marginally reduce cursor jitter. Requires one VM
  reboot. Do if cursor frustrates you again.
- **spice-webdavd shared folder** — host↔guest file transfer. Install
  `phodav` on host, enable SPICE WebDAV channel in VM XML, mount
  inside Windows. Trivial when a file actually needs to move.
- **Dynamic-resize fix** — spice-vdagent is running but resolution
  doesn't auto-fit on first launch. Likely needs guest registry tweak
  or different driver. Currently working around by manually picking
  1920×1080 in Windows Display Settings.
- **Increase video VRAM** — current virtio video has default
  allocation (likely 16-64 MB). Bumping to 256 MB may unlock higher
  resolutions cleanly.

---

## Done

### Win11 KVM VM track

- ✅ **Phase 1 — Pre-flight checks.** VT-x, KVM modules, /dev/kvm,
  disk, RAM all verified clean.
- ✅ **Phase 2 — KVM/libvirt base install** (`1acce83`). qemu-full,
  libvirt, virt-manager, virt-viewer, edk2-ovmf, swtpm, virtiofsd,
  virtio-win all in chezmoi bootstrap. libvirtd enabled + active.
  Default NAT network autostart. `dev` user in `libvirt`+`kvm`
  groups.
- ✅ **Phase 3 — Win11 ISO acquired.** `Win11_25H2_English_x64_v2.iso`
  parked at `~/Downloads/iso/`. Manual download (Microsoft's page is
  JS-gated; not chezmoi-managed).
- ✅ **Phase 4 — VM definition via virt-install** (`e07cd2f`).
  4 vCPU, 6 GB RAM, 80 GB qcow2 at `~/vms/win11/`, q35 + UEFI + swtpm
  TPM 2.0, virtio disk/net/video, SPICE display, 2× USB redirect.
  qemu runs as `dev:dev` (chezmoi-managed edit to qemu.conf).
- ✅ **Phase 5 — Windows install.** Loaded virtio storage driver from
  virtio-win CD during "Where do you want to install"; bypassed MS
  account requirement via `ms-cxh:localonly` (post-BYPASSNRO trick);
  landed at desktop with local account.
- ✅ **Phase 6 — Guest tools.** `virtio-win-guest-tools.exe` installed
  all paravirt drivers + spice-vdagent in one shot. Network, clipboard
  sync, cursor sync working.
- ✅ **Phase 7 — Usability layer** (commits `074a237` → `998604a`):
  - `~/.local/bin/win` smart launcher (start/attach/stop/force/snap/restore/snaps/status)
  - `Super+W` → attach virt-viewer fullscreen on workspace 5
  - Idempotent: focus existing viewer instead of spawning a 2nd
  - `Super+Shift+W` (bindp) → escape to workspace 1 (bypasses virt-viewer's keyboard grab)
  - `Super+Shift+Q` (bindp) → graceful VM shutdown via `win stop`
  - Drop `--reconnect` so viewer auto-closes on shutdown
  - `clean-install` external snapshot taken (post-OOBE, post-Chrome)
- ✅ **Phase 10 — Documentation** (`2695f26`). `docs/src/virtualization.md`
  added to the mdBook reference site under a new Virtualization section.
  Covers stack, file locations, `win` script, keybinds, snapshot model,
  virsh recipes, known-degraded behavior, IT licensing handoff,
  future work.

### Other completed major work (recent sessions)

- **SSH agent**: dropped oh-my-zsh `ssh-agent` plugin, route through
  1Password's SSH agent. Single stable socket at
  `~/.1password/agent.sock`; survives reboots; key passphrase in the
  vault. Fixed the post-reboot "every-pane-asks-for-passphrase" storm.
  (`969eadf`)
- **Laptop docs site (mdBook)**: categorized one-page-per-subsystem
  reference at `docs/src/`, served as HTML via mdBook, accessible
  via `Super+?` keybind running `laptop-docs` launcher.

---

## How to use this file

- Update inline as items complete (move bullet under **Done** with the
  commit SHA + one-line outcome).
- New work that spans multiple sessions: add a phase to **Active**
  with subtasks.
- "Maybe someday" items: keep in **Deferred** so they survive across
  sessions without cluttering the active list.
- When something breaks unexpectedly that triggers a deferred phase,
  promote it to Active.
