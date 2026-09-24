#!/usr/bin/env bash
# Turn a fresh `clean-install` VM into `pre-deploy`: install and configure
# Timeshift (rsync mode, root disk) like the host, and apply all Ubuntu updates
# so the VM matches a maintained machine. Then take the `pre-deploy` snapshot.
set -euo pipefail
source "$(dirname "$0")/config.sh"

"$(dirname "$0")/reset.sh" clean-install
vm_ssh 'set -e
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get -o DPkg::Lock::Timeout=300 update -qq
  sudo apt-get -o DPkg::Lock::Timeout=300 install -y -qq timeshift >/dev/null
  sudo apt-get -o DPkg::Lock::Timeout=300 full-upgrade -y -qq >/dev/null
  sudo snap refresh >/dev/null 2>&1 || true
  sudo timeshift --list >/dev/null 2>&1 || true      # writes the default config
  u=$(sudo blkid -s UUID -o value "$(findmnt -no SOURCE /)")
  sudo sed -i "s/\"backup_device_uuid\" : \"[^\"]*\"/\"backup_device_uuid\" : \"$u\"/" /etc/timeshift/timeshift.json
  sudo timeshift --list | grep -E "Device|Mode"'
vm_ssh 'sudo poweroff' || true
while [ "$(virsh domstate "$VM_NAME")" != "shut off" ]; do sleep 2; done
"$(dirname "$0")/snapshot.sh" pre-deploy "clean-install + Timeshift (rsync) + all updates"
