// Compact mode: the whole frame folds into this thin LCARS line at the top of the
// screen and the apps get the rest. Click it (or press Super+F11) to unfold.
import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: line
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.frame.compactHeight
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    color: Theme.color.background

    RowLayout {
        anchors.fill: parent
        anchors.bottomMargin: 2
        spacing: Theme.frame.gap
        Repeater {
            // an echo of the full frame's colors: elbow, workspaces, readouts, clock
            model: [
                { w: 140, c: "orange" }, { w: 60, c: "periwinkle" }, { w: 0, c: "lavender" },
                { w: 90, c: "peach" }, { w: 40, c: "orange" }, { w: 120, c: "periwinkle" },
                { w: 70, c: "red" }
            ]
            Rectangle {
                required property var modelData
                required property int index
                Layout.fillHeight: true
                Layout.fillWidth: modelData.w === 0
                Layout.preferredWidth: modelData.w
                color: Theme.named(modelData.c)
                bottomLeftRadius: index === 0 ? height : 0
                bottomRightRadius: index === 6 ? height : 0
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { Sounds.play("open"); Settings.toggleCompact() }
    }
}
