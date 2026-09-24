// Readout bar: the main elbow's horizontal arm, workspaces, then system readouts
// and volume (title, stardate, clock and LOCK are in Header.qml). Readouts are LCARS blocks; the volume one is interactive.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    // No left margin: Hyprland already places this after the sidebar's reserved
    // zone, because the sidebar is created first (see shell.qml)
    readonly property int pad: Theme.frame.padding
    readonly property int arm: Theme.frame.armHeight
    readonly property int inner: Theme.frame.innerRadius
    implicitHeight: pad + arm + inner
    exclusiveZone: implicitHeight
    color: Theme.color.background

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volume: Math.round(100 * (sink?.audio?.volume ?? 0))

    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    // UPower reports percentage as 0..1 in Quickshell 0.3; accept 0..100 too
    readonly property int batteryPercent: {
        const p = battery?.percentage ?? 0
        return Math.round(p <= 1 ? p * 100 : p)
    }

    // Workspaces 1-5 always, more when a higher one is in use or focused
    readonly property int workspaceCount: {
        let n = 5
        for (const w of Hyprland.workspaces.values) if (w.id > n && w.id <= 10) n = w.id
        return n
    }

    component Readout: Segment {
        Layout.fillHeight: true
        Layout.preferredWidth: Math.max(70, labelWidth + 20)
    }

    // Concave inner corner where the arm meets the sidebar's elbow
    Rectangle {
        x: 0; y: bar.pad
        width: bar.inner; height: bar.arm + bar.inner
        color: Theme.color.orange
        Rectangle {
            anchors { right: parent.right; bottom: parent.bottom }
            width: bar.inner; height: bar.inner
            color: Theme.color.background
            topLeftRadius: bar.inner
        }
    }

    RowLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: bar.pad; rightMargin: bar.pad }
        height: bar.arm
        spacing: Theme.frame.gap

        Rectangle { Layout.preferredWidth: 40; Layout.fillHeight: true; color: Theme.color.orange }

        Repeater {
            model: bar.workspaceCount
            Segment {
                required property int index
                readonly property int ws: index + 1
                Layout.preferredWidth: 44
                Layout.fillHeight: true
                label: "" + ws
                fill: Hyprland.focusedWorkspace?.id === ws ? Theme.color.orange : Theme.color.periwinkle
                onActivated: Hyprland.dispatch("workspace " + ws)
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.minimumWidth: 20; Layout.fillHeight: true; color: Theme.color.lavender }

        Readout {
            label: "CPU " + SystemStats.cpu + "%"
            fill: SystemStats.cpu >= 90 ? Theme.color.red : Theme.color.peach
        }
        Readout {
            label: "MEM " + SystemStats.memory + "%"
            fill: SystemStats.memory >= 90 ? Theme.color.red : Theme.color.lavender
        }
        Readout {
            label: "NET " + SystemStats.network
            fill: SystemStats.network === "OFFLINE" ? Theme.color.red : Theme.color.periwinkle
        }
        Readout {
            visible: bar.hasBattery
            label: "BAT " + bar.batteryPercent + "%" + (bar.battery?.state === UPowerDeviceState.Charging ? "+" : "")
            fill: bar.batteryPercent <= 15 && UPower.onBattery ? Theme.color.red : Theme.color.peach
        }
        Readout {
            label: bar.muted ? "MUTED" : "VOL " + bar.volume + "%"
            fill: bar.muted ? Theme.color.red : Theme.color.lavender
            topRightRadius: height / 2
            bottomRightRadius: height / 2
            onActivated: if (bar.sink?.audio) bar.sink.audio.muted = !bar.muted
            onScrolled: delta => {
                if (!bar.sink?.audio) return
                bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + (delta > 0 ? 0.05 : -0.05)))
            }
        }
    }
}
