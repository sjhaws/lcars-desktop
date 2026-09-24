// Your LCARS preferences, kept in ~/.config/lcars/settings.json (user data:
// lcars-rollback moves it to ~/lcars-backups instead of deleting it).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: settings
    readonly property string file: Quickshell.env("HOME") + "/.config/lcars/settings.json"

    property bool sounds: true          // interface chirps (on by default)

    FileView {
        id: view
        path: settings.file
        blockLoading: true
        printErrors: false
        onLoaded: {
            try { settings.sounds = JSON.parse(text()).sounds ?? true } catch (e) {}
        }
    }
    function save() {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.config/lcars"])
        saveTimer.restart()
    }
    // Written a moment later so the directory exists
    Timer {
        id: saveTimer
        interval: 200
        onTriggered: view.setText(JSON.stringify({ sounds: settings.sounds }, null, 2) + "\n")
    }
    function toggleSounds() { sounds = !sounds; save() }
}
