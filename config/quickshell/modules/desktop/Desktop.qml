import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components

// Cards on the wallpaper, behind your windows, picked in hecate.toml [desktop]; "foo" loads widgets/Foo.qml.
PanelWindow {
    id: root
    property var cards: []   // their loaders: the blur follows each one as the columns lay out

    screen: Quickshell.screens.find(s => s.name === Config.desktop.monitor) ?? Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "hecate-desktop"
    mask: Region { item: left; Region { item: right } }
    // a card's blur joins once it has started fading in, or the blur would show before the glass
    BackgroundEffect.blurRegion: Region { regions: Theme.blur ? root.cards.filter(l => l.item && l.faded).map(l => l.blur) : [] }

    component Stack: Column {
        property var names
        spacing: Theme.px(14)

        Repeater {
            model: parent.names

            Loader {
                id: loader
                required property string modelData
                required property int index
                readonly property Region blur: Region { item: loader; radius: Theme.radiusLarge }
                readonly property bool faded: opacity > 0.3   // flips once during the fade-in
                source: Qt.resolvedUrl(`widgets/${modelData[0].toUpperCase()}${modelData.slice(1)}.qml`)
                opacity: 0
                Behavior on opacity { Anim { duration: Theme.ms(900); easing.type: Easing.InOutQuad } }   // in step with the wallpaper's fade-in
                Timer { running: true; interval: 150 + loader.index * 90; onTriggered: loader.opacity = 1 }
                Component.onCompleted: root.cards = [...root.cards, loader]
                Component.onDestruction: root.cards = root.cards.filter(l => l !== loader)
            }
        }
    }

    Stack { id: left; names: Config.ready ? Config.desktop.left : []; x: Theme.px(20); y: Theme.px(14) }
    Stack { id: right; names: Config.ready ? Config.desktop.right : []; x: parent.width - width - Theme.px(20); y: Theme.px(14) }
}
