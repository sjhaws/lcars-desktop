// LCARS shell (Phase 3): a left sidebar curving into a top bar on every screen.
// Started by hypr/autostart.conf:  quickshell -p <repo>/shell
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root
    // Compact mode swaps the frame for a thin line
    readonly property bool frameShown: !Settings.compact
    readonly property bool lineShown: Settings.compact

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            LazyLoader {
                active: root.frameShown
                Frame { screen: perScreen.modelData }
            }
            LazyLoader {
                active: root.lineShown
                CompactBar { screen: perScreen.modelData }
            }
        }
    }

    Launcher { id: launcher }
    Notifications {}
    Connections {
        target: Menu
        function onLauncherRequested() { launcher.toggle() }
    }

    // Keyboard parity: `quickshell -p <shell> ipc call menu activate custom1`,
    // `... ipc call launcher toggle`
    IpcHandler {
        target: "menu"
        function activate(id: string): void { Menu.activate(id) }
        function edit(): void { Menu.edit() }
    }
    IpcHandler {
        target: "frame"
        function toggleCompact(): void { Sounds.play("open"); Settings.toggleCompact() }
    }
    // Tell Hyprland how much of each screen edge the frame (or the compact line)
    // occupies, and use tighter window gaps in compact mode. If the shell isn't
    // running, nothing is reserved and apps simply get the whole screen.
    Connections {
        target: Settings
        function onCompactChanged() { root.applyLayout() }
        function onLoadedChanged() { root.applyLayout() }
    }
    Component.onCompleted: applyLayout()
    // A config reload (e.g. after editing hypr/*.conf) resets runtime settings
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") root.applyLayout() }
    }
    function applyLayout() {
        const c = Settings.compact
        const top = c ? Theme.frame.compactHeight : Theme.headerHeight + Theme.readoutHeight
        const bottom = c ? 0 : Theme.bottomHeight
        const left = c ? 0 : Theme.frame.sidebarWidth
        const gIn = c ? Theme.frame.compactGapsIn : Theme.tokens.shape.gapsIn
        const gOut = c ? Theme.frame.compactGapsOut : Theme.tokens.shape.gapsOut
        Quickshell.execDetached(["hyprctl", "--batch",
            `keyword monitor ,addreserved,${top},${bottom},${left},0 ; ` +
            `keyword general:gaps_in ${gIn} ; keyword general:gaps_out ${gOut}`])
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { launcher.toggle() }
    }
}
