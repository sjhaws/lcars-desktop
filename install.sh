#!/usr/bin/env bash
# install.sh — install the LCARS session alongside the stock Ubuntu session.
#
# Every change is recorded in ~/.local/state/lcars/manifest so that
# bin/lcars-rollback can undo it exactly. Changes, in order:
#   1. Timeshift snapshot "Before LCARS install" (skip with --no-timeshift)
#   2. Tarball of ~/.config in ~/lcars-backups/ (kept after rollback)
#   3. apt packages listed in PACKAGES (only the newly installed ones are recorded)
#   4. ~/.config/<dir> symlinks into this repo; existing dirs are moved aside first
#   5. ~/.local/bin/lcars-session (symlink) and ~/.local/bin/lcars-rollback (copy,
#      so rollback still works if this repo is moved or deleted)
#   6. /usr/share/wayland-sessions/lcars.desktop — the only file outside $HOME
#   7. Hyprland's runtime dirs (~/.local/share/hyprland, ~/.cache/hyprland) are
#      recorded if they don't exist yet, so rollback can remove what Hyprland creates
#   8. The stock "Hyprland" login entries are hidden with `dpkg-divert --local`,
#      so the only way into Hyprland from GDM is the crash-guarded LCARS session
#   9. ~/.apport-ignore.xml gets an entry for /usr/bin/Hyprland: Hyprland 0.53
#      segfaults on every exit, which would otherwise pop up a crash dialog
#  10. The crash guard's one-time notice (~/.config/autostart/lcars-fallback-notice.desktop)
#      is recorded so rollback removes it if it never got shown
# It never touches GDM, GNOME or /etc, and does not make LCARS the default session.
#
# Usage: ./install.sh [--no-timeshift] [--deploy]
#   --deploy        required to run outside a VM (Phase 5 only)

set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/lcars"
MANIFEST="$STATE/manifest"
SESSION_FILE=/usr/share/wayland-sessions/lcars.desktop
PACKAGES=(hyprland xdg-desktop-portal-hyprland grim)
PKG_RECORD="$HOME/lcars-backups/lcars-packages.txt"   # survives rollback, for a later --purge
RUNTIME_DIRS=("$HOME/.local/share/hyprland" "$HOME/.cache/hyprland")
HIDE_SESSIONS=(/usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland-uwsm.desktop)
APPORT_IGNORE="$HOME/.apport-ignore.xml"
FALLBACK_NOTICE="$HOME/.config/autostart/lcars-fallback-notice.desktop"   # written by lcars-session
CONFIG_LINKS=(hypr)               # ~/.config/<name> -> $REPO/<name>

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
  sudo apt-get update -qq
  sudo apt-get install -y "${missing[@]}"
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
mkdir_rec() { [ -d "$1" ] || { mkdir -p "$1"; record "dir	$1"; }; }

mkdir_rec "$HOME/.config"
for name in "${CONFIG_LINKS[@]}"; do link "$REPO/$name" "$HOME/.config/$name"; done
mkdir_rec "$HOME/.local/bin"
link "$REPO/bin/lcars-session" "$HOME/.local/bin/lcars-session"
install -m 755 "$REPO/bin/lcars-rollback" "$HOME/.local/bin/lcars-rollback"
record "file	$HOME/.local/bin/lcars-rollback"
say "Installed $HOME/.local/bin/lcars-rollback"

# ---- 7. runtime dirs Hyprland will create ----------------------------------
for d in "${RUNTIME_DIRS[@]}"; do
  [ -e "$d" ] && continue
  # Parents that don't exist yet are removed later only if empty
  parent="$(dirname "$d")"
  missing=()
  while [ "$parent" != "$HOME" ] && [ ! -e "$parent" ]; do missing=("$parent" "${missing[@]}"); parent="$(dirname "$parent")"; done
  for m in "${missing[@]}"; do record "dir	$m"; done
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

# ---- 9. apport: ignore Hyprland's crash-on-exit ------------------------------
# lcars-session still logs every real crash. mtime far in the future so the
# entry keeps matching after Hyprland package upgrades.
added="$(python3 - "$APPORT_IGNORE" <<'PY'
import os, sys, xml.dom.minidom as md
path, prog = sys.argv[1], "/usr/bin/Hyprland"
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
  record "apportignore	/usr/bin/Hyprland"
  say "Crash dialogs for Hyprland disabled in $APPORT_IGNORE"
fi

# ---- 10. crash-guard notice (created later by lcars-session, if ever) ---------
[ -d "$(dirname "$FALLBACK_NOTICE")" ] || record "dir	$(dirname "$FALLBACK_NOTICE")"
record "rundir	$FALLBACK_NOTICE"

# ---- 6. login session entry ------------------------------------------------
say "Adding LCARS to the login screen ($SESSION_FILE)"
sed "s|@LCARS_SESSION@|$HOME/.local/bin/lcars-session|" "$REPO/session/lcars.desktop.in" |
  sudo install -m 644 /dev/stdin "$SESSION_FILE"
record "sysfile	$SESSION_FILE"

say "Done. Log out, click your name, pick \"LCARS\" from the gear icon."
say "Undo everything with: lcars-rollback   (add --purge to remove packages)"
