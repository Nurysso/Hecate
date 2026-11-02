import qs.config
import qs.components
import qs.services

// The active keyboard layout; click for the next one. Hidden while only one layout is set up.
Pill {
    widget: "keyboard"
    visible: Hypr.layouts.length > 1
    icon: Theme.icon.keyboard
    label: Hypr.layout.toUpperCase()
    tooltip: "Next keyboard layout"
    onClicked: Hypr.nextLayout()
}
