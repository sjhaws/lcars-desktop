#!/usr/bin/env bash
# install.sh — install the LCARS session alongside the stock Ubuntu session.
#
# Every change is recorded in ~/.local/state/lcars/manifest so that
# bin/lcars-rollback can undo it exactly. Changes, in order:
#   1. Timeshift snapshot "Before LCARS install" (skip with --no-timeshift)
#   2. Tarball of ~/.config in ~/lcars-backups/ (kept after rollback)
#   3. apt packages listed in PACKAGES (only the newly installed ones are recorded)
#   4. Themed files are generated from tokens/palette.json (tools/lcars-gen, inside
#      the repo), then ~/.config/<dir> symlinks into this repo; existing dirs are
#      moved aside first. The Antonio font is linked into ~/.local/share/fonts
#   5. ~/.local/bin/lcars-session (symlink) and ~/.local/bin/lcars-rollback (copy,
#      so rollback still works if this repo is moved or deleted)
#   5b. Quickshell (the LCARS shell toolkit, not packaged for Ubuntu) is built from
#      a pinned release into ~/.local; every installed file is recorded. Its build
#      dependencies are ordinary apt packages, recorded like the others
#   6. /usr/share/wayland-sessions/lcars.desktop
#   7. Hyprland's runtime dirs (~/.local/share/hyprland, ~/.cache/hyprland) are
#      recorded if they don't exist yet, so rollback can remove what Hyprland creates
#   8. The stock "Hyprland" login entries are hidden with `dpkg-divert --local`,
#      so the only way into Hyprland from GDM is the crash-guarded LCARS session
#   9. ~/.apport-ignore.xml gets entries for /usr/bin/Hyprland (0.53 segfaults on
#      every exit) and for the session helpers that abort when the compositor
#      goes away, which would otherwise pop up crash dialogs in the next GNOME session
#  12. ~/.config/lcars (your custom sidebar menu and settings) is recorded as user data: rollback
#      moves it to ~/lcars-backups instead of deleting it
#  11. The packaged user services for hyprpolkitagent and hypridle (and mako, if present) are
#      masked for this user (`systemctl --user mask`): the packages enable them for
#      every graphical login, GNOME included. LCARS starts these tools itself.
#  10. The crash guard's one-time notice (~/.config/autostart/lcars-fallback-notice.desktop)
#      is recorded so rollback removes it if it never got shown
#  13. `systemctl --global disable` for hypridle and hyprpolkitagent: their packages
#      enable them for every user's graphical session (the login screen and other
#      accounts included). This removes their two symlinks under
#      /etc/systemd/user/graphical-session.target.wants/ — the only change in /etc.
# It never touches GDM or GNOME, and does not make LCARS the default session.
#
# Usage: ./install.sh [--no-timeshift] [--deploy]
#   --deploy        required to run outside a VM (Phase 5 only)

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/lcars"
MANIFEST="$STATE/manifest"
SESSION_FILE=/usr/share/wayland-sessions/lcars.desktop
PACKAGES=(
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk hyprpolkitagent
  hyprlock hypridle
  grim slurp wl-clipboard brightnessctl playerctl
  # Quickshell build and runtime dependencies
  g++ git cmake ninja-build pkg-config spirv-tools libcli11-dev libjemalloc-dev
  qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-declarative-private-dev
  qt6-shadertools-dev qt6-wayland-dev qt6-wayland-private-dev qt6-svg-dev
  wayland-protocols libwayland-dev libdrm-dev libgbm-dev libegl-dev libpipewire-0.3-dev libglib2.0-dev
  qml6-module-qtquick qml6-module-qtquick-layouts qml6-module-qtquick-window
  qml6-module-qtqml-workerscript
  upower                          # battery readout (already on laptops)
  pipewire-bin                    # pw-play for interface sounds (already on Ubuntu)
)
QS_TAG=v0.3.1
QS_REPO=https://github.com/quickshell-mirror/quickshell.git
QS_BIN="$HOME/.local/bin/quickshell"
USER_MENU_DIR="$HOME/.config/lcars"
PKG_RECORD="$HOME/lcars-backups/lcars-packages.txt"   # survives rollback, for a later --purge
RUNTIME_DIRS=("$HOME/.local/share/hyprland" "$HOME/.cache/hyprland")
HIDE_SESSIONS=(/usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland-uwsm.desktop)
APPORT_IGNORE="$HOME/.apport-ignore.xml"
APPORT_PROGRAMS=(/usr/bin/Hyprland /usr/libexec/hyprpolkitagent /usr/libexec/xdg-desktop-portal-hyprland
                 /usr/bin/hypridle)
MASK_UNITS=(hyprpolkitagent.service hypridle.service mako.service)
GLOBAL_DISABLE_UNITS=(hypridle.service hyprpolkitagent.service)
FALLBACK_NOTICE="$HOME/.config/autostart/lcars-fallback-notice.desktop"   # written by lcars-session
CONFIG_LINKS=(hypr)               # ~/.config/<name> -> $REPO/<name>
FONT_LINK="$HOME/.local/share/fonts/lcars"

timeshift=1 deploy=0
for arg in "$@"; do
  case "$arg" in
    --no-timeshift) timeshift=0 ;;
    --deploy) deploy=1 ;;
    -h|--help) sed -n '2,/^$/s/^# \{0,1\}//p' "$0"; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

say()  { printf '\033[1;33m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
record() { grep -qxF "$1" "$MANIFEST" 2>/dev/null || printf '%s\n' "$1" >> "$MANIFEST"; }

# ---- preflight -------------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "Run as your normal user, not root."
if ! systemd-detect-virt -q && [ "$deploy" -ne 1 ]; then
  die "This is not a VM. Until Phase 5, install only in the test VM (or pass --deploy)."
fi
. /etc/os-release
[ "$ID" = ubuntu ] || die "Ubuntu only (found $ID)."
[ -f /usr/share/wayland-sessions/ubuntu.desktop ] || die "Stock Ubuntu session not found; refusing."
sudo true || die "sudo is required."
mkdir -p "$STATE"
touch "$MANIFEST"
ts="$(date +%Y%m%d-%H%M%S)"

# ---- 1. system snapshot ----------------------------------------------------
if [ "$timeshift" -eq 1 ]; then
  command -v timeshift >/dev/null || die "Timeshift not installed (install it, or pass --no-timeshift)."
  say "Timeshift snapshot"
  sudo timeshift --create --comments "Before LCARS install $ts" --tags O
fi

# ---- 2. ~/.config backup ---------------------------------------------------
say "Backing up ~/.config to ~/lcars-backups/config-$ts.tar.gz"
mkdir -p "$HOME/lcars-backups"
tar -C "$HOME" -czf "$HOME/lcars-backups/config-$ts.tar.gz" .config

# ---- 3. packages -----------------------------------------------------------
missing=()
for p in "${PACKAGES[@]}"; do
  dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed' || missing+=("$p")
done
if [ "${#missing[@]}" -gt 0 ]; then
  say "Installing packages: ${missing[*]}"
  before="$(dpkg-query -W -f='${Package}\n' | LC_ALL=C sort)"
  # Wait for the dpkg lock (PackageKit or unattended-upgrades often hold it after boot)
  sudo apt-get -o DPkg::Lock::Timeout=300 update -qq
  # Say so if apt must also upgrade packages you already have: rollback won't
  # downgrade them (they're normally pending Ubuntu updates)
  upgrades="$(apt-get -s install "${missing[@]}" 2>/dev/null | awk '/^Inst [^ ]+ \[/{print $2}' | tr '\n' ' ')"
  [ -z "$upgrades" ] || say "Note: apt will also update these installed packages (kept on rollback): $upgrades"
  # Retry once after refreshing the index: while Ubuntu publishes an update the
  # index can briefly point at a package version the mirror no longer has (404)
  sudo apt-get -o DPkg::Lock::Timeout=300 install -y "${missing[@]}" || {
    say "Package download failed; refreshing the package index and retrying once"
    sudo apt-get -o DPkg::Lock::Timeout=300 update -qq
    sudo apt-get -o DPkg::Lock::Timeout=300 install -y "${missing[@]}"
  }
  after="$(dpkg-query -W -f='${Package}\n' | LC_ALL=C sort)"
  # Record every package that is new, including dependencies, for `lcars-rollback --purge`
  LC_ALL=C comm -13 <(echo "$before") <(echo "$after") | while read -r p; do
    record "pkg	$p"
    grep -qxF "$p" "$PKG_RECORD" 2>/dev/null || echo "$p" >> "$PKG_RECORD"
  done
else
  say "Packages already installed"
fi

# ---- 4-5. user files -------------------------------------------------------
link() {  # link TARGET LINKPATH
  local target="$1" path="$2"
  if [ -L "$path" ] && [ "$(readlink "$path")" = "$target" ]; then return; fi
  if [ -e "$path" ] || [ -L "$path" ]; then
    local backup="$STATE/backup/$ts${path#"$HOME"}"
    mkdir -p "$(dirname "$backup")"
    mv "$path" "$backup"
    record "moved	$path	$backup"
    say "Moved existing $path aside"
  fi
  ln -s "$target" "$path"
  record "link	$path"
  say "Linked $path -> $target"
}
# Record every missing directory from $1 up to $HOME (rollback removes them if empty)
record_missing_dirs() {
  local d="$1" missing=()
  while [ "$d" != "$HOME" ] && [ ! -e "$d" ]; do missing=("$d" "${missing[@]}"); d="$(dirname "$d")"; done
  for d in "${missing[@]}"; do record "dir	$d"; done
}
mkdir_rec() { record_missing_dirs "$1"; mkdir -p "$1"; }

say "Generating themed files from tokens/palette.json"
python3 "$REPO/tools/lcars-gen" >/dev/null

mkdir_rec "$HOME/.config"
for name in "${CONFIG_LINKS[@]}"; do link "$REPO/$name" "$HOME/.config/$name"; done
mkdir_rec "$(dirname "$FONT_LINK")"
link "$REPO/fonts" "$FONT_LINK"
fc-cache -f "$(dirname "$FONT_LINK")" >/dev/null 2>&1 || true
mkdir_rec "$HOME/.local/bin"
link "$REPO/bin/lcars-session" "$HOME/.local/bin/lcars-session"
install -m 755 "$REPO/bin/lcars-rollback" "$HOME/.local/bin/lcars-rollback"
record "file	$HOME/.local/bin/lcars-rollback"
say "Installed $HOME/.local/bin/lcars-rollback"

# ---- 5b. Quickshell, built into ~/.local -------------------------------------
if ! "$QS_BIN" --version 2>/dev/null | grep -q "Quickshell ${QS_TAG#v} "; then
  say "Building Quickshell $QS_TAG into ~/.local (takes a few minutes)"
  # Build on disk: /tmp is a size-limited tmpfs on Ubuntu 26.04
  src="$HOME/.cache/lcars-build"
  buildlog="$STATE/quickshell-build.log"
  record_missing_dirs "$(dirname "$src")"
  record "rundir	$src"
  rm -rf "$src"; mkdir -p "$src"
  # Snapshot ~/.local: CMake's install_manifest.txt misses some files (the qs
  # link, the icon), so new files are found by comparing before and after
  dirs_before="$(find "$HOME/.local" -xdev -type d 2>/dev/null | LC_ALL=C sort)"
  files_before="$(find "$HOME/.local" -xdev ! -type d 2>/dev/null | LC_ALL=C sort)"
  if ! { git -c advice.detachedHead=false clone -q --depth 1 --branch "$QS_TAG" "$QS_REPO" "$src/quickshell" &&
         cmake -S "$src/quickshell" -B "$src/build" -G Ninja -DCMAKE_BUILD_TYPE=Release \
           -DCMAKE_INSTALL_PREFIX="$HOME/.local" -DCRASH_HANDLER=OFF -DX11=OFF -DI3=OFF \
           -DSERVICE_PAM=OFF -DSERVICE_POLKIT=OFF &&
         cmake --build "$src/build" &&
         cmake --install "$src/build"; } > "$buildlog" 2>&1; then
    tail -n 30 "$buildlog" >&2
    die "Quickshell build failed (full log: $buildlog). Nothing else was changed after this step; lcars-rollback undoes the rest."
  fi
  # Record new directories (parents first) and every installed file
  LC_ALL=C comm -13 <(echo "$dirs_before") <(find "$HOME/.local" -xdev -type d | LC_ALL=C sort) |
    while read -r d; do record "dir	$d"; done
  LC_ALL=C comm -13 <(echo "$files_before") <(find "$HOME/.local" -xdev ! -type d | LC_ALL=C sort) |
    while read -r f; do record "file	$f"; done
  rm -rf "$src"
  say "Installed $("$QS_BIN" --version | head -n1)"
fi

# ---- 13. keep Hyprland helpers out of every other user's session --------------
for unit in "${GLOBAL_DISABLE_UNITS[@]}"; do
  if [ "$(systemctl --global is-enabled "$unit" 2>/dev/null)" = enabled ]; then
    sudo systemctl --global disable "$unit" >/dev/null 2>&1
    record "globaldisable	$unit"
    say "Disabled $unit for all users' sessions (LCARS starts it itself)"
  fi
done

# ---- 12. the custom menu (created later by the sidebar, if ever) --------------
[ -e "$USER_MENU_DIR" ] || record "userdata	$USER_MENU_DIR"

# ---- 7. runtime dirs Hyprland will create ----------------------------------
for d in "${RUNTIME_DIRS[@]}"; do
  [ -e "$d" ] && continue
  record_missing_dirs "$(dirname "$d")"
  record "rundir	$d"
done

# ---- 8. hide the unguarded stock Hyprland sessions -------------------------
for f in "${HIDE_SESSIONS[@]}"; do
  if [ -e "$f" ] && ! dpkg-divert --list "$f" | grep -q .; then
    sudo dpkg-divert --local --rename --divert "$f.lcars-hidden" --add "$f"
    record "divert	$f"
    say "Hid $(basename "$f") from the login screen"
  fi
done

# ---- 9. apport: ignore crashes caused by the compositor exiting --------------
# lcars-session still logs every real Hyprland crash. mtime far in the future so
# the entries keep matching after package upgrades.
for prog in "${APPORT_PROGRAMS[@]}"; do
  added="$(python3 - "$APPORT_IGNORE" "$prog" <<'PY'
import os, sys, xml.dom.minidom as md
path, prog = sys.argv[1], sys.argv[2]
dom = md.parse(path) if os.path.isfile(path) else md.parseString("<apport/>")
if any(e.getAttribute("program") == prog for e in dom.getElementsByTagName("ignore")):
    print("no")
else:
    e = dom.createElement("ignore")
    e.setAttribute("program", prog)
    e.setAttribute("mtime", "4102444800")
    dom.documentElement.appendChild(e)
    open(path, "w").write(dom.toxml())
    print("yes")
PY
)"
  if [ "$added" = yes ]; then
    record "apportignore	$prog"
    say "Crash dialogs for $(basename "$prog") disabled in $APPORT_IGNORE"
  fi
done

# ---- 11. keep Hyprland helpers out of other sessions --------------------------
record_missing_dirs "$HOME/.config/systemd/user"
for unit in "${MASK_UNITS[@]}"; do
  if [ "$(systemctl --user is-enabled "$unit" 2>/dev/null)" != masked ] &&
     systemctl --user cat "$unit" >/dev/null 2>&1; then
    systemctl --user mask "$unit" >/dev/null 2>&1
    record "mask	$unit"
    say "Masked user service $unit (LCARS starts it itself)"
  fi
done

# ---- 10. crash-guard notice (created later by lcars-session, if ever) ---------
record_missing_dirs "$(dirname "$FALLBACK_NOTICE")"
record "rundir	$FALLBACK_NOTICE"

# ---- 6. login session entry ------------------------------------------------
say "Adding LCARS to the login screen ($SESSION_FILE)"
sed "s|@LCARS_SESSION@|$HOME/.local/bin/lcars-session|" "$REPO/session/lcars.desktop.in" |
  sudo install -m 644 /dev/stdin "$SESSION_FILE"
record "sysfile	$SESSION_FILE"

say "Done. Log out, click your name, pick \"LCARS\" from the gear icon."
say "Undo everything with: lcars-rollback   (add --purge to remove packages)"
