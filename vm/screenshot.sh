#!/usr/bin/env bash
# Usage: vm/screenshot.sh [OUT.png]
# Captures the VM screen over VNC: works at GDM, text consoles and in any session.
# If VNC is busy (virt-manager holds the display exclusively), falls back to grim
# inside a running Hyprland session.
set -euo pipefail
source "$(dirname "$0")/config.sh"
out="${1:-$VM_DIR/screen.png}"
if python3 "$(dirname "$0")/vncgrab.py" 127.0.0.1 "$VM_VNC_PORT" "$out" 2>/dev/null; then exit 0; fi
if vm_ssh 'ls /run/user/$(id -u)/hypr/*/.socket.sock' >/dev/null 2>&1; then
  vm_ssh 'export XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-1; grim -' > "$out"
  echo "$out (via grim; VNC is in use by another viewer)"
else
  echo "VNC is in use by another viewer and no Hyprland session is running" >&2; exit 1
fi
