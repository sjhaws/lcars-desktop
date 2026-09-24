#!/usr/bin/env python3
"""Grab one frame from a VNC server (no auth, raw encoding) and save it as PNG.
Used for VM screenshots: QEMU's screendump can't read virgl scanouts, VNC can.
Usage: vncgrab.py HOST PORT OUT.png"""
import socket, struct, sys
from PIL import Image

def recv(s, n):
    buf = b""
    while len(buf) < n:
        chunk = s.recv(n - len(buf))
        if not chunk:
            raise EOFError("VNC connection closed")
        buf += chunk
    return buf

host, port, out = sys.argv[1], int(sys.argv[2]), sys.argv[3]
s = socket.create_connection((host, port), timeout=15)
recv(s, 12); s.sendall(b"RFB 003.008\n")
ntypes = recv(s, 1)[0]
types = recv(s, ntypes)
if 1 not in types:
    sys.exit("VNC server requires authentication")
s.sendall(b"\x01")
if struct.unpack(">I", recv(s, 4))[0] != 0:
    sys.exit("VNC security handshake failed")
s.sendall(b"\x01")  # shared session
w, h = struct.unpack(">HH", recv(s, 4))
recv(s, 16)
recv(s, struct.unpack(">I", recv(s, 4))[0])
# 32bpp, depth 24, little-endian, true colour, BGRX layout
s.sendall(struct.pack(">B3xBBBBHHHBBB3x", 0, 32, 24, 0, 1, 255, 255, 255, 16, 8, 0))
s.sendall(struct.pack(">BxHi", 2, 1, 0))  # SetEncodings: raw only
s.sendall(struct.pack(">BBHHHH", 3, 0, 0, 0, w, h))  # full update request
img = Image.new("RGB", (w, h))
got = 0
while got < w * h:
    mtype = recv(s, 1)[0]
    if mtype == 0:
        recv(s, 1)
        for _ in range(struct.unpack(">H", recv(s, 2))[0]):
            x, y, rw, rh, enc = struct.unpack(">HHHHi", recv(s, 12))
            if enc == -223:  # DesktopSize pseudo-encoding
                continue
            data = recv(s, rw * rh * 4)
            img.paste(Image.frombytes("RGB", (rw, rh), data, "raw", "BGRX"), (x, y))
            got += rw * rh
    elif mtype == 2:  # bell
        continue
    elif mtype == 3:
        recv(s, 3); recv(s, struct.unpack(">I", recv(s, 4))[0])
    else:
        sys.exit(f"unexpected VNC message {mtype}")
img.save(out)
print(out)
