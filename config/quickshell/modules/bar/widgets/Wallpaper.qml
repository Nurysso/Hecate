import qs.config
import qs.components

Pill {
    widget: "wallpaper"
    icon: Theme.icon.wallpaper
    onClicked: GlobalStates.toggle("wallpaper")
}
