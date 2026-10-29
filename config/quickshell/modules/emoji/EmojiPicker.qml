import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components

// Data: emojis.tsv, one "<emoji>\t<name>\t<keywords>" per line (from the Unicode CLDR names).
Panel {
    id: root
    name: "emoji"

    ColumnLayout {
        id: column
        width: 560
        height: 520
        spacing: Theme.gap * 1.5

        FileView {
            id: data
            path: Quickshell.shellPath("modules/emoji/emojis.tsv")
            printErrors: false
        }
        readonly property var all: data.text().split("\n").filter(l => l).map(l => {
            const f = l.split("\t")
            return { char: f[0], name: f[1], search: (f[1] + " " + f[2]).toLowerCase() }
        })

        SearchField {
            id: search
            Layout.fillWidth: true
            icon: Theme.icon.emoji
            placeholderText: "Search emoji"
            focus: true
            Keys.onDownPressed: grid.moveCurrentIndexDown()
            Keys.onUpPressed: grid.moveCurrentIndexUp()
            Keys.onLeftPressed: e => { if (search.cursorPosition > 0) e.accepted = false; else grid.moveCurrentIndexLeft() }
            Keys.onRightPressed: e => { if (search.cursorPosition < search.length) e.accepted = false; else grid.moveCurrentIndexRight() }
            onAccepted: grid.currentItem?.pick()
        }

        GridView {
            id: grid
            readonly property int cols: Math.floor(width / 56)
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / cols
            cellHeight: 56
            highlightMoveDuration: Theme.animFast
            highlight: Rectangle { radius: Theme.radiusSmall; color: Theme.secondary_container }
            model: ScriptModel {
                values: {
                    const words = search.text.toLowerCase().split(/\s+/).filter(w => w)
                    return column.all.filter(e => words.every(w => e.search.includes(w)))
                }
                onValuesChanged: grid.currentIndex = 0
            }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                width: grid.cellWidth
                height: grid.cellHeight
                function pick() {
                    Quickshell.execDetached(["wl-copy", "--", modelData.char])
                    GlobalStates.panel = ""
                }

                StyledText {
                    anchors.centerIn: parent
                    text: cell.modelData.char
                    font.pixelSize: 28
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Only on real mouse movement, so keyboard scrolling
                    // under a stationary cursor doesn't steal the selection.
                    onPositionChanged: grid.currentIndex = cell.index
                    onClicked: cell.pick()
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: !grid.count
                text: "No emoji found"
                color: Theme.on_surface_variant
            }
        }

        // Name of the highlighted emoji
        StyledText {
            Layout.fillWidth: true
            text: grid.currentItem ? grid.currentItem.modelData.name : ""
            color: Theme.on_surface_variant
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
