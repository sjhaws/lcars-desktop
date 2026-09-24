// LCARS shell (Phase 3): a left sidebar curving into a top bar on every screen.
// Started by hypr/autostart.conf:  quickshell -p <repo>/shell
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            // Order matters: the header reserves the top edge first, then the
            // sidebar the left edge below it; the bottom rule and the readout bar
            // go to the sidebar's right
            Header { screen: perScreen.modelData }
            Sidebar { screen: perScreen.modelData }
            BottomBar { screen: perScreen.modelData }
            TopBar { screen: perScreen.modelData }
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
        target: "launcher"
        function toggle(): void { launcher.toggle() }
    }
}
