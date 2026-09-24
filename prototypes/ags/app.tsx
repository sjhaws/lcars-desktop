// Phase 1 bake-off: minimal LCARS top bar in AGS v2 / Astal (GTK 4).
// Run in the VM:  ags run ~/lcars-desktop/prototypes/ags/app.tsx
import app from "ags/gtk4/app"
import { Astal, Gtk, Gdk } from "ags/gtk4"
import { createBinding } from "ags"
import { createPoll } from "ags/time"
import Hyprland from "gi://AstalHyprland"
import Wp from "gi://AstalWp"

// AGS bundles the app, so the palette is imported (read at bundle time on every `ags run`)
import tokens from "../../tokens/palette.json"
const c = tokens.color

// Colors come from tokens/palette.json; the stylesheet is generated here
const css = `
window.lcars { background: ${c.background}; font-family: "${tokens.font.family}"; font-weight: ${tokens.font.weight}; }
.elbow { background: ${c.orange}; border-top-left-radius: 28px; min-width: 180px; min-height: 56px; }
.elbow .inner { background: ${c.background}; border-top-left-radius: 18px; min-height: 28px; margin-left: 60px; }
.elbow label { color: ${c.textOnColor}; font-size: 22px; margin-left: 64px; }
.pill { min-height: 28px; min-width: 64px; padding: 0 10px; border-radius: 0; border: none; box-shadow: none;
        color: ${c.textOnColor}; font-size: 18px; background: ${c.peach}; }
.pill label { color: ${c.textOnColor}; }
.pill.ws { min-width: 56px; background: ${c.periwinkle}; }
.pill.ws.focused { background: ${c.orange}; }
.pill.cap-right { border-top-right-radius: 14px; border-bottom-right-radius: 14px; }
.pill.muted { background: ${c.red}; }
.pill.sound { background: ${c.orange}; }
.filler { background: ${c.lavender}; min-height: 28px; }
`

function stardate(d: Date) {
  const start = new Date(d.getFullYear(), 0, 1).getTime()
  const end = new Date(d.getFullYear() + 1, 0, 1).getTime()
  return ((d.getFullYear() - 1946) * 1000 + (1000 * (d.getTime() - start)) / (end - start)).toFixed(1)
}

function Bar(monitor: Gdk.Monitor) {
  const hypr = Hyprland.get_default()
  const focused = createBinding(hypr, "focusedWorkspace")
  const now = createPoll(new Date(), 1000, () => new Date())
  const speaker = Wp.get_default()!.audio.defaultSpeaker
  const muted = createBinding(speaker, "mute")
  const { TOP, LEFT, RIGHT } = Astal.WindowAnchor

  return (
    <window visible class="lcars" gdkmonitor={monitor} anchor={TOP | LEFT | RIGHT}
            exclusivity={Astal.Exclusivity.EXCLUSIVE} application={app} heightRequest={64}>
      <box marginTop={8} marginStart={8} marginEnd={8} spacing={6} valign={Gtk.Align.START}>
        <box class="elbow" orientation={Gtk.Orientation.VERTICAL}>
          <label halign={Gtk.Align.START} label={now((d) => `LCARS ${d.toTimeString().slice(0, 5)}`)} />
          <box class="inner" vexpand />
        </box>
        <box spacing={6} valign={Gtk.Align.START} hexpand>
          {[1, 2, 3, 4, 5].map((ws) => (
            <button class={focused((f) => (f?.id === ws ? "pill ws focused" : "pill ws"))}
                    onClicked={() => hypr.dispatch("workspace", String(ws))}>
              <label halign={Gtk.Align.END} valign={Gtk.Align.END} label={String(ws)} />
            </button>
          ))}
          <box class="filler" hexpand />
          <button class="pill">
            <label label={now((d) => `STARDATE ${stardate(d)}`)} />
          </button>
          <button class={muted((m) => (m ? "pill muted cap-right" : "pill sound cap-right"))}
                  onClicked={() => speaker.set_mute(!speaker.mute)}>
            <label label={muted((m) => (m ? "SOUND OFF" : "SOUND ON"))} />
          </button>
        </box>
      </box>
    </window>
  )
}

app.start({
  css,
  main() {
    app.get_monitors().map(Bar)
  },
})
