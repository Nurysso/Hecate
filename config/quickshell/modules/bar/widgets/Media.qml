import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.components

// Now playing: click plays/pauses, scroll skips tracks. Hidden with no player.
Pill {
    id: root
    widget: "media"
    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property int max: Config.widget(widget).max_title ?? 32
    readonly property string text: [player?.trackTitle, player?.trackArtist].filter(s => s).join(" · ")

    visible: !!player
    icon: player?.isPlaying ? Theme.icon.pause : Theme.icon.play
    label: text.length > max ? text.slice(0, max - 1) + "…" : text
    onClicked: if (player?.canTogglePlaying) player.togglePlaying()

    WheelHandler {
        onWheel: e => {
            if (e.angleDelta.y > 0 && root.player.canGoPrevious) root.player.previous()
            else if (e.angleDelta.y < 0 && root.player.canGoNext) root.player.next()
        }
    }
}
