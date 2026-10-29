//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.bar
import qs.modules.clipboard
import qs.modules.connectivity
import qs.modules.desktop
import qs.modules.emoji
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.power
import qs.modules.wallpaper

ShellRoot {
    Desktop {}
    Bar {}
    Popups {}
    NotificationCenter {}
    Launcher {}
    Connectivity {}
    PowerMenu {}
    ClipboardHistory {}
    EmojiPicker {}
    WallpaperSelector {}

    // qs ipc call hecate toggle <launcher|notifications|connectivity|power|clipboard|emoji|wallpaper>
    IpcHandler {
        target: "hecate"
        function toggle(panel: string): void { GlobalStates.toggle(panel) }
    }
}
