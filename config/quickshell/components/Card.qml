import QtQuick
import QtQuick.Layouts
import qs.config

// Desktop card: glass with its children stacked in a column. Settings come from [desktop.<widget>],
// including color (accent) and background.
Glass {
    id: root
    required property string widget
    readonly property var cfg: Config.desktop[widget] ?? {}
    readonly property color accent: Config.tint(cfg.color, Theme.primary)
    default property alias content: column.data

    implicitWidth: Theme.px(360)
    implicitHeight: column.implicitHeight + Theme.pad * 2
    tint: Config.tint(cfg.background, Theme.surface_container)

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.pad
        spacing: Theme.px(14)
    }
}
