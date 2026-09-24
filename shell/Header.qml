// Header panel: the upper half of the LCARS split frame. A lavender elbow with a
// station code, the focused app's name as the title, stardate and time, a LOCK pill,
// and a thin arm running into mixed-width divider rules.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: header
    anchors { top: true; left: true; right: true }
    readonly property int pad: Theme.frame.padding
    readonly property int gap: Theme.frame.gap
    readonly property int titleH: Theme.frame.headerTitle
    readonly property int armH: Theme.frame.headerArm
    readonly property int side: Theme.frame.sidebarWidth
    readonly property int inner: Theme.frame.innerRadius
    implicitHeight: Theme.headerHeight
    exclusionMode: ExclusionMode.Ignore     // placed explicitly; see Theme.qml
    exclusiveZone: 0
    color: Theme.color.background

    SystemClock { id: clock; precision: SystemClock.Seconds }
    function stardate(d) {
        const start = new Date(d.getFullYear(), 0, 1)
        const end = new Date(d.getFullYear() + 1, 0, 1)
        return ((d.getFullYear() - 1946) * 1000 + 1000 * (d - start) / (end - start)).toFixed(1)
    }

    // A stable three-digit station code from the machine's name, like "LCARS 105"
    FileView { id: hostnameFile; path: "/etc/hostname"; blockLoading: true }
    readonly property string stationCode: {
        const h = hostnameFile.text().trim() || "lcars"
        let n = 0
        for (let i = 0; i < h.length; i++) n = (n * 31 + h.charCodeAt(i)) % 1000
        return "LCARS " + String(n).padStart(3, "0")
    }
    // Title: the focused app's name, e.g. "org.gnome.Nautilus" -> "FILES"
    readonly property string title: {
        const w = ToplevelManager.activeToplevel
        const cls = w?.activated ? (w.appId ?? "") : ""
        if (!cls) return "MAIN DISPLAY"
        // Prefer the app's own display name ("Files"), as the launcher shows it
        const entry = DesktopEntries.byId(cls)
            ?? DesktopEntries.applications.values.find(e => e.id.toLowerCase() === cls.toLowerCase())
        if (entry?.name) return entry.name
        const parts = cls.split(".")
        return parts[parts.length - 1].replace(/[-_]/g, " ")
    }

    // Upper elbow: rounded at the bottom left, opening up and to the right
    Rectangle {
        id: block
        x: header.pad; y: header.pad
        width: header.side - header.pad
        height: header.titleH + header.gap + header.armH
        color: Theme.color.lavender
        bottomLeftRadius: Theme.frame.headerRadius
        Text {
            anchors { right: parent.right; top: parent.top; rightMargin: 10; topMargin: 2 }
            text: header.stationCode
            color: Theme.color.textOnColor
            font { family: Theme.font; pixelSize: 16; weight: Theme.fontWeight }
        }
    }
    // Concave corner above the arm, where it leaves the block
    Rectangle {
        x: header.side; y: header.pad + header.titleH + header.gap - header.inner
        width: header.inner; height: header.inner
        color: Theme.color.lavender
        Rectangle { anchors.fill: parent; color: Theme.color.background; bottomLeftRadius: header.inner }
    }

    // Arm and divider rules along the bottom
    RowLayout {
        id: rules
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  leftMargin: header.side; rightMargin: header.pad }
        height: header.armH
        spacing: header.gap
        Repeater {
            // widths are fractions of the row; w: 0 takes what's left
            model: [
                { w: 0.22, c: "lavender" }, { w: 0.04, c: "orange" }, { w: 0.12, c: "peach" },
                { w: 0.02, c: "red" }, { w: 0, c: "lavender" }, { w: 0.05, c: "orange" },
                { w: 0.14, c: "periwinkle" }, { w: 0.03, c: "peach" }
            ]
            Rectangle {
                required property var modelData
                required property int index
                Layout.fillHeight: true
                Layout.fillWidth: modelData.w === 0
                Layout.preferredWidth: modelData.w * rules.width
                // the first rule is the arm itself, flush with the block
                Layout.leftMargin: index === 0 ? -header.gap : 0
                color: Theme.named(modelData.c)
            }
        }
    }

    // Title row
    RowLayout {
        anchors { left: parent.left; right: parent.right; top: parent.top
                  leftMargin: header.side + 16; rightMargin: header.pad; topMargin: header.pad }
        height: header.titleH
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: header.title.toUpperCase()
            elide: Text.ElideRight
            color: Theme.color.orange
            font { family: Theme.font; pixelSize: 34; weight: Theme.fontWeight }
        }
        Text {
            text: "STARDATE " + header.stardate(clock.date) + "  " + Qt.formatDateTime(clock.date, "HH:mm:ss")
            color: Theme.color.periwinkle
            font { family: Theme.font; pixelSize: 28; weight: Theme.fontWeight }
        }
        Segment {   // fold the frame into a thin line (Super+F11)
            Layout.preferredWidth: 110
            Layout.preferredHeight: 34
            label: "Compact"
            fill: Theme.color.periwinkle
            radius: height / 2
            centerLabel: true
            sound: "open"
            onActivated: Settings.toggleCompact()
        }
        Segment {   // interface sounds on/off (not the system volume)
            Layout.preferredWidth: 110
            Layout.preferredHeight: 34
            label: Settings.sounds ? "SFX on" : "SFX off"
            fill: Settings.sounds ? Theme.color.orange : Theme.color.lavender
            radius: height / 2
            centerLabel: true
            sound: ""
            onActivated: { Settings.toggleSounds(); if (Settings.sounds) Sounds.play("confirm") }
        }
        Segment {   // LOCK pill, like LCARS "LOGOUT"
            Layout.preferredWidth: 110
            Layout.preferredHeight: 34
            label: "Lock"
            fill: Theme.color.red
            radius: height / 2
            centerLabel: true
            onActivated: Quickshell.execDetached(["loginctl", "lock-session"])
        }
    }
}
