pragma Singleton
import Quickshell

Singleton {
    property string panel: ""
    property bool caffeine   // idle inhibitor, shared by every bar

    function toggle(name) { panel = panel === name ? "" : name }
}
