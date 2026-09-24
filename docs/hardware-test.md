# Real-hardware test (laptop + ThinkPad USB-C Dock Gen 2)

LCARS is installed **next to** Ubuntu. The Ubuntu session stays untouched and remains the
default whenever you pick it at the login screen. Everything below is undone by
`lcars-rollback --purge`, and `install.sh` takes a Timeshift snapshot first.

## Before you start

- Save your work. Logging out closes all apps, including the Claude app; reopen it afterwards
  and continue this session.
- Laptop on the charger and docked (laptop screen + both monitors).
- Keep this page open on your phone, or print the "If something goes wrong" section.

## 1. Install (≈ 10–15 minutes, you type your password)

```bash
cd ~/lcars-desktop && ./install.sh --deploy
```

It takes a Timeshift snapshot, backs up `~/.config`, installs packages, builds Quickshell
(a few minutes), and adds "LCARS" to the login screen.

## 2. Docked

Log out → click your name → gear ⚙ → **LCARS** → log in.

- [ ] The frame appears on **all three** screens within ~10 s; note which screen is which
- [ ] Top readouts: CPU, MEM, NET, **BAT** (battery), VOL; stardate and clock tick
- [ ] `Super+Return` opens a terminal; `Super+Space` opens the launcher (works on real hardware)
- [ ] Open Firefox from the launcher, play a video: smooth? sound?
- [ ] SFX chirps audible when clicking sidebar buttons; volume keys change VOL
- [ ] Move a window between screens (`Super+Shift+←/→`), focus screens (`Super+,` / `Super+.`)
- [ ] `Super+F11` compact mode and back
- [ ] `Super+L` locks all screens; your password unlocks
- [ ] Suspend: in a terminal run `systemctl suspend`, wait 10 s, wake with a key. Do all screens
  come back? Is it locked? Does it unlock?
- [ ] **Unplug the dock** while logged in: does the laptop screen keep working?
- [ ] Click **EXIT**: back at the login screen

## 3. Undocked

Dock unplugged, at the login screen: log into LCARS again.

- [ ] Frame on the laptop screen; BAT readout; brightness keys
- [ ] **Plug the dock in** while logged in. (Expected with the current design: the dock screens
  stay dark until you log out and back in, because LCARS renders on the Intel GPU only when
  it starts undocked, to save battery.) Note what actually happens
- [ ] Click **EXIT**

## 4. Back in Ubuntu

Log into **Ubuntu** (gear ⚙ → Ubuntu), then run:

```bash
~/lcars-desktop/bin/lcars-report
```

and tell Claude the file name it prints. Notes on anything odd (flicker, slowness, colors,
wrong screen order) help too.

## If something goes wrong

| Situation | Do this |
| --- | --- |
| Anything odd, but it responds | `Super+Shift+Esc` (or EXIT) → login screen → gear → **Ubuntu** |
| LCARS keeps crashing | After 3 crashes it starts Ubuntu by itself |
| Frozen screen | Wait ~45 s: it restarts itself. Or hold the power button, then pick Ubuntu |
| Black screen | `Ctrl+Alt+F3`, log in, run `lcars-rollback`, then `sudo reboot` |
| Stop LCARS without removing it | In Ubuntu or a console: `touch ~/.lcars-off` |
| Remove it completely | `lcars-rollback --purge` |
| System damaged | Restore the Timeshift snapshot "Before LCARS install …" (or the live USB) |
