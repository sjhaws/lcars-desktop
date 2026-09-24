#!/usr/bin/env bash
# Usage: vm/fingerprint.sh OUT   — record the guest state LCARS may touch, for
# before/after comparisons (rollback must return every line to its old value).
# Runtime noise that any login creates (caches, logs, sockets) is excluded.
set -euo pipefail
source "$(dirname "$0")/config.sh"
vm_ssh 'bash -s' > "${1:?output file}" <<'REMOTE'
cd "$HOME"
echo "## files under ~/.config and ~/.local (type, target or sha256)"
find .config .local -xdev \( -path .local/share/Trash -o -path .local/share/recently-used.xbel \
     -o -path '.local/state/wireplumber' -o -path '.local/share/gvfs-metadata' \
     -o -path '.config/pulse' -o -path '.local/share/keyrings' -o -path '.local/state/*/log*' \
     -o -path .config/dconf -o -path .local/share/sounds -o -path .local/share/tracker \) -prune -o -print 2>/dev/null | sort |
while read -r f; do
  if [ -L "$f" ]; then echo "L $f -> $(readlink "$f")"
  elif [ -d "$f" ]; then echo "D $f"
  else echo "F $f $(sha256sum < "$f" | cut -c1-16)"; fi
done
echo "## home top level"
ls -A1 | grep -vE '^\.(cache|bash_history|lesshst|sudo_as_admin_successful|ssh|wget-hsts)$' || true
echo "## packages"
dpkg-query -W -f='${Package} ${Version}\n' | sort | sha256sum
echo "## session files"
ls /usr/share/wayland-sessions /usr/share/xsessions 2>/dev/null
echo "## default session"
busctl get-property org.freedesktop.Accounts /org/freedesktop/Accounts/User$(id -u) org.freedesktop.Accounts.User Session
echo "## /etc checksum (excluding timeshift, machine state)"
sudo find /etc -xdev -type f ! -path '/etc/timeshift/*' ! -name 'ld.so.cache' ! -path '/etc/cups/*' -print0 2>/dev/null | sort -z | sudo xargs -0 sha256sum | sha256sum
REMOTE
echo "$1"
