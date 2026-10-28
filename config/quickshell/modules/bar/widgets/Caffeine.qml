import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components

// Keeps the screen awake while on.
Pill {
    id: root
    widget: "caffeine"
    icon: GlobalStates.caffeine ? Theme.icon.coffee : Theme.icon.coffeeOff
    fg: GlobalStates.caffeine ? Config.color(widget, "color", Theme.primary) : Theme.on_surface_variant
    onClicked: GlobalStates.caffeine = !GlobalStates.caffeine

    IdleInhibitor { window: root.QsWindow.window; enabled: GlobalStates.caffeine }
}
