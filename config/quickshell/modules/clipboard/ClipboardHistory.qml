import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components
import qs.services

// Clipboard history. Enter copies the entry back; Delete removes it (when the cursor is at the end of
// the search text). Images show as thumbnails.
Panel {
    id: root
    name: "clipboard"
    kind: "modal"
    contentWidth: Theme.px(600)
    contentHeight: Theme.px(540)

    ColumnLayout {
        spacing: Theme.px(12)
        Component.onCompleted: Cliphist.refresh()

        SearchField {
            id: search
            Layout.fillWidth: true
            icon: Theme.icon.clipboard
            placeholderText: "Search the clipboard"
            focus: true
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onDeletePressed: e => {
                if (search.cursorPosition < search.length || !list.currentItem) e.accepted = false
                else Cliphist.remove(list.currentItem.modelData)
            }
            onAccepted: list.currentItem?.pick()
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.px(2)
            highlightMoveDuration: Theme.animFast
            highlightResizeDuration: Theme.animFast
            highlight: Rectangle { radius: Theme.radiusSmall; color: Theme.layerHigh }
            // ListView keeps the selection in place as entries are deleted; a new search starts at the top
            model: ScriptModel {
                values: {
                    const q = search.text.toLowerCase()
                    return Cliphist.entries.filter(e => e.slice(e.indexOf("\t") + 1).toLowerCase().includes(q))
                }
            }
            Connections { target: search; function onTextChanged() { list.currentIndex = 0 } }

            delegate: Item {
                id: entry
                required property string modelData
                readonly property string preview: modelData.slice(modelData.indexOf("\t") + 1)
                // "[[ binary data 1.2 MiB png 1920x1080 ]]"
                readonly property var binary: preview.match(/^\[\[ binary data (\S+ \S+) (\w+)(?: (\d+)x(\d+))?/)
                property bool decoded
                function pick() {
                    Cliphist.copy(modelData)
                    GlobalStates.close()
                }

                width: ListView.view.width
                implicitHeight: binary ? Theme.px(76) : Theme.px(48)

                // Decode an image once into the thumbnail cache
                Process {
                    running: !!entry.binary
                    command: ["sh", "-c", 'f=$1; [ -s "$f" ] || { mkdir -p "${f%/*}" && cliphist decode "$2" > "$f"; }', "sh", Cliphist.thumb(entry.modelData), Cliphist.id(entry.modelData)]
                    onExited: entry.decoded = true
                }

                StateLayer { id: hover; radius: Theme.radiusSmall; onClicked: entry.pick() }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.px(12)
                    anchors.rightMargin: Theme.px(8)
                    spacing: Theme.px(12)

                    Icon { visible: !entry.binary; text: Theme.icon.text; color: Theme.on_surface_variant; Layout.preferredWidth: Theme.px(24) }

                    ClippingRectangle {
                        visible: !!entry.binary
                        implicitWidth: Theme.px(96)
                        implicitHeight: Theme.px(60)
                        radius: Theme.radiusTiny
                        color: Theme.layerHigh
                        Icon { anchors.centerIn: parent; visible: thumb.status !== Image.Ready; text: Theme.icon.image; color: Theme.on_surface_variant }
                        Image {
                            id: thumb
                            anchors.fill: parent
                            source: entry.decoded ? "file://" + Cliphist.thumb(entry.modelData) : ""
                            sourceSize.width: Theme.px(192)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            Layout.fillWidth: true
                            text: entry.binary ? `${entry.binary[2].toUpperCase()} image` : entry.preview.replace(/\s+/g, " ")
                        }
                        StyledText {
                            Layout.fillWidth: true
                            visible: !!entry.binary
                            text: entry.binary ? [entry.binary[3] ? `${entry.binary[3]} × ${entry.binary[4]}` : "", entry.binary[1]].filter(s => s).join("  ·  ") : ""
                            color: Theme.on_surface_variant
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    IconButton {
                        size: Theme.px(32)
                        icon: Theme.icon.delete
                        fg: Theme.on_surface_variant
                        opacity: entry.ListView.isCurrentItem || hover.containsMouse ? 1 : 0
                        onClicked: Cliphist.remove(entry.modelData)
                    }
                }
            }

            remove: Transition { Anim { property: "opacity"; to: 0 } }
            displaced: Displaced {}

            ColumnLayout {
                anchors.centerIn: parent
                visible: !list.count
                spacing: Theme.gap
                Icon { Layout.alignment: Qt.AlignHCenter; text: Theme.icon.clipboard; font.pixelSize: Theme.px(44); color: Theme.alpha(Theme.on_surface_variant, 0.6) }
                StyledText { Layout.alignment: Qt.AlignHCenter; text: search.text ? "Nothing matches" : "The clipboard is empty"; color: Theme.on_surface_variant }
            }
        }

        RowLayout {
            Layout.leftMargin: Theme.px(4)
            Hints { keys: [["↵", "copy"], ["del", "remove"], ["esc", "close"]] }
            Item { Layout.fillWidth: true }
            TextButton { visible: list.count > 0; icon: Theme.icon.clearAll; text: "Clear all"; onClicked: Cliphist.wipe() }
        }
    }
}
