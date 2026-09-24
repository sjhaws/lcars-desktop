#!/usr/bin/env bash
# Usage: vm/reset.sh [SNAPSHOT]   — revert the VM (default: clean-install) and boot it
set -euo pipefail
source "$(dirname "$0")/config.sh"
name="${1:-clean-install}"
virsh snapshot-revert "$VM_NAME" "$name" --force
[ "$(virsh domstate "$VM_NAME")" = running ] || virsh start "$VM_NAME" >/dev/null
for _ in $(seq 60); do vm_ssh true 2>/dev/null && break; sleep 3; done
echo "Reverted to $name; VM is up at $(vm_ip)."
