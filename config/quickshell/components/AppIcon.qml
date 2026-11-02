import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config

// An app's icon from its id (window class, desktop entry id or icon name), or a glyph when the icon
// theme has nothing for it.
Item {
    id: root
    property string app
    property int implicitSize: Theme.px(18)
    // Desktop entries load in the background; reading the list makes this look again once they're in
    readonly property string path: DesktopEntries.applications.values.length >= 0
        ? Quickshell.iconPath(DesktopEntries.heuristicLookup(app)?.icon ?? app, true) : ""

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    IconImage { anchors.fill: parent; source: root.path; visible: root.path !== "" }
    Icon {
        anchors.centerIn: parent
        visible: root.path === ""
        text: Theme.icon.apps
        color: Theme.on_surface_variant
        font.pixelSize: Math.round(root.implicitSize * 0.9)
    }
}
