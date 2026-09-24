#!/usr/bin/env bash
# Usage: vm/hyprctl.sh ARGS...   — run hyprctl against the live Hyprland session in the VM
source "$(dirname "$0")/config.sh"
vm_ssh "export XDG_RUNTIME_DIR=/run/user/\$(id -u)
        export HYPRLAND_INSTANCE_SIGNATURE=\$(ls -t \"\$XDG_RUNTIME_DIR/hypr\" | head -1)
        hyprctl $(printf '%q ' "$@")" < /dev/null
