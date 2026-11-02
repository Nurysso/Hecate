pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property string panel: ""        // the open panel, "" when none
    property string back: ""         // the panel that opened this one, for a way back
    property string screen: ""       // output it opens on
    property Item anchor: null       // bar widget a popover hangs from
    property var anchors: ({})       // "<output>/<panel>" → the bar widget that opens it, for panels opened by key
    property bool caffeine           // idle inhibitor, shared by every bar
    property bool dnd                // do not disturb: notifications skip the popup
    property bool gamemode           // Hyprland effects off, see Hypr.setGamemode

    function toggle(name, item) { panel === name ? close() : open(name, item) }

    // item: the bar widget that was clicked; without one the panel opens on the focused monitor
    function open(name, item) {
        if (!Config.panels.includes(name)) return console.warn(`hecate: no panel called "${name}"`)
        screen = item?.QsWindow.window?.screen?.name ?? Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
        anchor = item ?? anchors[`${screen}/${name}`] ?? null
        back = ""
        panel = name
    }

    // From one panel to another in the same spot, remembering the way back
    function switchTo(name) {
        const from = panel
        open(name, anchor)
        back = from
    }

    function close() { panel = "" }

    function register(output, name, item) { anchors = Object.assign({}, anchors, { [`${output}/${name}`]: item }) }
    function unregister(output, name, item) {
        if (anchors[`${output}/${name}`] !== item) return
        const a = Object.assign({}, anchors)
        delete a[`${output}/${name}`]
        anchors = a
    }
}
