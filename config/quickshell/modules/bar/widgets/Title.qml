import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components

// Focused window's icon and title.
Pill {
    id: root
    widget: "title"
    readonly property var top: ToplevelManager.activeToplevel
    readonly property int max: cfg.max_title ?? 48
    readonly property string title: top?.title ?? ""

    visible: !!top?.activated
    tooltip: title.length > max ? title : ""

    AppIcon {
        anchors.verticalCenter: parent.verticalCenter
        app: root.top?.appId ?? ""
        implicitSize: Theme.px(18)
    }
    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.title.length > root.max ? root.title.slice(0, root.max - 1) + "…" : root.title
        color: root.fg
        font.weight: Font.Medium
    }
}
