#!/usr/bin/env bash
# Usage: vm/click.sh X Y   — left-click at screen pixel X,Y (VM screen is 1280x800)
# Uses QMP input-send-event with absolute tablet coordinates (0..32767).
set -euo pipefail
source "$(dirname "$0")/config.sh"
W=${VM_SCREEN_W:-1280} H=${VM_SCREEN_H:-800}
ax=$(( $1 * 32767 / (W - 1) )) ay=$(( $2 * 32767 / (H - 1) ))
qmp() { virsh qemu-monitor-command "$VM_NAME" "$1" >/dev/null; }
qmp "{\"execute\":\"input-send-event\",\"arguments\":{\"events\":[
  {\"type\":\"abs\",\"data\":{\"axis\":\"x\",\"value\":$ax}},
  {\"type\":\"abs\",\"data\":{\"axis\":\"y\",\"value\":$ay}}]}}"
sleep 0.1
qmp '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":true,"button":"left"}}]}}'
sleep 0.1
qmp '{"execute":"input-send-event","arguments":{"events":[{"type":"btn","data":{"down":false,"button":"left"}}]}}'
