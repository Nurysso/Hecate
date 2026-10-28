import qs.config
import qs.components

Pill {
    widget: "launcher"
    icon: Theme.icon.arch
    onClicked: GlobalStates.toggle("launcher")
}
