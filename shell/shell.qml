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
            // Order matters: the sidebar reserves the left edge first, so the
            // top bar is placed to its right and the sidebar keeps full height
            Sidebar { screen: perScreen.modelData }
            TopBar { screen: perScreen.modelData }
        }
    }

    // Keyboard parity for the menu: `quickshell -p <shell> ipc call menu activate custom1`
    IpcHandler {
        target: "menu"
        function activate(id: string): void { Menu.activate(id) }
    }
}
