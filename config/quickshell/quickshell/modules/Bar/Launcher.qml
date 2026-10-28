import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../utils"

IconButton {
    icon: "󰣙"
    command: ["rofi", "-show", "drun", "-config",
              `${Quickshell.env("HOME")}/.config/rofi/config-icon-grid.rasi`]
}
