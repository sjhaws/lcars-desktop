#!/usr/bin/env bash
# Usage: vm/snapshot.sh NAME [DESCRIPTION]   — replaces an existing snapshot of that name
set -euo pipefail
source "$(dirname "$0")/config.sh"
name="${1:?snapshot name}"
virsh snapshot-delete "$VM_NAME" "$name" >/dev/null 2>&1 || true
virsh snapshot-create-as "$VM_NAME" "$name" "${2:-}" >/dev/null
echo "Snapshot $name taken."
