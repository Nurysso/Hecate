import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.components

// Focused window's icon and title.
Pill {
    id: root
    widget: "title"
    readonly property var top: ToplevelManager.activeToplevel
    readonly property int max: Config.widget(widget).max_title ?? 48
    readonly property string iconPath: top ? Quickshell.iconPath(DesktopEntries.heuristicLookup(top.appId)?.icon ?? top.appId, true) : ""

    visible: !!top?.activated
    label: top ? (top.title.length > max ? top.title.slice(0, max - 1) + "…" : top.title) : ""

    IconImage { visible: root.iconPath; source: root.iconPath; implicitSize: 18; anchors.verticalCenter: parent.verticalCenter }
}
