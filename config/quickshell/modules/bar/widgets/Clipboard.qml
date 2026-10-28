import qs.config
import qs.components

Pill {
    widget: "clipboard"
    icon: Theme.icon.clipboard
    onClicked: GlobalStates.toggle("clipboard")
}
