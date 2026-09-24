# LCARS keybindings and sidebar

`Super` is the Windows key. Every window tiles automatically; there is no desktop to drag windows around on.

| Keys | Action |
| --- | --- |
| `Super+Shift+Esc` | **Exit to the login screen** (escape route 1) |
| `Super+Return` | Terminal |
| `Super+Space` | App launcher (type to search, Enter to open, Esc to close) |
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
| `` Super+` `` | Previous workspace |
| `Super+S` / `Super+Shift+S` | Show / send to the scratch workspace |
| `Print` / `Shift+Print` | Screenshot of a region / whole screen → `~/Pictures/Screenshots` and clipboard |
| Volume, mute, brightness, media keys | Work as labelled |
| `Super`+drag with left / right mouse button | Move / resize a window |
| Three-finger swipe (touchpad) | Switch workspace |

## The sidebar

Every sidebar segment is a button: Terminal, Browser, Files, Editor, Monitor, Settings,
two custom buttons, Apps (the launcher) and Exit. The top bar's numbers switch
workspaces and SOUND ON/OFF mutes.

**Custom buttons:** click an unset CUSTOM button. It opens your own copy of the menu
(`~/.config/lcars/menu.json`) in Text Editor. Give it a `label` and a `command`, save,
and the sidebar updates within two seconds. You can relabel, recolor or reorder any
segment the same way. `lcars-rollback` keeps this file (it moves it to `~/lcars-backups`).

Not yet: lock screen (Phase 4); notifications and launcher are still stopgaps (mako,
fuzzel) styled from the palette.
