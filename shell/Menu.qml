// Sidebar menu. Defaults come from shell/menu.json; if ~/.config/lcars/menu.json
// exists it is used instead, and edits to it apply as soon as the file is saved.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: menu
    readonly property string userFile: Quickshell.env("HOME") + "/.config/lcars/menu.json"
    readonly property string customizeScript: Quickshell.shellDir + "/customize-menu"

    FileView {
        id: defaults
        path: Quickshell.shellDir + "/menu.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    // The user file is polled rather than watched: it may not exist yet when the
    // shell starts, and editors save by replacing the file, which breaks a watch.
    // userText only changes (and the sidebar only rebuilds) when the content does.
    property string userText: ""
    FileView {
        id: user
        path: menu.userFile
        blockLoading: true
        printErrors: false
        onLoaded: menu.userText = text()
        onLoadFailed: menu.userText = ""
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: user.reload()
    }

    function parse(text) {
        try { return JSON.parse(text) } catch (e) { return null }
    }
    // A broken user file falls back to the defaults instead of an empty sidebar
    readonly property var userConfig: parse(userText)
    readonly property var config: userConfig?.segments ? userConfig : parse(defaults.text())
    readonly property var segments: config?.segments ?? []
    readonly property var footer: config?.footer ?? []

    function find(id) {
        return segments.concat(footer).find(s => s.id === id)
    }
    function activate(id) {
        const s = find(id)
        if (!s) return
        // An unset custom button opens the menu file so it can be set
        const cmd = s.command && s.command.length ? s.command : customizeScript
        Quickshell.execDetached(["sh", "-c", cmd])
    }
}
