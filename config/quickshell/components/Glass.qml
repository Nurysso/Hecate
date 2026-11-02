import QtQuick
import Quickshell
import qs.config

// Frosted surface: the tint at [theme] opacity with a hairline edge. A window lists the `blur` of its
// glass in BackgroundEffect.blurRegion and Hyprland blurs what's behind exactly that shape.
Rectangle {
    id: root
    property bool glass: true                    // false: a bare container, nothing drawn and nothing blurred
    property color tint: Theme.surface_container
    readonly property Region blur: Region { item: root; radius: root.radius }

    color: glass ? Theme.alpha(tint, tint.a * Theme.opacity) : "transparent"
    radius: Theme.radiusLarge
    border.width: glass && Config.theme.border ? 1 : 0
    border.color: Theme.hairline
    Behavior on color { CAnim {} }
}
