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

    // Frame geometry. Every panel is placed at a fixed position from these numbers
    // and invisible Reserver panels keep that space free for windows (shell.qml), so
    // the layout never depends on the order in which the panels appear.
    readonly property int headerHeight: frame.padding + frame.headerTitle + frame.gap + frame.headerArm
    readonly property int readoutHeight: frame.padding + frame.armHeight + frame.innerRadius
    readonly property int bottomHeight: frame.padding + frame.footHeight + frame.innerRadius

    // Segment colors cycle through the palette, LCARS style
    readonly property var cycle: [color.orange, color.peach, color.lavender, color.periwinkle]
    function named(name) { return color[name] ?? color.orange }
    // Sidebar segment heights: LCARS panels mix short and tall blocks
    function segmentHeight(size) {
        return size === "short" ? frame.segmentShort : size === "tall" ? frame.segmentTall : frame.segmentHeight
    }
}
