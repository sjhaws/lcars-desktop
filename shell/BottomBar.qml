// Bottom rule: the sidebar's foot curves into it (concave corner at its left),
// then mixed-width blocks and the machine's IP address, LCARS style ("192 168 0 3").
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: bottom
    anchors { bottom: true; left: true; right: true }
    readonly property int pad: Theme.frame.padding
    readonly property int armH: Theme.frame.footHeight
    readonly property int inner: Theme.frame.innerRadius
    implicitHeight: pad + armH + inner
    exclusiveZone: implicitHeight
    color: Theme.color.background

    property string address: "NO ADDRESS"
    Process {
        id: ip
        command: ["hostname", "-I"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v4 = text.trim().split(/\s+/).find(a => /^\d+\.\d+\.\d+\.\d+$/.test(a))
                bottom.address = v4 ? v4.split(".").join(" ") : "NO ADDRESS"
            }
        }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: ip.running = true }

    // Concave corner above the arm, next to the sidebar's foot
    Rectangle {
        x: 0; y: bottom.height - bottom.pad - bottom.armH - bottom.inner
        width: bottom.inner; height: bottom.inner
        color: Theme.color.orange
        Rectangle { anchors.fill: parent; color: Theme.color.background; bottomLeftRadius: bottom.inner }
    }

    RowLayout {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: bottom.pad; rightMargin: bottom.pad }
        height: bottom.armH
        spacing: Theme.frame.gap
        Rectangle { Layout.preferredWidth: 120; Layout.fillHeight: true; color: Theme.color.orange; Layout.leftMargin: -Theme.frame.gap }
        Rectangle { Layout.preferredWidth: 60; Layout.fillHeight: true; color: Theme.color.peach }
        Rectangle { Layout.fillWidth: true; Layout.fillHeight: true; color: Theme.color.periwinkle }
        Rectangle { Layout.preferredWidth: 24; Layout.fillHeight: true; color: Theme.color.orange }
        Segment {
            Layout.preferredWidth: labelWidth + 24
            Layout.fillHeight: true
            label: bottom.address
            fill: Theme.color.peach
            topRightRadius: height / 2
            bottomRightRadius: height / 2
        }
    }
}
