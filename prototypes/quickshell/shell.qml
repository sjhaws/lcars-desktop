// Phase 1 bake-off: minimal LCARS top bar in Quickshell (QML).
// Run in the VM:  qs -p ~/lcars-desktop/prototypes/quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

ShellRoot {
    id: root

    FileView {
        id: tokensFile
        path: Quickshell.shellDir + "/../../tokens/palette.json"
        blockLoading: true
    }
    readonly property var tokens: JSON.parse(tokensFile.text())
    readonly property var c: tokens.color
    readonly property string fontFamily: tokens.font.family

    SystemClock { id: clock; precision: SystemClock.Seconds }

    // Earth-date stardate: 1000 units per year since 1946, 1 decimal
    function stardate(d) {
        const start = new Date(d.getFullYear(), 0, 1);
        const end = new Date(d.getFullYear() + 1, 0, 1);
        return ((d.getFullYear() - 1946) * 1000 + 1000 * (d - start) / (end - start)).toFixed(1);
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false

    component Pill: Rectangle {
        id: pill
        property string label: ""
        property color fill: root.c.peach
        property bool leftCap: false
        property bool rightCap: false
        signal clicked()
        implicitHeight: 28
        implicitWidth: Math.max(64, text.implicitWidth + 28)
        color: area.pressed ? Qt.lighter(fill, 1.25) : fill
        topLeftRadius: leftCap ? height / 2 : 0
        bottomLeftRadius: leftCap ? height / 2 : 0
        topRightRadius: rightCap ? height / 2 : 0
        bottomRightRadius: rightCap ? height / 2 : 0
        Text {
            id: text
            anchors { right: parent.right; rightMargin: 10; bottom: parent.bottom; bottomMargin: 2 }
            text: pill.label.toUpperCase()
            color: root.c.textOnColor
            font { family: root.fontFamily; pixelSize: 18; weight: root.tokens.font.weight }
        }
        MouseArea { id: area; anchors.fill: parent; onClicked: pill.clicked() }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 64
            color: root.c.background

            // Elbow: thick block with a rounded outer corner and a concave inner curve
            Rectangle {
                id: elbow
                x: 8; y: 8
                width: 180; height: 56
                color: root.c.orange
                topLeftRadius: 28
                Rectangle {
                    anchors { right: parent.right; bottom: parent.bottom }
                    width: parent.width - 60; height: parent.height - 28
                    color: root.c.background
                    topLeftRadius: 18
                }
                Text {
                    x: 64; y: 2
                    text: "LCARS " + Qt.formatDateTime(clock.date, "HH:mm")
                    color: root.c.textOnColor
                    font { family: root.fontFamily; pixelSize: 22; weight: root.tokens.font.weight }
                }
            }

            RowLayout {
                anchors { left: elbow.right; leftMargin: 6; right: parent.right; rightMargin: 8; top: elbow.top }
                spacing: 6

                Repeater {
                    model: 5
                    Pill {
                        required property int index
                        readonly property int ws: index + 1
                        label: "" + ws
                        implicitWidth: 56
                        fill: Hyprland.focusedWorkspace?.id === ws ? root.c.orange : root.c.periwinkle
                        onClicked: Hyprland.dispatch("workspace " + ws)
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 28; color: root.c.lavender }
                Pill {
                    label: "Stardate " + root.stardate(clock.date)
                    fill: root.c.peach
                }
                Pill {
                    label: root.muted ? "Sound off" : "Sound on"
                    fill: root.muted ? root.c.red : root.c.orange
                    rightCap: true
                    onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.muted
                }
            }
        }
    }
}
