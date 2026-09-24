// The full LCARS frame for one screen: header, sidebar, bottom rule, readout bar.
// Each panel has a fixed position (Theme.qml); shell.qml reserves the space.
import QtQuick
import Quickshell

Scope {
    id: frame
    required property var screen
    Header { screen: frame.screen }
    Sidebar { screen: frame.screen }
    BottomBar { screen: frame.screen }
    TopBar { screen: frame.screen }
}
