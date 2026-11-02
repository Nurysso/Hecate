pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config

// Default output and input through PipeWire. [widgets.volume] step and max set the scroll step and the cap.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property real step: (Config.widget("volume").step ?? 5) / 100
    readonly property real max: Math.max(0.1, (Config.widget("volume").max ?? 100) / 100)
    readonly property string icon: muted || volume === 0 ? Theme.icon.volumeOff : Theme.icon.volume[Math.min(2, Math.floor(volume * 3))]
    readonly property string micIcon: micMuted ? Theme.icon.micOff : Theme.icon.mic

    // Hardware devices you can switch between; streams and video nodes left out
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)

    function name(node) { return node?.description || node?.nickname || node?.name || "" }

    function setVolume(v) {
        if (!sink?.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(max, v))
    }
    function raise() { setVolume(volume + step) }
    function lower() { setVolume(volume - step) }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }

    function setMic(v) {
        if (!source?.audio) return
        source.audio.muted = false
        source.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMic() { if (source?.audio) source.audio.muted = !source.audio.muted }

    PwObjectTracker { objects: [root.sink, root.source] }
}
