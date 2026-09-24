// CPU, memory and network readouts for the top bar, refreshed every 2 seconds.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: stats
    property int cpu: 0          // percent busy since the last sample
    property int memory: 0       // percent used (MemTotal - MemAvailable)
    property string network: "…" // WIFI, WIRED, VPN or OFFLINE
    property var lastCpu: null

    FileView { id: procStat; path: "/proc/stat" }
    FileView { id: procMem; path: "/proc/meminfo" }

    function sample() {
        procStat.reload()
        procMem.reload()
        // first line: cpu user nice system idle iowait irq softirq steal ...
        const f = procStat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
        const idle = f[3] + f[4]
        const total = f.reduce((a, b) => a + b, 0)
        if (stats.lastCpu) {
            const dt = total - stats.lastCpu.total
            if (dt > 0) stats.cpu = Math.round(100 * (1 - (idle - stats.lastCpu.idle) / dt))
        }
        stats.lastCpu = { idle: idle, total: total }
        const mem = {}
        for (const line of procMem.text().split("\n")) {
            const m = line.match(/^(\w+):\s+(\d+)/)
            if (m) mem[m[1]] = Number(m[2])
        }
        if (mem.MemTotal) stats.memory = Math.round(100 * (1 - mem.MemAvailable / mem.MemTotal))
    }

    // NetworkManager's view of the connected devices, e.g. "wifi:connected:HomeNet"
    Process {
        id: nmcli
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "device"]
        stdout: StdioCollector {
            onStreamFinished: {
                const up = text.split("\n").map(l => l.split(":")).filter(p => p[1] === "connected")
                const types = up.map(p => p[0])
                stats.network = types.includes("vpn") || types.includes("wireguard") ? "VPN"
                    : types.includes("wifi") ? "WIFI"
                    : types.includes("ethernet") ? "WIRED"
                    : "OFFLINE"
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: stats.sample()
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: nmcli.running = true
    }
}
