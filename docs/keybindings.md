# LCARS keybindings and sidebar

`Super` is the Windows key. Every window tiles automatically; there is no desktop to drag windows around on.

| Keys | Action |
| --- | --- |
| `Super+Shift+Esc` | **Exit to the login screen** (escape route 1) |
| `Super+L` | Lock the screen (also the LOCK block in the top bar) |
| `Super+Return` | Terminal |
| `Super+Space` | LCARS app launcher: type to search, ↑/↓ to choose, Enter to open, Esc to close |
| `Super+B` / `Super+E` | Web browser / Files |
| `Super+F1` / `Super+F2` | The sidebar's two custom buttons |
| `Super+F3` | Edit the sidebar menu (opens `~/.config/lcars/menu.json`) |
| `Super+F11` | Compact mode: fold the frame into a thin line and give apps the screen; again to unfold |
| `Super+Q` | Close window |
| `Super+←↑→↓` | Move focus |
| `Super+Shift+←↑→↓` | Move window |
| `Super+Ctrl+←↑→↓` | Resize window |
| `Super+F` / `Super+Shift+F` | Fullscreen / maximize (keeps gaps) |
| `Super+V` | Float / unfloat window |
| `Super+J` | Flip split direction |
| `Super+P` | Pseudo-tile (keep the window's own size inside its tile) |
| `Super+G` | Turn windows into a tabbed group (LCARS tabs) / ungroup |
| `Super+Tab` / `Super+Shift+Tab` | Next / previous tab in a group |
| `Super+1…0` | Go to workspace 1–10 |
| `Super+Shift+1…0` | Send window to workspace 1–10 |
| `Super+]` / `Super+[` | Next / previous workspace (also `Super+PgDn/PgUp` and `Super+Alt+→/←`, as in GNOME) |
| `Super+Shift+]` / `Super+Shift+[` | Take the window to the next / previous workspace |
| `` Super+` `` | Back to the last workspace you were on |
| `Super+,` / `Super+.` | Focus the screen to the left / right |
| `Super+Shift+←/→` at a screen's edge | Move the window onto the neighbouring screen |
| `Super+S` / `Super+Shift+S` | Show / send to the scratch workspace |
| `Print` / `Shift+Print` | Screenshot of a region / whole screen → `~/Pictures/Screenshots` and clipboard |
| Volume, mute, brightness, media keys | Work as labelled |
| `Super`+drag with left / right mouse button | Move / resize a window |
| Three-finger swipe (touchpad) | Switch workspace |

## The sidebar

Every sidebar segment is a button: Terminal, Browser, Files, Editor, Monitor, Settings,
two custom buttons, Apps (the launcher) and Exit.

The frame is split like classic LCARS panels: a **header** (lavender elbow with a station code,
the focused app's name, stardate and time, and a LOCK pill), the main frame (orange elbow,
sidebar, readout bar), and a **bottom rule** ending in the machine's IP address.

The readout bar's numbers switch workspaces (more appear when you use workspaces above 5).
Its readouts show CPU, memory, network (WIFI / WIRED / VPN / OFFLINE, red when offline),
battery on laptops (`+` while charging, red at 15 % or less on battery).
The VOL block mutes on click and changes volume with the scroll wheel.

Notifications appear top right: red cap = critical (stays until clicked), orange = normal,
periwinkle = low. Click one to open it (if the app offers that) and dismiss it.

**Custom buttons:** click an unset CUSTOM button, the **EDIT MENU** block, or right-click any
sidebar button (or press `Super+F3`). Each opens your own copy of the menu
(`~/.config/lcars/menu.json`) in Text Editor. Give it a `label` and a `command`, save,
and the sidebar updates within two seconds. You can relabel, recolor or reorder any
segment the same way, and make it `"size": "short"`, `"normal"` or `"tall"` (short blocks show
only the label). `lcars-rollback` keeps this file (it moves it to `~/lcars-backups`).

If the frame ever fails to start, a red notice appears at the top of the screen; the
keyboard shortcuts above keep working. Details are in `~/.local/state/lcars/shell.log`.

## Several screens

Every screen gets its own LCARS frame. With more than one screen, each readout bar shows the
workspaces on *its* screen: orange is the one showing on the screen you're using, peach the
one showing on another screen. Screens can be plugged in or removed at any time.

## Compact mode

`Super+F11`, the **COMPACT** pill in the header, or a click on the thin line toggles it. In
compact mode the frame folds into a 10 px LCARS line at the top and windows get the rest of
the screen with tighter gaps. Everything else keeps working (launcher, notifications, lock,
shortcuts). The choice is remembered across logins.

## App look

Inside LCARS, modern GNOME apps (Files, Settings, Text Editor, Calculator…) run in dark mode
with an orange accent. This is set only for the LCARS session (environment variables), so
the same apps look normal in the Ubuntu session. The choice lives in `tokens/palette.json`
under `apps`.

## Sounds

Buttons chirp, the launcher and launched apps have their own tones, and notifications play an
alert (critical ones an alarm). All sounds are original, synthesized by `tools/lcars-sounds`.
The **SFX ON/OFF** pill in the header turns them off without touching the system volume; the
choice is kept in `~/.config/lcars/settings.json`.

## Lock screen and idle

The screen dims after 5 idle minutes, locks after 10 and turns off after 11. After 30 minutes
the laptop suspends, but only on battery; plugged in or docked it stays awake. It also always
locks before a suspend. Unlock by typing your password ("ENTER ACCESS CODE") and Enter.
The times are in `hypr/hypridle.conf`.

If the lock screen itself ever crashes, the screen stays locked and shows a red message.
From a text console (`Ctrl+Alt+F3`, log in) run `hyprctl --instance 0 dispatch exec hyprlock`,
then switch back with `Ctrl+Alt+F2`.

Not yet: sounds, app themes and multi-monitor polish (Phase 4).
