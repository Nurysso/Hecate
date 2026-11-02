//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.services
import qs.modules.bar
import qs.modules.calendar
import qs.modules.clipboard
import qs.modules.connectivity
import qs.modules.control
import qs.modules.desktop
import qs.modules.emoji
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.power
import qs.modules.wallpaper

ShellRoot {
    Desktop {}
    Bar {}
    Popups {}
    Osd {}
    Launcher {}
    ControlCenter {}
    NotificationCenter {}
    Calendar {}
    Connectivity {}
    PowerMenu {}
    ClipboardHistory {}
    EmojiPicker {}
    WallpaperSelector {}

    // Sets up the shell's layer rules and starts following Hyprland's events
    Component.onCompleted: Hypr.applyRules()

    // qs ipc call hecate toggle <launcher|control|notifications|calendar|connectivity|power|clipboard|emoji|wallpaper>
    // also: open <panel>, close, volume <+5|-5|mute>, mic, media <play-pause|next|previous|stop>, dnd, caffeine
    IpcHandler {
        target: "hecate"
        function toggle(panel: string): void { GlobalStates.toggle(panel) }
        function open(panel: string): void { GlobalStates.open(panel) }
        function close(): void { GlobalStates.close() }
        function volume(change: string): void {
            if (change === "mute") Audio.toggleMute()
            else if (!isNaN(Number(change))) Audio.setVolume(Audio.volume + Number(change) / 100)
        }
        function mic(): void { Audio.toggleMic() }
        function media(action: string): void { Players.control(action) }
        function dnd(): void { GlobalStates.dnd = !GlobalStates.dnd }
        function caffeine(): void { GlobalStates.caffeine = !GlobalStates.caffeine }
    }

    // Hyprland binds reach these over its global-shortcuts protocol, with no process per key press:
    //   hl.bind("SUPER + D", hl.dsp.global("hecate:launcher"))
    component Key: GlobalShortcut { appid: "hecate" }

    Variants {
        model: Config.panels
        Key {
            required property string modelData
            name: modelData
            description: `Open or close ${modelData}`
            onPressed: GlobalStates.toggle(modelData)
        }
    }
    Key { name: "volume-up"; description: "Raise the volume"; onPressed: Audio.raise() }
    Key { name: "volume-down"; description: "Lower the volume"; onPressed: Audio.lower() }
    Key { name: "volume-mute"; description: "Mute or unmute the output"; onPressed: Audio.toggleMute() }
    Key { name: "mic-mute"; description: "Mute or unmute the microphone"; onPressed: Audio.toggleMic() }
    Key { name: "media-play-pause"; description: "Play or pause"; onPressed: Players.control("play-pause") }
    Key { name: "media-next"; description: "Next track"; onPressed: Players.control("next") }
    Key { name: "media-previous"; description: "Previous track"; onPressed: Players.control("previous") }
    Key { name: "media-stop"; description: "Stop playback"; onPressed: Players.control("stop") }
    Key { name: "dnd"; description: "Do not disturb"; onPressed: GlobalStates.dnd = !GlobalStates.dnd }
    Key { name: "caffeine"; description: "Keep the screen awake"; onPressed: GlobalStates.caffeine = !GlobalStates.caffeine }
}
