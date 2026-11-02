import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Volume and microphone changes (from keys, apps, anything) in a small glass pill on the focused screen.
// [widgets.osd] position = "bottom" (default) or "top"; enabled = false turns it off.
Scope {
    id: root
    readonly property var cfg: Config.widget("osd")
    readonly property bool top: cfg.position === "top"
    property string icon
    property string label
    property real value: -1   // 0..1 draws a bar, -1 shows the label alone
    property bool shown
    property bool armed       // ignores the burst of changes while PipeWire starts up

    function show(icon, label, value) {
        // the control center's own slider already shows it
        if (!armed || cfg.enabled === false || GlobalStates.panel === "control") return
        root.icon = icon
        root.label = label
        root.value = value
        shown = true
        hide.restart()
    }
    function volume() { show(Audio.icon, Audio.muted ? "Muted" : Math.round(Audio.volume * 100) + "%", Audio.muted ? 0 : Audio.volume / Audio.max) }

    Timer { running: true; interval: 2500; onTriggered: root.armed = true }
    Timer { id: hide; interval: 1600; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onVolumeChanged() { root.volume() }
        function onMutedChanged() { root.volume() }
        function onMicMutedChanged() { root.show(Audio.micIcon, Audio.micMuted ? "Microphone off" : "Microphone on", -1) }
    }

    PanelWindow {
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
        visible: root.shown || pill.opacity > 0
        anchors { top: root.top; bottom: !root.top }
        margins { top: Theme.barExtent + Theme.px(24); bottom: Theme.px(72) }
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: pill.width
        implicitHeight: pill.height + Theme.px(16)
        color: "transparent"
        mask: Region {}   // never takes clicks
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "hecate-osd"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        BackgroundEffect.blurRegion: Region { regions: Theme.blur && root.shown ? [pill.blur] : [] }

        Glass {
            id: pill
            width: Theme.px(300)
            height: Theme.px(52)
            radius: height / 2
            // arrives at once with its blur, slides into place; fades on the way out
            y: root.top ? (root.shown ? Theme.px(16) : 0) : (root.shown ? 0 : Theme.px(16))
            opacity: root.shown ? 1 : 0
            Behavior on y { Anim {} }
            Behavior on opacity { enabled: !root.shown; Anim { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.px(18)
                anchors.rightMargin: Theme.px(18)
                spacing: Theme.px(14)

                Icon { text: root.icon; color: Theme.primary; font.pixelSize: Theme.px(22) }
                Meter {
                    Layout.fillWidth: true
                    visible: root.value >= 0
                    implicitHeight: Theme.px(8)
                    value: root.value
                }
                StyledText {
                    Layout.fillWidth: root.value < 0
                    Layout.preferredWidth: root.value < 0 ? -1 : Theme.px(52)
                    horizontalAlignment: root.value < 0 ? Text.AlignLeft : Text.AlignRight
                    text: root.label
                    font.weight: Font.DemiBold
                    font.features: { "tnum": 1 }
                }
            }
        }
    }
}
