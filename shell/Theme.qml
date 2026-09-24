// Colors, font and frame sizes, read live from tokens/palette.json.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    FileView {
        id: tokensFile
        path: Quickshell.shellDir + "/../tokens/palette.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var tokens: JSON.parse(tokensFile.text())
    readonly property var color: tokens.color
    readonly property var frame: tokens.frame
    readonly property string font: tokens.font.family
    readonly property int fontWeight: tokens.font.weight

    // Segment colors cycle through the palette, LCARS style
    readonly property var cycle: [color.orange, color.peach, color.lavender, color.periwinkle]
    function named(name) { return color[name] ?? color.orange }
}
