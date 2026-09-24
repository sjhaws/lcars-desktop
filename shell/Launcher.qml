// LCARS app launcher (Super+Space or the APPS segment): type to filter,
// Up/Down to choose, Enter to launch, Esc or a click outside to close.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: launcher
    property bool open: false
    function toggle() { open = !open }

    PanelWindow {
        id: win
        visible: launcher.open
        // Open on the monitor that has focus
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "#99000000"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "lcars-launcher"

        onVisibleChanged: if (visible) {
            search.text = ""; list.currentIndex = 0; search.forceActiveFocus()
            Sounds.play("open")
        }

        // Click outside the panel closes it
        MouseArea { anchors.fill: parent; onClicked: launcher.open = false }

        readonly property var apps: {
            const q = search.text.trim().toLowerCase()
            const all = DesktopEntries.applications.values.filter(a => !a.noDisplay)
            const score = a => {
                const n = (a.name ?? "").toLowerCase()
                if (!q) return 1
                if (n.startsWith(q)) return 3
                if (n.includes(q)) return 2
                const extra = [a.genericName, a.comment, ...(a.keywords ?? [])].join(" ").toLowerCase()
                return extra.includes(q) ? 1 : 0
            }
            return all.map(a => ({ app: a, s: score(a) })).filter(x => x.s > 0)
                .sort((x, y) => y.s - x.s || x.app.name.localeCompare(y.app.name))
                .map(x => x.app)
        }
        function launch(app) {
            if (!app) { Sounds.play("error"); return }
            Sounds.play("confirm")
            app.execute()
            launcher.open = false
        }

        // The panel: an LCARS elbow header, the search line, then the app list
        Item {
            id: panel
            width: Math.min(640, parent.width - 80)
            height: Math.min(560, parent.height - 80)
            anchors.centerIn: parent
            MouseArea { anchors.fill: parent }    // clicks inside don't close

            Rectangle { anchors.fill: parent; color: Theme.color.background; radius: 4 }

            // Elbow: top bar curving into a left column
            Rectangle {
                id: head
                x: 0; y: 0; width: parent.width; height: 44
                color: Theme.color.orange
                topLeftRadius: 30; topRightRadius: 22; bottomRightRadius: 22
                Text {
                    anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                    text: "APPLICATIONS"
                    color: Theme.color.textOnColor
                    font { family: Theme.font; pixelSize: 26; weight: Theme.fontWeight }
                }
            }
            Rectangle {
                id: column
                x: 0; y: head.height - 1; width: 70; height: parent.height - head.height + 1
                color: Theme.color.orange
                bottomLeftRadius: 30
                Rectangle {   // concave inner corner
                    x: parent.width; y: 0; width: 16; height: 16
                    color: Theme.color.orange
                    Rectangle { anchors.fill: parent; color: Theme.color.background; topLeftRadius: 16 }
                }
                Text {
                    anchors { right: parent.right; rightMargin: 8; bottom: parent.bottom; bottomMargin: 8 }
                    text: win.apps.length
                    color: Theme.color.textOnColor
                    font { family: Theme.font; pixelSize: 22; weight: Theme.fontWeight }
                }
            }

            ColumnLayout {
                anchors { left: column.right; right: parent.right; top: head.bottom; bottom: parent.bottom; margins: 12 }
                spacing: 8

                // Search line
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: "transparent"
                    border { width: 2; color: Theme.color.peach }
                    radius: 20
                    TextInput {
                        id: search
                        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                        verticalAlignment: TextInput.AlignVCenter
                        color: Theme.color.textOnBlack
                        font { family: Theme.font; pixelSize: 22; weight: Theme.fontWeight; capitalization: Font.AllUppercase }
                        focus: true
                        onTextChanged: list.currentIndex = 0
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) { launcher.open = false; event.accepted = true }
                            else if (event.key === Qt.Key_Down) { list.incrementCurrentIndex(); event.accepted = true }
                            else if (event.key === Qt.Key_Up) { list.decrementCurrentIndex(); event.accepted = true }
                            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                win.launch(win.apps[list.currentIndex]); event.accepted = true
                            }
                        }
                    }
                    Text {
                        visible: search.text.length === 0
                        anchors { left: parent.left; leftMargin: 18; verticalCenter: parent.verticalCenter }
                        text: "TYPE TO SEARCH"
                        color: Theme.color.lavender
                        font { family: Theme.font; pixelSize: 22; weight: Theme.fontWeight }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: win.apps
                    highlightMoveDuration: 0
                    delegate: Segment {
                        sound: ""        // launch() plays "confirm"
                        required property var modelData
                        required property int index
                        width: list.width
                        height: 40
                        label: modelData.name
                        hint: modelData.genericName && modelData.genericName !== modelData.name ? modelData.genericName : ""
                        fill: ListView.isCurrentItem ? Theme.color.orange : Theme.cycle[(index % 3) + 1]
                        onActivated: win.launch(modelData)
                    }
                }
            }
        }
    }
}
