import QtQuick
import QtQuick.Layouts
import qs.config

// Desktop widget surface; settings come from hecate.toml [desktop.<widget>], children stack in a column.
Rectangle {
    id: root
    required property string widget
    readonly property var cfg: Config.desktop[widget] ?? {}
    readonly property color accent: Config.tint(cfg.color, Theme.primary)
    default property alias content: column.data

    implicitWidth: 360
    implicitHeight: column.implicitHeight + Theme.pad * 2
    radius: Theme.radius
    color: Config.tint(cfg.background, Theme.alpha(Theme.surface_container, 0.86))
    border.color: Theme.alpha(Theme.outline_variant, 0.5)
    Behavior on color { CAnim {} }

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.pad
        spacing: Theme.gap * 1.5
    }
}
