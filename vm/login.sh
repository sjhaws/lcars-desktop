#!/usr/bin/env bash
# Usage: vm/login.sh SESSION   — log in at GDM as the test user into SESSION
# (e.g. ubuntu, lcars, hyprland). Presets the session through AccountsService,
# which is what GDM's gear menu sets, then types the password with virsh send-key.
set -euo pipefail
source "$(dirname "$0")/config.sh"
session="${1:?session name}"
vm_ssh "sudo busctl call org.freedesktop.Accounts /org/freedesktop/Accounts/User\$(id -u) \
        org.freedesktop.Accounts.User SetSession s $session"
session_up() {
  vm_ssh "loginctl list-sessions --no-legend | awk '\$3==\"$VM_USER\" && \$4==\"seat0\"' | grep -q ." 2>/dev/null
}
echo "Logging in to $session..."
# GDM re-reads the preset when the user is selected. Keys typed before the
# password field is ready are lost, so wait and retry.
for attempt in 1 2 3; do
  virsh send-key "$VM_NAME" KEY_ESC >/dev/null; sleep 2
  virsh send-key "$VM_NAME" KEY_ENTER >/dev/null; sleep 3
  for ch in $(echo "$VM_PASS" | fold -w1); do
    virsh send-key "$VM_NAME" "KEY_${ch^^}" >/dev/null
  done
  virsh send-key "$VM_NAME" KEY_ENTER >/dev/null
  for _ in $(seq 10); do session_up && { echo "Session up."; exit 0; }; sleep 2; done
  echo "attempt $attempt: no session yet" >&2
done
echo "No graphical session for $VM_USER" >&2; exit 1
