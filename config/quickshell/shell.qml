// shell.qml
import Quickshell
import Quickshell.Wayland
import "widgets" as Widgets
import "modules" as Module

ShellRoot {
    Widgets.ClockWidget {}
    Widgets.QuickAppsWidget {}
    Widgets.AudioWidget {}
    Widgets.SystemInfoWidget {}
    // Module.Bar{}
}
