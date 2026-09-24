// Invisible panel that keeps an edge of one screen free for the LCARS frame.
// The visible panels ignore reserved space and sit at fixed positions; these do
// the reserving. Reserved space adds up the same whatever order they appear in,
// which the visible panels' own layout would not.
// (Hyprland's "monitor ...,addreserved" was tried first: in 0.53 it replaces the
// monitor's whole rule, resetting resolution and position.)
import QtQuick
import Quickshell

PanelWindow {
    id: reserver
    property string edge: "top"          // top, left or bottom
    property int size: 0
    anchors {
        top: edge !== "bottom"
        bottom: edge !== "top"
        left: true
        right: edge !== "left"
    }
    implicitWidth: 1
    implicitHeight: 1
    exclusiveZone: size
    color: "transparent"
    mask: Region {}                      // clicks pass through
}
