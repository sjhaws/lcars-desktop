// Interface sounds: original chirps from tools/lcars-sounds, played with pw-play.
// Muted by the SFX pill in the header (Settings.sounds); system volume applies too.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string dir: Quickshell.shellDir + "/../sounds/generated/"
    function play(name) {
        if (!Settings.sounds || !name) return
        Quickshell.execDetached(["pw-play", "--volume", "0.6", dir + name + ".wav"])
    }
}
