import QtQuick
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Now playing: click plays/pauses, scroll skips tracks, middle-click raises the player. Hidden with no player.
Pill {
    id: root
    widget: "media"
    readonly property var player: Players.active
    readonly property int max: cfg.max_title ?? 32
    readonly property string track: [player?.trackTitle, player?.trackArtist].filter(s => s).join(" · ")

    visible: !!player && track !== ""
    tooltip: [player?.trackTitle, player?.trackArtist, player?.trackAlbum].filter(s => s).join("\n")
    onClicked: Players.control("play-pause")
    onMiddleClicked: if (player?.canRaise) player.raise()

    WheelHandler { onWheel: e => Players.control(e.angleDelta.y > 0 ? "previous" : "next") }

    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Theme.px(22)
        implicitHeight: Theme.px(22)
        radius: Theme.px(6)
        color: Theme.alpha(Theme.primary, 0.2)

        Image {
            id: art
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            sourceSize.width: Theme.px(44)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        // play state: on its own without art, over a dimmed cover while paused
        Rectangle { anchors.fill: parent; visible: art.status === Image.Ready && !Players.playing; color: Theme.alpha(Theme.scrim, 0.5) }
        Icon {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready || !Players.playing
            text: Players.playing ? Theme.icon.pause : Theme.icon.play
            color: art.status === Image.Ready ? "white" : root.fg
            font.pixelSize: Theme.px(14)
        }
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.track.length > root.max ? root.track.slice(0, root.max - 1) + "…" : root.track
        color: Players.playing ? root.fg : Theme.alpha(root.fg, 0.6)
        font.weight: Font.Medium
    }
}
