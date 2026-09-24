#!/usr/bin/env bash
# Usage: vm/screenshot.sh [OUT.png]
# Captures the VM screen over VNC: works at GDM, text consoles and in any session.
# (Inside Hyprland, `vm/ssh.sh grim` also works, but can't see GDM or consoles.)
set -euo pipefail
source "$(dirname "$0")/config.sh"
out="${1:-$VM_DIR/screen.png}"
python3 "$(dirname "$0")/vncgrab.py" 127.0.0.1 "$VM_VNC_PORT" "$out"
