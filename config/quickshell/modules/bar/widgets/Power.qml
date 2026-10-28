import qs.config
import qs.components

Pill {
    widget: "power"
    icon: Theme.icon.power
    onClicked: GlobalStates.toggle("power")
}
