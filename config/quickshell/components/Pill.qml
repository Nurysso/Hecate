import QtQuick
import Quickshell
import qs.config

// A bar widget's button: icon and/or label with hover feedback, styled by [widgets.<widget>]:
// color, background, and right_click (a shell command). Set panel to open that panel on click;
// the button stays lit while it's open and the panel hangs beneath it.
Rectangle {
    id: root
    property string widget
    property string panel
    property string icon
    property string label
    property string tooltip
    property bool active: panel !== "" && GlobalStates.panel === panel
    property bool interactive: true      // false when the content handles its own clicks (workspaces, tray)
    property alias spacing: row.spacing
    property int padding: bare ? Theme.px(7) : Theme.px(12)   // each side
    readonly property var cfg: Config.widget(widget)
    property color fg: Config.color(widget, "color", Theme.on_surface)
    readonly property bool bare: !label && row.visibleChildren.length <= 1   // icon only: square button
    readonly property string output: QsWindow.window?.screen?.name ?? ""
    default property alias content: row.data
    signal clicked
    signal middleClicked
    signal rightClicked

    implicitWidth: Math.max(implicitHeight, row.implicitWidth + padding * 2)
    implicitHeight: Theme.barHeight - Theme.barInset * 2
    radius: Math.max(0, Theme.radius - Theme.barInset)
    color: active ? Theme.alpha(Theme.primary, 0.18) : Config.color(widget, "background", "transparent")
    Behavior on color { CAnim {} }
    Behavior on implicitWidth { Anim {} }

    function register() { if (panel && output) GlobalStates.register(output, panel, root) }
    onOutputChanged: register()
    Component.onCompleted: register()
    Component.onDestruction: if (panel && output) GlobalStates.unregister(output, panel, root)

    StateLayer {
        id: hover
        enabled: root.interactive
        tint: root.fg
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: e => {
            tip.active = false
            if (e.button === Qt.MiddleButton) return root.middleClicked()
            if (e.button === Qt.RightButton) {
                if (root.cfg.right_click) Quickshell.execDetached(["sh", "-c", root.cfg.right_click])
                return root.rightClicked()
            }
            if (root.panel) GlobalStates.toggle(root.panel, root)
            root.clicked()
        }
        onContainsMouseChanged: {
            tip.active = false
            if (containsMouse && root.tooltip) tipDelay.restart()
            else tipDelay.stop()
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(6)

        Icon { text: root.icon; color: root.fg; visible: text; anchors.verticalCenter: parent.verticalCenter }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            visible: text
            text: root.label
            color: root.fg
            font.weight: Font.Medium
            font.features: { "tnum": 1 }   // numbers that change keep their width
        }
    }

    Timer { id: tipDelay; interval: 600; onTriggered: tip.active = !root.active }
    Loader {
        id: tip
        active: false
        sourceComponent: Tooltip { target: root; text: root.tooltip }
    }
}
