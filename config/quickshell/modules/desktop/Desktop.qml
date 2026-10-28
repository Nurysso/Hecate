import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components

// Widgets on the wallpaper, picked in hecate.toml [desktop]; "foo" loads widgets/Foo.qml.
PanelWindow {
    id: root
    screen: Quickshell.screens.find(s => s.name === Config.desktop.monitor) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "hecate-desktop"
    mask: Region { item: left; Region { item: right } }

    component Stack: Column {
        property var names
        spacing: Theme.gap * 1.5

        Repeater {
            model: parent.names
            Loader {
                id: loader
                required property string modelData
                required property int index
                source: Qt.resolvedUrl(`widgets/${modelData[0].toUpperCase()}${modelData.slice(1)}.qml`)
                opacity: 0
                transform: Translate { y: (1 - loader.opacity) * 16 }
                Behavior on opacity { Anim { duration: 700 } }
                Timer { running: true; interval: 150 + loader.index * 90; onTriggered: loader.opacity = 1 }
            }
        }
    }

    Stack { id: left; names: Config.desktop.left; x: Theme.pad * 1.5; y: Theme.pad }
    Stack { id: right; names: Config.desktop.right; x: parent.width - width - Theme.pad * 1.5; y: Theme.pad }
}
