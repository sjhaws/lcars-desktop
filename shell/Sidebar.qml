// Left sidebar: the elbow at the top, menu segments, a filler block, then the footer.
import QtQuick
import QtQuick.Layouts
import Quickshell

PanelWindow {
    id: sidebar
    anchors { left: true; top: true; bottom: true }
    margins.top: Theme.headerHeight
    implicitWidth: Theme.frame.sidebarWidth
    exclusionMode: ExclusionMode.Ignore     // placed explicitly; see Theme.qml
    exclusiveZone: 0
    color: Theme.color.background

    readonly property int pad: Theme.frame.padding
    readonly property int gap: Theme.frame.gap

    ColumnLayout {
        anchors { fill: parent; leftMargin: sidebar.pad; topMargin: sidebar.pad; bottomMargin: sidebar.pad }
        spacing: sidebar.gap

        // The elbow's vertical part; its top edge lines up with the top bar's arm
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.frame.elbowHeight
            color: Theme.color.orange
            topLeftRadius: Theme.frame.outerRadius
            Text {
                anchors { right: parent.right; bottom: parent.bottom; rightMargin: 10; bottomMargin: 2 }
                text: "LCARS"
                color: Theme.color.textOnColor
                font { family: Theme.font; pixelSize: 26; weight: Theme.fontWeight }
            }
        }

        Repeater {
            model: Menu.segments
            Segment {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.segmentHeight(modelData.size)
                label: modelData.label
                hint: modelData.hint ?? ""
                fill: modelData.color ? Theme.named(modelData.color) : Theme.cycle[(index + 1) % Theme.cycle.length]
                onActivated: Menu.activate(modelData.id)
                onSecondaryActivated: Menu.edit()
            }
        }

        // The filler takes the leftover height, like the blank blocks on real LCARS
        // panels, and doubles as the way into the menu file
        Segment {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Theme.frame.segmentHeight
            label: "Edit menu"
            hint: "Super+F3"
            fill: Theme.color.lavender
            onActivated: Menu.edit()
            onSecondaryActivated: Menu.edit()
        }

        Repeater {
            model: Menu.footer
            Segment {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.frame.segmentHeight
                label: modelData.label
                hint: modelData.hint ?? ""
                fill: Theme.named(modelData.color ?? "orange")
                onActivated: Menu.activate(modelData.id)
            }
        }

        // Rounded foot: the lower elbow that curves into the bottom rule
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.frame.footHeight + 18
            color: Theme.color.orange
            bottomLeftRadius: Theme.frame.headerRadius
        }
    }
}
