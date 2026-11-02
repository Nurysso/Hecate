import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Emoji search: words from an emoji's name or keywords narrow the grid ("heart eyes", "fire"), the
// arrows move, Enter copies. Recent picks come first. Data: emojis.tsv, through the Emojis service.
Panel {
    id: root
    name: "emoji"
    kind: "modal"
    contentWidth: Theme.px(600)
    contentHeight: Theme.px(540)

    ColumnLayout {
        spacing: Theme.px(12)

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
            readonly property int cols: Math.max(1, Math.floor(width / Theme.px(56)))
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: width / cols
            cellHeight: Theme.px(56)
            highlightMoveDuration: Theme.animFast
            highlight: Rectangle { radius: Theme.radiusSmall; color: Theme.layerHigh }
            model: ScriptModel {
                values: {
                    const words = search.text.toLowerCase().split(/\s+/).filter(w => w)
                    if (words.length) return Emojis.all.filter(e => words.every(w => e.search.includes(w)))
                    const recent = Emojis.recent.map(c => Emojis.all.find(e => e.char === c)).filter(e => e)
                    return recent.concat(Emojis.all.filter(e => !Emojis.recent.includes(e.char)))
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
                    Emojis.pick(modelData)
                    GlobalStates.close()
                }

                StyledText {
                    anchors.centerIn: parent
                    text: cell.modelData.char
                    font.pixelSize: Theme.px(30)
                    scale: cell.GridView.isCurrentItem ? 1.15 : 1
                    Behavior on scale { Anim { duration: Theme.animFast } }
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
                text: Emojis.all.length ? "No emoji found" : "Loading…"
                color: Theme.on_surface_variant
            }
        }

        RowLayout {
            Layout.leftMargin: Theme.px(4)
            spacing: Theme.px(10)
            StyledText { text: grid.currentItem?.modelData.char ?? ""; font.pixelSize: Theme.px(22) }
            StyledText {
                Layout.fillWidth: true
                text: grid.currentItem?.modelData.name ?? ""
                color: Theme.on_surface_variant
                font.capitalization: Font.Capitalize
            }
            Hints { keys: [["↵", "copy"], ["esc", "close"]] }
        }
    }
}
