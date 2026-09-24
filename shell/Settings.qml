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
    property bool compact: false        // frame collapsed to a thin line (Super+F11)
    property bool loaded: false

    FileView {
        id: view
        path: settings.file
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const j = JSON.parse(text())
                settings.sounds = j.sounds ?? true
                settings.compact = j.compact ?? false
            } catch (e) {}
            settings.loaded = true
        }
        onLoadFailed: settings.loaded = true
    }
    function save() {
        Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.config/lcars"])
        saveTimer.restart()
    }
    // Written a moment later so the directory exists
    Timer {
        id: saveTimer
        interval: 200
        onTriggered: view.setText(JSON.stringify({ sounds: settings.sounds, compact: settings.compact }, null, 2) + "\n")
    }
    function toggleSounds() { sounds = !sounds; save() }
    function toggleCompact() { compact = !compact; save() }
}
