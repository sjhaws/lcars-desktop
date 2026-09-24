#!/usr/bin/env bash
# Copy the working tree (minus the ISO, .git and generated files) to ~/lcars-desktop
# in the VM, then regenerate the themed files there: they contain the repo's path,
# which differs between the host and the VM user.
set -euo pipefail
source "$(dirname "$0")/config.sh"
rsync -a --delete -e "ssh -i $VM_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR" \
  --exclude '*.iso' --exclude .git --exclude 'hypr/generated/' "$(dirname "$0")/../" "$VM_USER@$(vm_ip):lcars-desktop/"
vm_ssh 'python3 ~/lcars-desktop/tools/lcars-gen >/dev/null'
