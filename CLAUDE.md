# LCARS Desktop — rules for Claude Code

An LCARS-styled (Star Trek TNG) Hyprland desktop session for Steven's Ubuntu laptop.
Full plan, decisions and roadmap: `docs/plan.md`. Read it at the start of every session.

## Hard safety rules

1. Never run `install.sh`, change desktop settings, or install LCARS packages on the host machine. All testing happens in the test VM over SSH, until Steven explicitly starts Phase 5 (deploy).
2. Take a VM snapshot before every install test. Restore it after any failed test.
3. Never modify GDM, GNOME, or files under `/etc` beyond what `install.sh` documents. The stock "Ubuntu" session must always keep working.
4. Every change `install.sh` makes must be undone by `bin/lcars-rollback`. Add both together, in the same commit.
5. Nothing auto-starts at boot. LCARS runs only when chosen at the login screen, through `bin/lcars-session` (the crash-guard wrapper).
6. Ask Steven before anything needing `sudo` on the host (e.g. installing qemu/libvirt).

## Working rules

- Colors and fonts come only from `tokens/palette.json`.
- Verify visual changes with a VM screenshot (`grim` over SSH) before calling them done.
- Stop at each phase checkpoint in `docs/plan.md` and summarize for Steven. Log results in `docs/test-log.md`.
- Use only original artwork and sounds — no official Star Trek logos, audio or assets.
- Commit small, with clear messages.

## Decisions (confirmed 2026-09-23)

- Window behavior: full tiling on every workspace
- Input: keyboard-first (all LCARS buttons still clickable)
- Sounds: on by default, mute toggle in the bar
- Shell toolkit: Quickshell — chosen after the Phase 1 bake-off against AGS/Astal (see `docs/test-log.md`)

## Host machine

- Ubuntu 26.04.1 LTS, ext4, 14 GB RAM, KVM available
- Laptop with hybrid graphics: Intel UHD (CometLake-H, i915) + NVIDIA GTX 1660 Ti Mobile, proprietary driver 595.91.07
- Usually docked via ThinkPad USB-C Dock Gen 2 with two external 1920x1080 monitors
- Display wiring: laptop panel eDP-1 -> Intel (card1); dock monitors DP-2 and DP-3 -> NVIDIA (card2)
- `lcars-session` should detect the dock and render on NVIDIA when docked, Intel when undocked
- The VM cannot test the dock or real GPUs — a hands-on real-hardware dock test is required before deploy (see stability criteria)
- Test VM budget: 4 cores, 6 GB RAM, 40 GB disk
- A Timeshift snapshot ("Before LCARS project") and an Ubuntu live USB exist as last-resort recovery
