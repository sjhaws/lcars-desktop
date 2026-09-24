# Shared settings for the LCARS test VM. Sourced by the other vm/ scripts.
# VM files live outside the repo, in ~/lcars-vm.
VM_NAME=lcars-test
VM_DIR="$HOME/lcars-vm"
VM_POOL=default        # libvirt pool at /var/lib/libvirt/images, readable by libvirt-qemu
VM_KEY="$VM_DIR/id_ed25519"
VM_USER=steven
VM_PASS=lcars          # throwaway password for the GDM login inside the VM only
VM_CPUS=4
VM_RAM_MB=6144
VM_DISK_GB=40
VM_ISO_VOL=ubuntu-26.04.1-desktop-amd64.iso
VM_ISO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/ubuntu-26.04.1-desktop-amd64.iso"
# Intel iGPU render node; virgl on the NVIDIA proprietary driver is unreliable
VM_VNC_PORT=5959       # localhost only
VM_RENDERNODE=/dev/dri/by-path/pci-0000:00:02.0-render
export LIBVIRT_DEFAULT_URI=qemu:///system

if ! id -nG | grep -qw libvirt; then
  echo "This shell is not in the libvirt group yet: log out and back in." >&2
  return 1 2>/dev/null || exit 1
fi

vm_ip() {
  virsh domifaddr "$VM_NAME" --source lease 2>/dev/null |
    awk '/ipv4/ {split($4, a, "/"); print a[1]; exit}'
}

vm_ssh() {
  local ip; ip="$(vm_ip)"
  [ -n "$ip" ] || { echo "VM has no IP yet" >&2; return 1; }
  ssh -i "$VM_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o LogLevel=ERROR -o ConnectTimeout=5 "$VM_USER@$ip" "$@"
}
