import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components
import qs.services

// Now playing over MPRIS, with a cava visualizer while audio plays.
Card {
    id: root
    widget: "audio"

    readonly property MprisPlayer player: Players.active
    readonly property bool playing: player?.isPlaying ?? false
    readonly property int barCount: 36
    property var bars: Array(barCount).fill(0)

    // MPRIS doesn't push position updates
    Timer { running: root.playing; repeat: true; interval: 1000; onTriggered: root.player.positionChanged() }

    Process {
        running: root.playing
        command: ["cava", "-p", Quickshell.shellPath("modules/desktop/cava.conf")]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").slice(0, root.barCount).map(v => Math.min(Number(v) / 100, 1) || 0)
        }
        onRunningChanged: if (!running) root.bars = Array(root.barCount).fill(0)
    }

    RowLayout {
        visible: !root.player
        spacing: Theme.px(12)
        Icon { text: Theme.icon.music; color: Theme.on_surface_variant; font.pixelSize: Theme.px(24) }
        StyledText { text: "Nothing playing"; color: Theme.on_surface_variant }
    }

    RowLayout {
        visible: !!root.player
        spacing: Theme.pad

        ClippingRectangle {
            implicitWidth: Theme.px(88)
            implicitHeight: Theme.px(88)
            radius: Theme.radiusSmall
            color: Theme.layerHigh

            Icon { anchors.centerIn: parent; text: Theme.icon.music; color: root.accent; font.pixelSize: Theme.px(32); visible: art.status !== Image.Ready }
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: Theme.px(176)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { Anim {} }
            }
        }

        ColumnLayout {
            spacing: Theme.px(2)
            Layout.fillWidth: true
            StyledText {
                text: root.player?.identity ?? ""
                color: root.accent
                font.pixelSize: Theme.fontTiny
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
                Layout.fillWidth: true
            }
            StyledText { text: root.player?.trackTitle || "Unknown title"; font.pixelSize: Theme.fontLarge; font.weight: Font.DemiBold; Layout.fillWidth: true }
            StyledText { text: root.player?.trackArtist ?? ""; color: Theme.on_surface_variant; Layout.fillWidth: true }
            StyledText { text: root.player?.trackAlbum ?? ""; color: Theme.outline; font.pixelSize: Theme.fontSmall; visible: text; Layout.fillWidth: true }
        }
    }

    // Visualizer, mirrored around the middle
    Row {
        id: viz
        visible: !!root.player
        Layout.fillWidth: true
        height: Theme.px(40)
        spacing: Theme.px(3)
        readonly property real barW: (width - spacing * (root.barCount - 1)) / root.barCount

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                width: viz.barW
                height: Math.max(Theme.px(3), viz.height * root.bars[index])
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: Theme.alpha(root.accent, 0.35 + 0.65 * root.bars[index])
                Behavior on height { Anim { duration: 90 } }
            }
        }
    }

    // Seek bar, click to jump
    RowLayout {
        visible: root.player?.positionSupported ?? false
        spacing: Theme.gap
        StyledText { text: Players.time(root.player?.position ?? 0); color: Theme.on_surface_variant; font.pixelSize: Theme.fontTiny; font.features: { "tnum": 1 } }
        Meter {
            Layout.fillWidth: true
            value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            fill: root.accent
            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.px(6)
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: mouse => root.player.position = root.player.length * Math.max(0, Math.min(1, (mouse.x - Theme.px(6)) / parent.width))
            }
        }
        StyledText { text: Players.time(root.player?.length ?? 0); color: Theme.on_surface_variant; font.pixelSize: Theme.fontTiny; font.features: { "tnum": 1 } }
    }

    RowLayout {
        visible: !!root.player
        spacing: Theme.gap
        Layout.alignment: Qt.AlignHCenter

        IconButton {
            visible: root.player?.shuffleSupported ?? false
            icon: Theme.icon.shuffle
            size: Theme.px(40)
            fg: root.player?.shuffle ? root.accent : Theme.on_surface
            onClicked: root.player.shuffle = !root.player.shuffle
        }
        IconButton { icon: Theme.icon.prev; size: Theme.px(40); enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }

        Rectangle {
            implicitWidth: Theme.px(56)
            implicitHeight: Theme.px(56)
            radius: root.playing ? Theme.radiusSmall : height / 2
            color: root.accent
            Behavior on radius { Anim {} }
            Icon { anchors.centerIn: parent; text: root.playing ? Theme.icon.pause : Theme.icon.play; color: Theme.contrast(root.accent); font.pixelSize: Theme.px(26) }
            StateLayer { tint: Theme.contrast(root.accent); enabled: root.player?.canTogglePlaying ?? false; onClicked: root.player.togglePlaying() }
        }

        IconButton { icon: Theme.icon.next; size: Theme.px(40); enabled: root.player?.canGoNext ?? false; onClicked: root.player.next() }
        IconButton {
            visible: root.player?.loopSupported ?? false
            icon: Theme.icon.repeat
            size: Theme.px(40)
            fg: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None ? root.accent : Theme.on_surface
            onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : MprisLoopState.None
        }
    }
}
