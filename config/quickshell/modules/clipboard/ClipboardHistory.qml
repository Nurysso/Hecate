import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

Panel {
    id: root
    name: "clipboard"

    ColumnLayout {
        width: 560
        height: 520
        spacing: Theme.gap * 1.5
        Component.onCompleted: Cliphist.refresh()

        RowLayout {
            spacing: Theme.gap
            SearchField {
                id: search
                Layout.fillWidth: true
                icon: Theme.icon.clipboard
                placeholderText: "Search clipboard  ·  Del removes"
                focus: true
                Keys.onDownPressed: list.incrementCurrentIndex()
                Keys.onUpPressed: list.decrementCurrentIndex()
                Keys.onDeletePressed: e => {
                    if (search.cursorPosition < search.length || !list.currentItem) e.accepted = false
                    else Cliphist.remove(list.currentItem.modelData)
                }
                onAccepted: list.currentItem?.clicked()
            }
            Pill {
                icon: Theme.icon.clearAll
                implicitHeight: search.height
                implicitWidth: search.height
                color: Theme.surface_container_highest
                onClicked: Cliphist.wipe()
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            highlightMoveDuration: Theme.animFast
            highlight: Rectangle { radius: Theme.radiusSmall; color: Theme.secondary_container }
            model: ScriptModel {
                values: Cliphist.entries.filter(e => e.toLowerCase().includes(search.text.toLowerCase()))
                onValuesChanged: list.currentIndex = 0
            }

            delegate: Tile {
                id: tile
                required property string modelData
                readonly property string preview: modelData.slice(modelData.indexOf("\t") + 1)
                readonly property bool binary: preview.startsWith("[[ binary data")
                width: ListView.view.width
                implicitHeight: 48
                icon: binary ? Theme.icon.image : Theme.icon.text
                title: binary ? preview.replace(/^\[\[ binary data |\]\]$/g, "") : preview.replace(/\s+/g, " ")
                onClicked: {
                    Cliphist.copy(modelData)
                    GlobalStates.panel = ""
                }

                Icon {
                    text: Theme.icon.delete
                    color: Theme.on_surface_variant
                    opacity: tile.ListView.isCurrentItem ? 1 : 0.4
                    StateLayer { anchors.margins: -8; onClicked: Cliphist.remove(tile.modelData) }
                }
            }

            remove: Transition { Anim { property: "opacity"; to: 0 } }
            displaced: Displaced {}

            StyledText {
                anchors.centerIn: parent
                visible: !list.count
                text: "Clipboard is empty"
                color: Theme.on_surface_variant
            }
        }
    }
}
