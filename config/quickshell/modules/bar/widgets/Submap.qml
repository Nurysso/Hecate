import qs.config
import qs.components
import qs.services

// Shows while a Hyprland submap (a key mode, such as one for resizing) is active; click to leave it.
Pill {
    widget: "submap"
    visible: Hypr.submap !== ""
    icon: Theme.icon.keyboard
    label: Hypr.submap
    fg: Config.color(widget, "color", Theme.primary)
    color: Config.color(widget, "background", Theme.alpha(Theme.primary, 0.16))
    tooltip: "Leave this key mode"
    onClicked: Hypr.resetSubmap()
}
