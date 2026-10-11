# nothing

A single-pill Quickshell shell for Hyprland, in the spirit of Nothing OS.
Design intent and the rules that follow from it: see INTENT.md.
Everything is coloured from the wallpaper with matugen.

Type: Instrument Serif for hero numbers and headings, Space Mono for
everything else, and a dot-matrix renderer for clocks and weather glyphs
(fonts in ~/.local/share/fonts/nothing, OFL).

## The pill

Resting: `workspaces · clock · weather · now playing · rec · tray · status`.
It grows and shrinks to fit whatever it's showing. The pill is translucent;
Hyprland blurs what's behind it (and behind fuzzel and kitty).

Windows are borderless: the focused one is solid, unfocused ones turn to
frosted glass. Dot-matrix elements can bloom (Settings > Appearance).

| Click / key                         | Opens                                  |
|-------------------------------------|----------------------------------------|
| clock · `Super+A`                   | calendar (scroll = month)              |
| weather chip                        | weather: now, next hours, 3 days       |
| tray grip (dots)                    | slide tray icons out; right-click one for its menu |
| red REC dot                         | stop screen recording                  |
| now playing · `Super+M`             | media controls                         |
| status · `Super+N`                  | sliders, tiles (Wi-Fi, Bluetooth, silent, caffeine, night light, mic), theme, notifications |
| tile chevron                        | Wi-Fi networks / Bluetooth devices     |
| `Ctrl+Super+T`                      | wallpaper picker                       |
| `Ctrl+Super+Alt+T`                  | random wallpaper                       |
| `Ctrl+Super+Shift+D`                | light / dark                           |
| `Ctrl+Alt+Delete`                   | power menu                             |
| `Super+J`                           | hide / show the pill                   |
| Esc, right-click, or click outside  | collapse                               |

Volume/brightness changes and notifications pop up in the pill on their own,
and polkit password prompts show up there too.

## Welcome tour and cheat sheet

The first time the shell starts it shows a short tour (wallpaper, look,
colour, weather, keys). It's stored in `~/.local/state/nothing/onboarded`;
reopen it from Settings > About or with `qs -c nothing ipc call onboarding open`.
`Super + /` (or `ipc call cheatsheet toggle`) shows every bind, grouped and
searchable, read live from Hyprland.

## Launcher (tap `Super`)

Tap Super, Super+V and Super+. run `scripts/launcher.sh`, which uses
[vicinae](https://vicinae.com) when its server is running (started only in the
Hyprland session) and falls back to the pill launcher and fuzzel otherwise.
vicinae is themed by `matugen/templates/vicinae.toml` (hot-reloaded on every
wallpaper change). Its settings live in `apps/vicinae/settings.json`, imported
from `~/.config/vicinae/settings.json`. Keep that file free of comments: vicinae
silently ignores imported files that contain them.

### Pill launcher (fallback)


Lives in the pill and never unloads, so icons are already decoded when it
opens. Empty query shows a grid (most-used first); typing ranks apps by name,
keywords and how often you launch them. `2*21` or `=` + anything (qalculate:
units, currency) calculates, `> cmd` runs a command, and the last row searches
the web. App actions (e.g. "New private window") show on the selected row.
fuzzel is only used if the shell isn't running.

## Desktop widgets

Clock, weather, now playing, calendar, battery ring, system meters and a
sticky note, on the wallpaper below windows. Toggle them and press "Arrange
widgets" in Settings > Widgets (or `qs -c nothing ipc call shell arrange`) to
drag them; positions are saved as screen fractions in config.json.

## Settings (`Super+I`)

A full settings window: appearance (wallpaper, palette, contrast, glass),
pill modules and clock style, Hyprland windows/decoration/blur/animations,
input (keyboard, mouse, touchpad, gestures, cursor), displays (with
auto-revert), sound (devices + per-app volume), network, power & lock (idle
timeouts, lock screen), weather, notifications, a searchable keybind list,
and system info.

- Shell options live in `config.json`.
- Hyprland changes apply instantly and only what you change is saved, to
  `hyprland.json` → generated `~/.config/hypr/hyprland/settings.lua` (loaded
  last). Delete that file to drop them all.
- Idle timeouts regenerate `~/.config/hypr/hypridle.conf` (scripts/idle.sh).
- Keybinds: every bind is recorded as Hyprland loads (hypr/hyprland/lib/bindlog.lua
  -> ~/.local/state/nothing/binds.json), so the page shows what each one does.
  Edits (new keys, open an app, run a command, shell/window/media/system
  actions, disable) go to `keybinds.json` -> generated
  `hypr/hyprland/keybinds-custom.lua`, loaded after keybinds.lua.
  `ipc call binds add "SUPER + ALT + B" "firefox"` works too.

The shell never hot-reloads while the screen is locked (Quickshell crashes if
it does), and the locked state is persisted so a restart can't drop the lock.
Use `scripts/restart.sh` to restart safely.

## Lock screen

`Super+L` / idle → `qs -c nothing ipc call lock lock` (PAM). hyprlock stays
as a themed fallback and is used if the shell isn't running (or if you pick
it in Settings). Preview without locking: `qs -c nothing ipc call lock preview`.

## Weather

Open-Meteo (hourly + 10 days); location from Settings, or wttr.in's IP
lookup when empty.

## Files

```
shell.qml             entry: layers, IPC, global shortcuts
services/             Theme (palette), Appearance (wallpaper state), Ui, Audio,
                      Brightness, Player, Notifs, Agent (polkit), Forecast
                      (weather), Net (Wi-Fi/Bluetooth), Toggles, Config
components/           DotMatrix/DotText/DotIcon (dot-matrix type + weather
                      glyphs), Tray, Tile, Switch, Card, Track, ...
modules/Bar.qml       the island + view switching
modules/views/        one file per view
scripts/theme.sh      sets wallpaper/mode/scheme, runs matugen, live-reloads
matugen/              matugen config + templates (separate from ~/.config/matugen)
apps/                 Hyprland-only kitty + fuzzel configs
bin/fuzzel            wrapper so every fuzzel call uses apps/fuzzel
```

Generated output lives in `~/.local/state/nothing/` plus
`~/.config/hypr/hyprland/colors.lua` and `~/.config/hypr/hyprlock/colors.conf`.

Wallpapers come from `~/Pictures/Wallpapers` (override with `NOTHING_WALLPAPERS`).

## CLI

```sh
qs -c nothing ipc call shell toggle control   # calendar | weather | media | control | wifi | bluetooth | wallpaper | power
qs -c nothing ipc call shell dnd              # also: caffeine, nightLight, tray
qs -c nothing ipc call settings open windows  # any page id
qs -c nothing ipc call settings set decoration:rounding 12
qs -c nothing ipc call lock preview
qs -c nothing ipc call shell wallpaper /path/to/image.jpg
~/.config/quickshell/nothing/scripts/theme.sh scheme scheme-monochrome mode light
```
