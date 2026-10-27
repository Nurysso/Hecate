import QtQuick
import Quickshell
import qs.config

Rectangle {
    id: root
    property string widget
    property string icon
    property string label
    property color fg: Config.color(widget, "color", Theme.on_surface)
    default property alias content: row.data
    signal clicked
    signal rightClicked

    implicitWidth: row.implicitWidth + Theme.pad * 1.5
    implicitHeight: Theme.barHeight - Theme.gap * 2
    radius: height / 2
    color: Config.color(widget, "background", Theme.surface_container)
    Behavior on color { CAnim {} }
    Behavior on implicitWidth { Anim {} }

    // [widgets.<name>] right_click = "command" runs on right-click unless the widget handles it
    onRightClicked: {
        const cmd = Config.widget(widget).right_click
        if (cmd) Quickshell.execDetached(["sh", "-c", cmd])
    }

    StateLayer {
        tint: root.fg
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.gap

        Icon { text: root.icon; color: root.fg; visible: text }
        StyledText { text: root.label; color: root.fg; visible: text; font.weight: Font.Medium }
    }
}
