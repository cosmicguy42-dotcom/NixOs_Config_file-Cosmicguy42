//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.modules
import qs.modules.settings
import qs.modules.desktop

// "nothing" - a single morphing pill, themed from the wallpaper.
//   qs -c nothing
//   qs -c nothing ipc call shell toggle <calendar|weather|media|control|wifi|bluetooth|wallpaper|power>
ShellRoot {
    Variants {
        model: Quickshell.screens
        Wallpaper {}
    }
    Variants {
        model: Quickshell.screens
        Desktop {}
    }
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Lock {
        id: lock
    }
    // Hot-reloading while the session is locked crashes Quickshell's
    // session-lock code, so file watching pauses until you unlock.
    settings.watchFiles: !lock.locked
    Settings {}
    Cheatsheet {}
    Onboarding {}

    // Instantiate services that must run from startup.
    Component.onCompleted: [Notifs, Agent, Audio, Brightness, Forecast, Toggles, Net]

    IpcHandler {
        target: "shell"
        function toggle(view: string): void { Ui.toggle(view); }
        function close(): void { Ui.close(); }
        function wallpaper(path: string): void { Appearance.setWallpaper(path); }
        function randomWallpaper(): void { Appearance.randomWallpaper(); }
        function toggleMode(): void { Appearance.toggleMode(); }
        function clearNotifications(): void { Notifs.clear(); }
        function dnd(): void { Toggles.dnd = !Toggles.dnd; }
        function tray(): void { Ui.trayOpen = !Ui.trayOpen; }
        function arrange(): void { Ui.close(); Ui.widgetEdit = !Ui.widgetEdit; }
        function caffeine(): void { Toggles.caffeine = !Toggles.caffeine; }
        function nightLight(): void { Toggles.setNightLight(!Toggles.nightLight); }
    }

    // Names match the existing Hyprland keybinds (hl.dsp.global("quickshell:<name>")).
    GlobalShortcut { name: "mediaControlsToggle"; onPressed: Ui.toggle("media") }
    GlobalShortcut { name: "sidebarRightToggle"; onPressed: Ui.toggle("control") }
    GlobalShortcut { name: "sessionToggle"; onPressed: Ui.toggle("power") }
    GlobalShortcut { name: "wallpaperSelectorToggle"; onPressed: Ui.toggle("wallpaper") }
    GlobalShortcut { name: "wallpaperSelectorRandom"; onPressed: Appearance.randomWallpaper() }
    GlobalShortcut { name: "toggleLightDark"; onPressed: Appearance.toggleMode() }
    GlobalShortcut { name: "calendarToggle"; onPressed: Ui.toggle("calendar") }
    GlobalShortcut { name: "launcherToggle"; onPressed: Ui.toggle("launcher") }
    GlobalShortcut { name: "captureToggle"; onPressed: Ui.toggle("capture") }
    GlobalShortcut { name: "weatherToggle"; onPressed: Ui.toggle("weather") }
    GlobalShortcut { name: "wifiToggle"; onPressed: Ui.toggle("wifi") }
    GlobalShortcut { name: "bluetoothToggle"; onPressed: Ui.toggle("bluetooth") }
    GlobalShortcut { name: "barToggle"; onPressed: Ui.barVisible = !Ui.barVisible }
}
