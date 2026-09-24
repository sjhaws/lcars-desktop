#!/usr/bin/env bash
# Copy the working tree (minus the ISO and .git) to ~/lcars-desktop in the VM.
set -euo pipefail
source "$(dirname "$0")/config.sh"
rsync -a --delete -e "ssh -i $VM_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
  --exclude '*.iso' --exclude .git "$(dirname "$0")/../" "$VM_USER@$(vm_ip):lcars-desktop/"
