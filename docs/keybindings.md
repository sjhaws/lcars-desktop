# LCARS keybindings and sidebar

`Super` is the Windows key. Every window tiles automatically; there is no desktop to drag windows around on.

| Keys | Action |
| --- | --- |
| `Super+Shift+Esc` | **Exit to the login screen** (escape route 1) |
| `Super+Return` | Terminal |
| `Super+Space` | LCARS app launcher: type to search, ↑/↓ to choose, Enter to open, Esc to close |
| `Super+B` / `Super+E` | Web browser / Files |
| `Super+F1` / `Super+F2` | The sidebar's two custom buttons |
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
| `Super+S` / `Super+Shift+S` | Show / send to the scratch workspace |
| `Print` / `Shift+Print` | Screenshot of a region / whole screen → `~/Pictures/Screenshots` and clipboard |
| Volume, mute, brightness, media keys | Work as labelled |
| `Super`+drag with left / right mouse button | Move / resize a window |
| Three-finger swipe (touchpad) | Switch workspace |

## The sidebar

Every sidebar segment is a button: Terminal, Browser, Files, Editor, Monitor, Settings,
two custom buttons, Apps (the launcher) and Exit.

The top bar's numbers switch workspaces (more appear when you use workspaces above 5).
Its readouts show CPU, memory, network (WIFI / WIRED / VPN / OFFLINE, red when offline),
battery on laptops (`+` while charging, red at 15 % or less on battery), stardate and time.
The VOL block mutes on click and changes volume with the scroll wheel.

Notifications appear top right: red cap = critical (stays until clicked), orange = normal,
periwinkle = low. Click one to open it (if the app offers that) and dismiss it.

**Custom buttons:** click an unset CUSTOM button. It opens your own copy of the menu
(`~/.config/lcars/menu.json`) in Text Editor. Give it a `label` and a `command`, save,
and the sidebar updates within two seconds. You can relabel, recolor or reorder any
segment the same way. `lcars-rollback` keeps this file (it moves it to `~/lcars-backups`).

If the frame ever fails to start, a red notice appears at the top of the screen; the
keyboard shortcuts above keep working. Details are in `~/.local/state/lcars/shell.log`.

Not yet: lock screen, idle dimming and sounds (Phase 4).
