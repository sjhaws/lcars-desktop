#!/usr/bin/env bash
# Create the test VM from the Ubuntu desktop ISO with an unattended autoinstall,
# then take the `clean-install` snapshot.
# Display: virgl renders through egl-headless on the Intel GPU and is shown over
# VNC on localhost (virt-manager opens it too). QEMU's screendump can't read a
# virgl scanout, so screenshots go through VNC (vm/vncgrab.py).
set -euo pipefail
source "$(dirname "$0")/config.sh"

[ -f "$VM_ISO" ] || { echo "Missing ISO: $VM_ISO" >&2; exit 1; }
virsh dominfo "$VM_NAME" >/dev/null 2>&1 && { echo "$VM_NAME already exists" >&2; exit 1; }

mkdir -p "$VM_DIR"
[ -f "$VM_KEY" ] || ssh-keygen -q -t ed25519 -N '' -C lcars-vm -f "$VM_KEY"

# libvirt-qemu can't read $HOME, so the ISO goes into the libvirt pool
if ! virsh pool-info "$VM_POOL" >/dev/null 2>&1; then
  virsh pool-define-as "$VM_POOL" dir --target /var/lib/libvirt/images
  virsh pool-build "$VM_POOL" || true
fi
virsh pool-start "$VM_POOL" >/dev/null 2>&1 || true
virsh pool-autostart "$VM_POOL" >/dev/null
if ! virsh vol-info "$VM_ISO_VOL" --pool "$VM_POOL" >/dev/null 2>&1; then
  echo "Uploading ISO to pool $VM_POOL..."
  virsh vol-create-as "$VM_POOL" "$VM_ISO_VOL" "$(stat -c %s "$VM_ISO")" --format raw
  virsh vol-upload "$VM_ISO_VOL" "$VM_ISO" --pool "$VM_POOL"
fi
# Direct kernel boot so we can pass `autoinstall` without editing GRUB
xorriso -osirrox on -indev "$VM_ISO" -extract /casper/vmlinuz "$VM_DIR/vmlinuz" \
        -extract /casper/initrd "$VM_DIR/initrd" >/dev/null 2>&1
chmod u+w "$VM_DIR/vmlinuz" "$VM_DIR/initrd"

hash="$(openssl passwd -6 "$VM_PASS")"
cat > "$VM_DIR/user-data" <<YAML
#cloud-config
autoinstall:
  version: 1
  interactive-sections: []
  locale: en_US.UTF-8
  keyboard: {layout: us}
  timezone: $(timedatectl show -p Timezone --value)
  identity:
    hostname: lcars-vm
    realname: $VM_REALNAME
    username: $VM_USER
    password: '$hash'
  ssh:
    install-server: true
    allow-pw: false
    authorized-keys: ['$(cat "$VM_KEY.pub")']
  storage: {layout: {name: direct}}
  packages: [spice-vdagent, mesa-utils]
  late-commands:
    - echo '$VM_USER ALL=(ALL) NOPASSWD:ALL' > /target/etc/sudoers.d/90-lcars-test
  shutdown: poweroff
YAML
printf 'instance-id: lcars-vm\nlocal-hostname: lcars-vm\n' > "$VM_DIR/meta-data"

virt-install \
  --name "$VM_NAME" --osinfo detect=on,require=off \
  --vcpus "$VM_CPUS" --memory "$VM_RAM_MB" --cpu host-passthrough \
  --disk "pool=$VM_POOL,size=$VM_DISK_GB,format=qcow2,bus=virtio" \
  --disk "vol=$VM_POOL/$VM_ISO_VOL,device=cdrom,bus=sata,readonly=on" \
  --install "kernel=$VM_DIR/vmlinuz,initrd=$VM_DIR/initrd,kernel_args=boot=casper autoinstall console=ttyS0\,115200 console=tty0,kernel_args_overwrite=yes" \
  --cloud-init "user-data=$VM_DIR/user-data,meta-data=$VM_DIR/meta-data" \
  --network network=default,model=virtio \
  --graphics vnc,listen=127.0.0.1,port="$VM_VNC_PORT" \
  --graphics egl-headless,gl.rendernode="$VM_RENDERNODE" \
  --video virtio,accel3d=yes \
  --input tablet,bus=virtio \
  --noautoconsole --wait -1

[ "$(virsh domstate "$VM_NAME")" = running ] || virsh start "$VM_NAME"
echo "Waiting for SSH..."
for _ in $(seq 60); do vm_ssh true 2>/dev/null && break; sleep 5; done
vm_ssh 'cloud-init status --wait >/dev/null 2>&1; lsb_release -ds'
virsh shutdown "$VM_NAME"
while [ "$(virsh domstate "$VM_NAME")" != "shut off" ]; do sleep 2; done
virsh snapshot-create-as "$VM_NAME" clean-install "Fresh Ubuntu desktop install"
echo "Created $VM_NAME with snapshot clean-install."
