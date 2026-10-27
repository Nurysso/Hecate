import QtQuick
import Quickshell.Services.Pipewire
import qs.config
import qs.components

// Default output: scroll changes volume, click mutes.
Pill {
    id: root
    widget: "volume"
    readonly property var cfg: Config.widget(widget)
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property real volume: audio?.volume ?? 0
    readonly property bool muted: audio?.muted ?? false

    visible: !!audio
    icon: muted ? Theme.icon.volumeOff : Theme.icon.volume[Math.min(2, Math.floor(volume * 3))]
    label: cfg.percent ?? true ? Math.round(volume * 100) + "%" : ""
    onClicked: audio.muted = !muted

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    WheelHandler {
        onWheel: e => {
            const step = (root.cfg.step ?? 5) / 100
            const max = (root.cfg.max ?? 100) / 100
            root.audio.muted = false
            root.audio.volume = Math.max(0, Math.min(max, root.volume + (e.angleDelta.y > 0 ? step : -step)))
        }
    }
}
