import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.config
import qs.components

// Now playing over MPRIS, with a cava visualizer while audio plays.
Card {
    id: root
    widget: "audio"

    readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property int barCount: 36
    property var bars: Array(barCount).fill(0)

    function time(sec) {
        const s = Math.max(0, Math.floor(sec))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // MPRIS doesn't push position updates
    Timer { running: root.playing; repeat: true; interval: 1000; onTriggered: root.player.positionChanged() }

    Process {
        running: root.playing
        command: ["cava", "-p", Quickshell.shellDir + "/modules/desktop/cava.conf"]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").slice(0, root.barCount).map(v => Math.min(Number(v) / 100, 1) || 0)
        }
        onRunningChanged: if (!running) root.bars = Array(root.barCount).fill(0)
    }

    RowLayout {
        visible: !root.player
        spacing: Theme.gap * 1.5
        Icon { text: Theme.icon.music; color: Theme.on_surface_variant; font.pixelSize: 24 }
        StyledText { text: "Nothing playing"; color: Theme.on_surface_variant }
    }

    RowLayout {
        visible: !!root.player
        spacing: Theme.pad

        ClippingRectangle {
            implicitWidth: 88
            implicitHeight: 88
            radius: Theme.radiusSmall
            color: Theme.surface_container_highest

            Icon { anchors.centerIn: parent; text: Theme.icon.music; color: root.accent; font.pixelSize: 32; visible: art.status !== Image.Ready }
            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                sourceSize.width: 176
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { Anim {} }
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            StyledText {
                text: root.player?.identity ?? ""
                color: root.accent
                font.pixelSize: 11
                font.weight: Font.Medium
                font.letterSpacing: 1
                Layout.fillWidth: true
            }
            StyledText { text: root.player?.trackTitle || "Unknown title"; font.pixelSize: 16; font.weight: Font.DemiBold; Layout.fillWidth: true }
            StyledText { text: root.player?.trackArtist ?? ""; color: Theme.on_surface_variant; Layout.fillWidth: true }
            StyledText { text: root.player?.trackAlbum ?? ""; color: Theme.outline; font.pixelSize: Theme.fontSize - 2; visible: text; Layout.fillWidth: true }
        }
    }

    // Visualizer, mirrored around the middle
    Row {
        id: viz
        visible: !!root.player
        Layout.fillWidth: true
        height: 40
        spacing: 3
        readonly property real barW: (width - spacing * (root.barCount - 1)) / root.barCount

        Repeater {
            model: root.barCount
            Rectangle {
                required property int index
                width: viz.barW
                height: Math.max(3, viz.height * root.bars[index])
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
        StyledText { text: root.time(root.player?.position ?? 0); color: Theme.on_surface_variant; font.pixelSize: 11; font.features: { "tnum": 1 } }
        Meter {
            Layout.fillWidth: true
            value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
            fill: root.accent
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: mouse => root.player.position = root.player.length * Math.max(0, Math.min(1, (mouse.x - 6) / parent.width))
            }
        }
        StyledText { text: root.time(root.player?.length ?? 0); color: Theme.on_surface_variant; font.pixelSize: 11; font.features: { "tnum": 1 } }
    }

    component Control: Rectangle {
        id: control
        property string icon
        property bool active
        signal clicked
        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: "transparent"
        opacity: enabled ? 1 : 0.38
        Icon { anchors.centerIn: parent; text: control.icon; color: control.active ? root.accent : Theme.on_surface; font.pixelSize: 20 }
        StateLayer { onClicked: control.clicked() }
    }

    RowLayout {
        visible: !!root.player
        spacing: Theme.gap
        Layout.alignment: Qt.AlignHCenter

        Control {
            visible: root.player?.shuffleSupported ?? false
            icon: Theme.icon.shuffle
            active: root.player?.shuffle ?? false
            onClicked: root.player.shuffle = !root.player.shuffle
        }
        Control { icon: Theme.icon.prev; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }

        Rectangle {
            implicitWidth: 56
            implicitHeight: 56
            radius: root.playing ? Theme.radiusSmall : 28
            color: root.accent
            Behavior on radius { Anim {} }
            Icon { anchors.centerIn: parent; text: root.playing ? Theme.icon.pause : Theme.icon.play; color: Theme.on_primary; font.pixelSize: 26 }
            StateLayer { tint: Theme.on_primary; enabled: root.player?.canTogglePlaying ?? false; onClicked: root.player.togglePlaying() }
        }

        Control { icon: Theme.icon.next; enabled: root.player?.canGoNext ?? false; onClicked: root.player.next() }
        Control {
            visible: root.player?.loopSupported ?? false
            icon: Theme.icon.repeat
            active: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
            onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist : MprisLoopState.None
        }
    }
}
