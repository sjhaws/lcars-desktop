# To do

Open items and ideas, newest requests first. Phase work follows `docs/plan.md`.

## Requested by Steven

- [x] **Fullscreen / compact mode.** `Super+F11`, the COMPACT pill, or a click on the line;
  remembered across logins. (Requested and built 2026-09-24.)
- [ ] **Verify unlocking in the VM** with the LOCK pill, a click into the VM and one tap of Super
  before typing. If keys still don't arrive, give the VM viewer the whole keyboard.
- [ ] Optional **UBUNTU** button in the sidebar: log out with the Ubuntu session preselected.

## Phase 4 (polish)

- [x] Lock screen (hyprlock) and idle (hypridle)
- [x] Interface sounds, on by default, with their own mute toggle (SFX pill)
- [x] App look, LCARS session only: libadwaita apps dark with orange accent (session env vars)
- [ ] Deeper LCARS app styling (true black, palette colors, Antonio headings) — needs a
  per-session stylesheet that GNOME never sees; libadwaita accents are limited to a fixed set
- [x] Multi-monitor: frame on every screen, per-screen workspaces, hot-plug, screen keys
- [ ] Arrange the real screens (eDP-1 laptop, DP-2/DP-3 dock) with `monitor =` rules during
  the real-hardware test; `auto` placement moves screens around when one is unplugged

## Small polish

- [ ] Hear the sounds in the VM: its sound card isn't routed to the host (the system libvirt QEMU
  can't reach the desktop's PipeWire); playback was verified via PipeWire streams instead

- [ ] Wi-Fi network name (SSID) in the NET readout
- [ ] Bigger font in the "frame failed to start" notice (Hyprland seems to ignore `fontsize:`)
- [ ] Rounded pill buttons in the header for common actions (from the reference image)

## Before deploying (stability criteria, `docs/plan.md`)

- [ ] 3 days of continuous use in the VM with no crashes
- [ ] Hands-on session by Steven in the VM
- [ ] Real-hardware test on the laptop: docked (3 screens), undocked, plugging and unplugging
  the dock, Intel/NVIDIA switching, **suspend/resume** (can't be tested in the VM: virtio-gpu
  stalls after S3), NVIDIA suspend services enabled
