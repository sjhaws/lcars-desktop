// One LCARS button: a colored block with its label in the bottom-right corner.
import QtQuick
import Quickshell

Rectangle {
    id: seg
    property string label: ""
    property string hint: ""
    property color fill: Theme.color.orange
    property bool centerLabel: false      // pills center their label
    property string sound: "beep"         // "" for silent blocks
    readonly property real labelWidth: text.implicitWidth
    // Short blocks show only the label
    readonly property bool showHint: hint.length > 0 && height >= 44
    signal activated()
    signal secondaryActivated()     // right-click
    signal scrolled(real delta)

    color: area.pressed ? Qt.lighter(fill, 1.35) : area.containsMouse ? Qt.lighter(fill, 1.15) : fill
    Behavior on color { ColorAnimation { duration: 80 } }

    Text {
        id: text
        anchors.right: seg.centerLabel ? undefined : parent.right
        anchors.bottom: seg.centerLabel ? undefined : parent.bottom
        anchors.centerIn: seg.centerLabel ? parent : undefined
        anchors.rightMargin: 10
        anchors.bottomMargin: seg.showHint ? 16 : 2
        text: seg.label.toUpperCase()
        color: Theme.color.textOnColor
        font { family: Theme.font; pixelSize: 20; weight: Theme.fontWeight }
    }
    Text {
        visible: seg.showHint
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 10; bottomMargin: 2 }
        text: seg.hint.toUpperCase()
        color: Theme.color.textOnColor
        opacity: 0.7
        font { family: Theme.font; pixelSize: 12; weight: Theme.fontWeight }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (seg.sound) Sounds.play(seg.sound)
            mouse.button === Qt.RightButton ? seg.secondaryActivated() : seg.activated()
        }
        onWheel: wheel => seg.scrolled(wheel.angleDelta.y)
    }
}
