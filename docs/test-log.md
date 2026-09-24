# Test log

## 2026-09-23 — Phase 1: VM and safety net

### Test VM

| Item | Result |
| --- | --- |
| Host tooling | libvirt 12.0.0 (system mode), QEMU 10.2.1, installed by Steven. Default storage pool created at `/var/lib/libvirt/images` |
| Guest | Ubuntu 26.04.1 LTS from `ubuntu-26.04.1-desktop-amd64.iso` (SHA256 verified), unattended autoinstall via `vm/create.sh` |
| Guest kernel | 7.0.0-34-generic (same as host) |
| Resources | 4 vCPU (host-passthrough), 6 GB RAM, 40 GB qcow2, BIOS boot (libvirt can't take internal snapshots of UEFI guests) |
| Graphics | virtio-vga-gl + `egl-headless` on the Intel iGPU (`renderD128`), shown over VNC on 127.0.0.1:5959 |
| 3D acceleration | Guest kernel: `[drm] features: +virgl`. Hyprland log: `Renderer: virgl (Mesa Intel(R) UHD Graphics (CML GT2))` — **PASS** |
| Screenshots | QEMU `screendump` fails on virgl scanouts ("no surface"); `vm/vncgrab.py` captures over VNC instead (GDM, consoles and sessions) |
| Snapshot | `clean-install` (shut off, fresh install + SSH key + passwordless sudo for the test user) |

### Hyprland 0.53.3 (Ubuntu package) in the VM

- Stock `hyprland.desktop` session starts from GDM and renders with virgl. **PASS**
- `hyprctl dispatch exit` makes Hyprland segfault during teardown (apport: signal 11). The upstream
  `start-hyprland` watchdog still reports "Hyprland exit cleanly" and GDM returns normally.
  → `lcars-session` launches through `start-hyprland` so a requested exit is not counted as a crash.

### Toolkit bake-off (same bar in both: elbow, workspaces 1–5, clock + stardate, PipeWire mute toggle)

| | Quickshell 0.3.1 (QML) | AGS 3.1 / Astal (TypeScript + GTK 4) |
| --- | --- | --- |
| Ubuntu 26.04 package | No — build from source (CMake, Qt 6.10 from Ubuntu) | No — build 4 Astal libs (Meson/Vala) + AGS (Go) + `npm install` |
| Build snags | Crash handler needs `cpptrace` (not packaged) → `-DCRASH_HANDLER=OFF` | Needs `valadoc`; AGS needs `npm install` before `meson install` (else `gnim` missing) |
| Build time in VM | ~4 min | < 1 min (plus npm download) |
| First run | Worked unchanged | Needed a fix: app is bundled to `/run/user/…`, so runtime-relative paths break (palette now imported at bundle time) |
| Runtime warnings | None (one harmless portal app-ID warning) | 2 `CRITICAL`s from AstalHyprland at start (`get_client: address != NULL`, JSON node invalid) against Hyprland 0.53 |
| Memory (RSS, bar only) | 146 MB | 207 MB (gjs) |
| Workspace/mute state updates | PASS | PASS |
| Mouse clicks (QMP tablet) | PASS — mute toggle, workspace 4 | PASS — mute toggle, workspace 4 |
| LCARS shapes | Per-corner radii native; `Shape`/`PathArc` available for true elbows and swept curves; property animations built in | GTK CSS per-corner radii only; true curved elbows need Cairo drawing areas; CSS transitions only |
| Visual result | Matches the design; tighter pills | Near-identical; GTK button padding widens pills, inner elbow curve flatter |

**Recommendation: Quickshell.** It ran first time, has no warnings against the current Hyprland,
uses less memory, and QML's shape and animation primitives fit LCARS elbows and sweeps far better
than GTK CSS. Its cost is a ~4 minute source build, which `install.sh` will need to handle in Phase 3.

### install.sh / lcars-rollback

Snapshots: `clean-install` → `pre-deploy` (+ Timeshift configured, rsync mode on `/dev/vda2`) → `installed`.

| Test | Result |
| --- | --- |
| `install.sh` on `pre-deploy` | **PASS** (exit 0, ~50 s). Timeshift snapshot, `~/.config` tarball, 50 new packages (Hyprland 0.53.3 + deps), 2 symlinks, 1 copied file, runtime dirs recorded, 1 system file (`/usr/share/wayland-sessions/lcars.desktop`) |
| Refuses outside a VM | By design: `systemd-detect-virt`; `--deploy` needed on real hardware (Phase 5) |
| Bugs found and fixed | `sudo -v` asks for a password even with NOPASSWD → `sudo true`; `comm` failed on locale sort order → `LC_ALL=C` |
| GDM gear menu | Shows **LCARS**, **Ubuntu**, and **Hyprland** (from Ubuntu's `hyprland` package, not crash-guarded) |
| LCARS start time | Hyprland answering IPC ~2 s after the password is submitted — **PASS** (< 10 s) |
| `lcars-rollback --purge` after using LCARS | **PASS**: package list, `/etc` (diffed against the Timeshift snapshot) and session files identical to before. Remaining: `~/lcars-backups/` (kept on purpose), default session `""` → `"ubuntu"` (equivalent), app data from using Ptyxis |
| Plain rollback, then `--purge` later | Fixed: package list now also kept in `~/lcars-backups/lcars-packages.txt` |
| Runtime leftovers | Fixed: `~/.local/share/hyprland` (and `~/.cache/hyprland`) recorded at install, removed by rollback |

### Escape routes

| # | Route | Result |
| --- | --- | --- |
| 1 | `Super+Shift+Esc` → login screen → gear → "Ubuntu" | **PASS**. Exit status 139 (Hyprland 0.53.3 segfaults in `libaquamarine` while shutting down); `lcars-session` recognises the exit marker, logs "exited on request", records no crash. GDM gear → Ubuntu → `gnome-shell --mode=ubuntu` |
| 2 | Crash on login → crash guard starts Ubuntu | **PASS** after a fix. 3× SIGSEGV → 3 crashes logged (exit 134) → `gnome-shell --mode=ubuntu` + `~/LCARS-NOTE.txt`. **First attempt failed:** upstream `start-hyprland` restarted the crash in safe mode, then reported the second crash as a clean exit. `lcars-session` now starts Hyprland directly |
| 3 | Frozen/black screen → `Ctrl+Alt+F3` → console → `lcars-rollback` | **PASS** after a fix. **A frozen compositor blocks `Ctrl+Alt+F3`** (Wayland compositors do the VT switch themselves; SIGSTOPped Hyprland → VT stayed on tty2). Added a hang watchdog: no IPC answer for 30 s → Hyprland killed (~44 s after the freeze) and counted as a crash. Then `Ctrl+Alt+F3` → tty3 login → `lcars-rollback`: 7 changes, 0 problems |
| 4 | `touch ~/.lcars-off` (over SSH) → next login goes to Ubuntu | **PASS**. LCARS chosen at GDM → Ubuntu session, Hyprland never started, note written |
| 5 | Restore pre-deploy Timeshift snapshot | **PASS with caveats.** `timeshift --restore --skip-grub --yes` (run over SSH while LCARS was logged in) removed all 50 packages and the session file and reset the default session. It did **not** reboot by itself and left the display dead ("Display output is not active"); `sudo reboot` needed. Timeshift excludes `/home`, so home leftovers remain until `lcars-rollback` is run (7 changes, 0 problems; tolerated the already-removed system parts). Live-USB variant **not rehearsed** |

### Open issues (decisions from Steven, 2026-09-24, in brackets)

1. **Crash popup after exiting LCARS.** Hyprland 0.53.3's segfault on exit leaves an apport report, so the next GNOME login shows "Ubuntu 26.04 has experienced an internal error". Harmless, but on every exit. [Silence apport for Hyprland per user; install/rollback pair]
2. **Freeze recovery takes ~45 s** (watchdog). A faster manual route needs Magic SysRq "unraw" (`Alt+SysRq+R`), which Ubuntu disables; enabling it means a documented `/etc/sysctl.d` file.
3. **Crash-guard note is only a file** (`~/LCARS-NOTE.txt`); nothing tells you on screen why you landed in Ubuntu. [One-time GNOME notification]
4. **`lcars-rollback` is on `PATH` only in login shells** (console, interactive SSH). In a one-off SSH command use `~/.local/bin/lcars-rollback`.
5. **Unguarded "Hyprland" entry in the GDM gear menu** comes from Ubuntu's package. [Hide with `dpkg-divert`; rollback restores]
6. VM test user: `steven` / `lcars`, passwordless sudo (VM only).

## 2026-09-24 — Phase 1 follow-up: Steven's four decisions

Retested from `pre-deploy` (install) and `installed` (routes, rollback).

| Change | Test | Result |
| --- | --- | --- |
| Hide stock Hyprland sessions (`dpkg-divert --local --rename`, `hyprland.desktop` and `hyprland-uwsm.desktop` → `*.lcars-hidden`) | GDM gear menu | **PASS**: only LCARS and Ubuntu listed |
| Apport ignore for `/usr/bin/Hyprland` in `~/.apport-ignore.xml` (mtime 4102444800 so it survives upgrades; merged into an existing file if present) | Route 1 exit (status 139), then Ubuntu login | **PASS**: no `/var/crash` file written, no crash dialog in GNOME |
| One-time fallback notification (self-deleting `~/.config/autostart` entry) | Route 2 (3 crashes) | **PASS** after a fix: GNOME 50 ignores `X-GNOME-Autostart-Delay` and ran the entry before its notification service existed; it now retries every 2 s for up to 60 s. Notification shown: "LCARS did not start — Hyprland crashed 3 times in the last 5 minutes…" |
| Freeze handling | — | Unchanged by decision: watchdog only, no `/etc` changes |
| `lcars-rollback --purge` after use | Fingerprint + `/etc` + `/var/lib/dpkg/diversions` vs pre-install | **PASS**: 13 changes, 0 problems; diversions removed before the purge, apport file removed (install created it), no autostart dir left. Remaining differences as before: `~/lcars-backups/`, default session `"ubuntu"`, `~/.local/share` kept because the login itself put files in it |

System-level changes made by `install.sh` are now: apt packages, `/usr/share/wayland-sessions/lcars.desktop`, and two local dpkg diversions. Nothing under `/etc`.

## 2026-09-24 — Phase 2: base session

### What was built

- `tokens/palette.json` extended with roles (border/group colors, inactive alpha, wallpaper dim) and shape sizes
- `tools/lcars-gen` (Python stdlib only) renders `*.in` templates and an original wallpaper PNG from the tokens → `hypr/generated/{colors.conf,hyprpaper.conf,wallpaper.png}`, `fuzzel/fuzzel.ini`, `mako/config` (all gitignored; `install.sh` runs it)
- Hyprland config split into `look`, `input`, `keybinds`, `rules`, `autostart`; no hard-coded colors
- LCARS frames: 4 px orange active / 45 % lavender inactive borders, 16 px rounding, no shadow/blur, quick animations; tabbed groups with LCARS-colored tabs in Antonio
- Antonio font shipped in `fonts/` (OFL 1.1) and linked into `~/.local/share/fonts/lcars`
- Stopgaps until Phase 3 (Steven's choice): fuzzel launcher, mako notifications, both from tokens
- Keybindings: see `docs/keybindings.md`

### Tests (VM, all from `pre-deploy`)

| Test | Result |
| --- | --- |
| `Hyprland --verify-config`, `hyprctl configerrors` | `config ok`, no errors |
| Install | **PASS** (79 packages recorded) after fixing: apt failed on the dpkg lock held by PackageKit just after boot → `DPkg::Lock::Timeout=300` in install and rollback |
| Frames, wallpaper, launcher, notification | **PASS** (screenshots). Wallpaper switched to `fit_mode = contain` so the whole design shows on 16:10 screens |
| Terminal, Files, Firefox (snap), polkit prompt (floats centered), tabbed group, volume keys, screenshot to `~/Pictures/Screenshots` + clipboard | **PASS**. Fixed: `xdg-user-dir` answers `$HOME` when Pictures isn't configured; `Super+B` now launches the default browser via `gtk-launch` |
| `hyprland-guiutils` notice at every login | Fixed: not packaged for Ubuntu → `misc:disable_hyprland_guiutils_check`, ANR dialog off |
| **Helpers leaking into the Ubuntu session** | **Found and fixed.** The `hyprpaper`, `hyprpolkitagent` and `mako` packages enable user services for *every* graphical login: they ran inside GNOME (a second polkit agent), hyprpaper ran twice in LCARS. `install.sh` now masks those three user services for the user (`systemctl --user mask`, undone by rollback); LCARS starts them itself |
| **Helper crash dialogs after exit** | **Found and fixed.** hyprpolkitagent, hyprpaper and xdg-desktop-portal-hyprland aborted when Hyprland exited → apport dialogs in GNOME. `hypr/scripts/exit` now stops them before exiting (no crashes at all on a normal exit, kernel log clean), and they're on the per-user apport ignore list for the crash path |
| LCARS → exit → Ubuntu | **PASS**: 0 Hyprland helpers in GNOME, no crash files, no dialog |
| Route 2 (3 crashes) | **PASS**: Ubuntu + notification, no helper crash dialogs |
| `lcars-rollback --purge` | **PASS**: 23 changes, 0 problems; `/etc` and dpkg diversions identical; same three intended leftovers as Phase 1 |

### Not testable in the VM (for the real-hardware test)

Brightness keys, touchpad gestures, lid/suspend, the dock and multiple monitors, NVIDIA/Intel switching.
