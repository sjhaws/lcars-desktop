// One LCARS button: a colored block with its label in the bottom-right corner.
import QtQuick
import Quickshell

Rectangle {
    id: seg
    property string label: ""
    property string hint: ""
    property color fill: Theme.color.orange
    readonly property real labelWidth: text.implicitWidth
    signal activated()
    signal secondaryActivated()     // right-click
    signal scrolled(real delta)

    color: area.pressed ? Qt.lighter(fill, 1.35) : area.containsMouse ? Qt.lighter(fill, 1.15) : fill
    Behavior on color { ColorAnimation { duration: 80 } }

    Text {
        id: text
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 10; bottomMargin: seg.hint ? 16 : 2 }
        text: seg.label.toUpperCase()
        color: Theme.color.textOnColor
        font { family: Theme.font; pixelSize: 20; weight: Theme.fontWeight }
    }
    Text {
        visible: seg.hint.length > 0
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
        onClicked: mouse => mouse.button === Qt.RightButton ? seg.secondaryActivated() : seg.activated()
        onWheel: wheel => seg.scrolled(wheel.angleDelta.y)
    }
}
