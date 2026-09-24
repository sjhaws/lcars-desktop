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
6. VM test user: `captain` ("Captain" at the login screen) / `lcars`, passwordless sudo (VM only). Was `steven` until 2026-09-24.

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

## 2026-09-24 — Phase 3 (part 1): LCARS frame with a working menu

Steven's direction after trying Phase 2: the elbow is a **functional menu**. Decisions: always
visible (screen space reserved), classic left sidebar + top bar, segments Terminal, Browser,
Files, Editor, Monitor (`resources`), Settings, 2 custom buttons, Apps, Exit.

### What was built

- `shell/` (Quickshell 0.3.1): `Sidebar.qml` (elbow, menu segments, filler, footer),
  `TopBar.qml` (arm with concave inner corner, workspaces 1–5, stardate, clock, mute),
  `Theme.qml` (reads `tokens/palette.json`, which gains `frame` sizes), `Menu.qml`
- Menu from `shell/menu.json`, overridden by `~/.config/lcars/menu.json`; an unset custom button
  opens that file (created from the defaults) in Text Editor; `Super+F1/F2` call the custom
  buttons through Quickshell IPC
- The wallpaper elbow and hyprpaper are gone (the frame is real now); background is black
- `install.sh` builds Quickshell from the pinned v0.3.1 tag into `~/.local` and records every
  new file; `~/.config/lcars` is recorded as user data (rollback moves it to `~/lcars-backups`)

### Problems found and fixed

| Problem | Fix |
| --- | --- |
| Build: no C++ compiler, then no `egl` pkg-config module | Added `g++`, `libegl-dev` (checked every `pkg_check_modules` in the source) |
| Build: "Disk quota exceeded": `/tmp` is a 2.7 GB tmpfs with per-user quota on 26.04 | Build in `~/.cache/lcars-build` (removed afterwards, `rundir` for rollback), `Release` instead of `RelWithDebInfo`; build output to a log, tail shown on failure |
| New `-dev` packages pulled Ubuntu security updates (PipeWire, libexpat) the VM lacked; rollback doesn't downgrade them | Correct behaviour. `pre-deploy` snapshot refreshed with all updates (like a maintained host); `install.sh` now prints any upgrades of installed packages |
| CMake's `install_manifest.txt` misses the `qs` link and the icon | Record new files by diffing `~/.local` before/after |
| `IpcHandler is not a type` → no frame at all | Missing `import Quickshell.Io` |
| Top bar offset twice by the sidebar width | Hyprland already places it after the sidebar's exclusive zone; margin removed |
| Custom-menu edits not picked up | The file may not exist at start, and editors save by replacing it; `Menu.qml` now polls it every 2 s and only rebuilds when the content changes |
| Unprivileged `/tmp` file from an earlier run blocked a root-owned log (fs.protected_regular) | Test tooling only |

### Tests (VM, fully updated `pre-deploy`)

| Test | Result |
| --- | --- |
| Install incl. Quickshell build | **PASS**, no upgrades of installed packages needed |
| Frame at login (screenshot) | **PASS**: elbow + concave corner, segments with shortcut hints, footer, top bar readouts |
| Clicks: Terminal, workspace 2, CUSTOM 1 (opens menu file), EXIT (back to GDM) | **PASS** |
| Edit menu file → sidebar relabels (CALCULATOR, red TOP) within 2 s; `Super+F1` opens Calculator | **PASS** |
| Exit → Ubuntu: no quickshell/helpers left, no crash files or dialogs (only Hyprland's known, ignored exit segfault in the kernel log) | **PASS** |
| `lcars-rollback --purge` (with a custom menu present) | **PASS**: 31 changes, 0 problems; menu moved to `~/lcars-backups/lcars-<time>`; same three intended leftovers |

### Open

- If the shell's QML fails to load, LCARS has no frame (keyboard shortcuts still work). Phase 3
  should make lcars-session or Hyprland notice and show a message.
- `prototypes/ags` is obsolete; kept for the record of the bake-off.

## 2026-09-24 — VM rebuilt with user "Captain"

At Steven's request the VM user is now `captain` (display name "Captain"; password still
`lcars`). The old VM and its snapshots were deleted and the VM rebuilt from the ISO with
`vm/create.sh`, then `vm/prepare.sh` (new: Timeshift install + configuration, all Ubuntu
updates, `pre-deploy` snapshot), so the whole VM can now be rebuilt with two commands.

## 2026-09-24 — Phase 3 (part 2): launcher, notifications, readouts, shell safety net

### What was built

- `shell/Launcher.qml`: LCARS launcher (elbow header "APPLICATIONS", search line, apps as LCARS
  blocks with the match count in the elbow). Super+Space and the APPS segment toggle it through
  Quickshell IPC; type to filter (name first, then generic name, comment, keywords), ↑/↓, Enter, Esc
- `shell/Notifications.qml`: the shell is now the notification server. LCARS cards top right;
  urgency sets the cap color; 8 s default timeout, critical stays until clicked; click runs the
  default action and dismisses
- `shell/SystemStats.qml` + top bar: CPU and memory (from `/proc`, every 2 s), network (NetworkManager
  via `nmcli`, every 5 s), battery (UPower; hidden without a battery), volume (scroll to change,
  click to mute). Workspace buttons grow past 5 when higher workspaces are in use
- `hypr/scripts/shell`: starts the shell, restarts it after a crash, and after 3 failures in a
  minute shows Hyprland's own on-screen error (works with no shell running); stops when the
  session ends
- Removed the fuzzel and mako stopgaps (packages, configs, templates); added `upower`
- The menu footer (Apps, Exit) always comes from the defaults, so user copies of `menu.json`
  can't point at a removed launcher

### Problems found and fixed

| Problem | Fix |
| --- | --- |
| `vm/sync.sh` copied the host's generated `colors.conf` (repo path `/home/steven/…`) into the VM (user `captain`) → shell couldn't start | Sync excludes `hypr/generated/` and regenerates in the VM. (Test tooling only; a real install generates in place.) Useful side effect: it exercised the failure notice |
| VNC screenshots fail while virt-manager holds the display | `vm/screenshot.sh` falls back to `grim` inside the Hyprland session |
| Launcher showed "CLOCKS / CLOCKS" | Hint hidden when the generic name equals the name |
| Background job interrupted by a usage limit before its snapshot step | Re-ran the shutdown + `installed` snapshot by hand; install itself had finished (exit 0) |

### Tests (VM, fresh install from `pre-deploy`)

| Test | Result |
| --- | --- |
| Install | **PASS**: 225 packages recorded, fuzzel/mako not installed |
| Frame + readouts (CPU, MEM, NET WIRED, stardate, clock, VOL; no battery in the VM) | **PASS** (screenshot) |
| Launcher: Super+Space opens, "calc" filters to Calculator, Enter launches, Esc closes | **PASS** |
| Notifications: normal / low / critical styles, click dismisses critical, others expire at 8 s | **PASS** |
| Volume: 4 scroll steps 100 % → 80 %, click mutes | **PASS** |
| Shell crash (SIGSEGV) → restarted in 1 s | **PASS** |
| Shell failing to load → Hyprland red notice after 3 tries | **PASS** (seen during the sync bug) |
| EXIT → GDM; no quickshell or shell script left; Ubuntu: no helpers, no crash files or dialogs | **PASS** |
| `lcars-rollback --purge` | **PASS**: 28 changes, 0 problems; `/etc` and dpkg diversions identical; same three intended leftovers |

### Still open in Phase 3

Checkpoint "Looks and feels like LCARS" is Steven's call. Candidates for polish: bigger font in
the failure notice (Hyprland's `fontsize:` seems ignored), network name (SSID) in the NET readout.

### 2026-09-24 — Edit menu

The sidebar's filler block is now an **EDIT MENU** button; right-clicking any sidebar button and
`Super+F3` do the same (open `~/.config/lcars/menu.json`, created from the defaults if missing).
VM test: all three open Text Editor on the file; right-click on TERMINAL opens the file, not a
terminal. `vm/click.sh` gained a button argument for right/middle clicks.

## 2026-09-24 — Phase 4 (part 1): lock screen and idle

### What was built

- `hypr/hyprlock.conf.in` → generated LCARS lock screen: elbow (one rounded outer corner, concave
  inner corner) and labelled sidebar blocks (SECURITY, ACCESS, user, LOCKED), "LCARS ACCESS
  TERMINAL" on the arm, large clock, stardate (`hypr/scripts/stardate`), "ENTER ACCESS CODE"
  field that turns red with "ACCESS DENIED"
- `hypr/hypridle.conf`: dim 5 min, lock 10 min, screen off 11 min, suspend 30 min on battery only
  (`hypr/scripts/idle-suspend`), lock before every sleep
- `Super+L` and a LOCK block in the top bar; `misc:allow_session_lock_restore` so a crashed
  hyprlock can be replaced
- `install.sh`: `hyprlock`, `hypridle`; masks the packaged `hypridle.service` (enabled for every
  graphical session, it would lock GNOME with hyprlock); hypridle added to the apport ignore list

### Problems found and fixed

| Problem | Fix |
| --- | --- |
| Placeholder text cut at `<span foreground="` | `#` starts a hyprlang comment → `##` |
| Most blocks and labels missing | hyprlang needs a newline after `shape {` / `label {` |
| Concave corner square, labels hidden under blocks | hyprlock doesn't keep file order → explicit `zindex` on every widget |
| Lowercase user name on the lock screen | `cmd[update:0] echo "$USER" \| tr a-z A-Z` |

### Tests (VM)

| Test | Result |
| --- | --- |
| LOCK click / `Super+L` / `loginctl lock-session` from the session → locked | **PASS** |
| Wrong code → "ACCESS DENIED" in red; right code unlocks | **PASS** |
| Idle (test timings 5/10/15 s): locked at ~11 s, screen off at 15 s, back on at unlock | **PASS** |
| Suspend → locked before sleep (hyprlock running on wake) | **PASS** |
| Display after resume | **Not testable in the VM.** virtio-gpu/virgl stalls on a fence after S3 (`drm_atomic_helper_wait_for_fences`, Hyprland "Cannot commit when a page-flip is awaiting"): the screen stops updating while Hyprland and hyprlock keep running. Must be checked on the real laptop (Intel/NVIDIA); NVIDIA needs `nvidia-suspend`/`nvidia-resume` enabled to preserve video memory |

Note: `loginctl lock-session` from an SSH shell locks the SSH session, not the desktop; tests
now trigger it inside the graphical session.

### Found in the full install test: helpers in other users' sessions

`hypridle` crash reports appeared for the GDM login screen's users (60578/60579): the `hypridle`
and `hyprpolkitagent` packages enable their user services globally
(`/etc/systemd/user/graphical-session.target.wants/`), so they start in *every* user's graphical
session: the login screen and any other account, not just Steven's (whose per-user masks worked).
Steven chose to disable them globally: `install.sh` runs `systemctl --global disable` (recorded
as `globaldisable`), `lcars-rollback` runs `--global enable`. This is the only change in `/etc`.

Full cycle after the change (fresh install from `pre-deploy`): symlinks removed (only Ubuntu's
`spice-vdagent` left); login screen after reboot: no hypridle, no polkit agent, no crash files;
LCARS: shell, hypridle, polkit agent running, `Super+L` locks; Ubuntu: no Hyprland helpers, no
crash files; `lcars-rollback --purge`: 31 changes, 0 problems, both services re-enabled, package
list identical. That run logged into GNOME before rolling back, so the home diff lists GNOME's
own first-login files (Evolution data, XDG folders, user-dirs) and `/etc/whoopsie` (created by
Ubuntu's crash reporter on the first GNOME login), none of them from LCARS.

## 2026-09-24 — Steven's feedback: unlock in the VM, varied block sizes

**"I can't log back in once I lock."** The VM had been locked for 2.5 min with *no* PAM attempts
in the journal; typing `lcars` via QEMU (`virsh send-key`) unlocked it immediately. So hyprlock
works; Steven's keystrokes didn't reach it. Most likely the host GNOME: `Super+L` is GNOME's own
lock shortcut, and a Super press caught by the host can leave Super "held" inside the VM, so typed
letters arrive as Super+letter. Workaround in the VM: lock with the LOCK block, click into the VM,
tap Super once, type. Not an issue on real hardware (no GNOME under LCARS). Open until Steven confirms.

**Variable sizes** (reference: an LCARS panel with mixed block heights and thin divider rules):
sidebar segments take `"size": "short" | "normal" | "tall"` (32 / 52 / 88 px, tokens
`frame.segmentShort/segmentHeight/segmentTall`), with a varied default rhythm; hints hide on
short blocks. The top bar gains a thin divider row of mixed-width blocks (`frame.dividerHeight`).

**Found while testing:** Hyprland auto-reloaded its config while `tools/lcars-gen` was rewriting
`colors.conf` → every `$lcars_*` variable failed to parse (config-error banner). `lcars-gen` now
writes to a temp file and renames it into place.
