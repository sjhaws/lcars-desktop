// Top bar: the elbow's horizontal arm, workspaces, a filler, stardate, clock, sound.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

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

    SystemClock { id: clock; precision: SystemClock.Seconds }
    // Earth-date stardate: 1000 units per year since 1946, one decimal
    function stardate(d) {
        const start = new Date(d.getFullYear(), 0, 1)
        const end = new Date(d.getFullYear() + 1, 0, 1)
        return ((d.getFullYear() - 1946) * 1000 + 1000 * (d - start) / (end - start)).toFixed(1)
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false

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

        Rectangle { Layout.preferredWidth: 90; Layout.fillHeight: true; color: Theme.color.orange }

        Repeater {
            model: 5
            Segment {
                required property int index
                readonly property int ws: index + 1
                Layout.preferredWidth: 52
                Layout.fillHeight: true
                label: "" + ws
                fill: Hyprland.focusedWorkspace?.id === ws ? Theme.color.orange : Theme.color.periwinkle
                onActivated: Hyprland.dispatch("workspace " + ws)
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.color.lavender }

        Segment {
            Layout.preferredWidth: 170
            Layout.fillHeight: true
            label: "Stardate " + bar.stardate(clock.date)
            fill: Theme.color.peach
        }
        Segment {
            Layout.preferredWidth: 110
            Layout.fillHeight: true
            label: Qt.formatDateTime(clock.date, "ddd HH:mm")
            fill: Theme.color.orange
        }
        Segment {
            Layout.preferredWidth: 110
            Layout.fillHeight: true
            label: bar.muted ? "Sound off" : "Sound on"
            fill: bar.muted ? Theme.color.red : Theme.color.lavender
            topRightRadius: height / 2
            bottomRightRadius: height / 2
            onActivated: if (bar.sink?.audio) bar.sink.audio.muted = !bar.muted
        }
    }
}
