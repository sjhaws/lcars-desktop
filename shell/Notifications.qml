// Notification server and LCARS popups (top right, below the top bar).
// Popups expire after the sender's timeout (default 8 s); critical ones stay
// until clicked. Clicking runs the default action, if any, then dismisses.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland

Scope {
    id: root

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        imageSupported: false
        keepOnReload: false
        onNotification: n => { n.tracked = true }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: server.trackedNotifications.values.length > 0
        anchors { top: true; right: true }
        margins { top: Theme.frame.gap * 2; right: Theme.frame.padding }
        implicitWidth: 400
        implicitHeight: stack.implicitHeight
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "lcars-notifications"

        ColumnLayout {
            id: stack
            width: parent.width
            spacing: Theme.frame.gap * 2

            Repeater {
                model: server.trackedNotifications
                delegate: Item {
                    id: card
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool critical: n.urgency === NotificationUrgency.Critical
                    readonly property color accent: critical ? Theme.color.red
                        : n.urgency === NotificationUrgency.Low ? Theme.color.periwinkle : Theme.color.orange
                    Layout.fillWidth: true
                    implicitHeight: Math.max(64, body.implicitHeight + 16)

                    Timer {
                        // expireTimeout is in seconds; <= 0 means "server decides"
                        running: !card.critical
                        interval: card.n.expireTimeout > 0 ? card.n.expireTimeout * 1000 : 8000
                        onTriggered: card.n.expire()
                    }

                    Rectangle { anchors.fill: parent; color: Theme.color.background }
                    // LCARS left cap in the urgency color, with the app name
                    Rectangle {
                        id: cap
                        width: 90; height: parent.height
                        color: card.accent
                        topLeftRadius: 24; bottomLeftRadius: 24
                        Text {
                            anchors { right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 4 }
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideLeft
                            text: (card.n.appName || "SYSTEM").toUpperCase()
                            color: Theme.color.textOnColor
                            font { family: Theme.font; pixelSize: 14; weight: Theme.fontWeight }
                        }
                    }
                    Rectangle {   // thin bar along the top, like an LCARS readout
                        anchors { left: cap.right; right: parent.right; top: parent.top; leftMargin: Theme.frame.gap }
                        height: 6
                        color: card.accent
                        topRightRadius: 3; bottomRightRadius: 3
                    }
                    ColumnLayout {
                        id: body
                        anchors { left: cap.right; right: parent.right; top: parent.top; leftMargin: 12; rightMargin: 8; topMargin: 12 }
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: card.n.summary.toUpperCase()
                            color: card.accent
                            elide: Text.ElideRight
                            font { family: Theme.font; pixelSize: 20; weight: Theme.fontWeight }
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: card.n.body
                            textFormat: Text.PlainText
                            wrapMode: Text.Wrap
                            maximumLineCount: 4
                            elide: Text.ElideRight
                            color: Theme.color.textOnBlack
                            font { family: Theme.font; pixelSize: 16 }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const def = card.n.actions.find(a => a.identifier === "default")
                            if (def) def.invoke()
                            card.n.dismiss()
                        }
                    }
                }
            }
        }
    }
}
