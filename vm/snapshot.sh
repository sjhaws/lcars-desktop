#!/usr/bin/env bash
# Usage: vm/snapshot.sh NAME [DESCRIPTION]   — replaces an existing snapshot of that name
# The VM must be shut off: libvirt can't save a running VM's memory with virgl.
set -euo pipefail
source "$(dirname "$0")/config.sh"
name="${1:?snapshot name}"
if [ "$(virsh domstate "$VM_NAME")" != "shut off" ]; then
  echo "Shut the VM down first (vm/ssh.sh sudo poweroff)." >&2; exit 1
fi
virsh snapshot-delete "$VM_NAME" "$name" >/dev/null 2>&1 || true
virsh snapshot-create-as "$VM_NAME" "$name" "${2:-}" >/dev/null
echo "Snapshot $name taken."
