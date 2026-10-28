import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components

Panel {
    id: root
    name: "wallpaper"

    ColumnLayout {
        width: 980
        height: 600
        spacing: Theme.gap * 1.5

        Process {
            id: apply
            stderr: StdioCollector { onStreamFinished: statusText.text = text.trim() }
            onStarted: statusText.text = "Applying…"
            onExited: code => {
                if (code !== 0) return
                statusText.text = ""
                GlobalStates.panel = ""
            }
        }

        RowLayout {
            Layout.leftMargin: Theme.gap
            spacing: Theme.gap
            Icon { text: Theme.icon.folder; color: root.accent }
            StyledText { text: Config.wallpaperDir; color: Theme.on_surface_variant; Layout.fillWidth: true }
            StyledText { id: statusText; color: apply.running ? root.accent : Theme.error }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.68
            highlightMoveDuration: Theme.animFast
            keyNavigationWraps: true
            Keys.onReturnPressed: currentItem?.pick()

            // shortcut: top-level files only; switch to a find(1) Process if nested folders are needed
            model: FolderListModel {
                folder: "file://" + Config.wallpaperDir
                nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.bmp"]
                caseSensitive: false
                showDirs: false
            }

            delegate: Item {
                id: cell
                required property string filePath
                required property int index
                readonly property bool current: filePath === Theme.wallpaper
                readonly property bool lit: GridView.isCurrentItem || hover.containsMouse
                function pick() { apply.exec([Config.home + "/.config/hecate/scripts/set-wallpaper.sh", filePath]) }
                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.gap / 2
                    radius: cell.lit ? Theme.radius : Theme.radiusSmall
                    color: Theme.surface_container_high
                    border.width: cell.current ? 3 : 0
                    border.color: root.accent
                    scale: cell.lit ? 1 : 0.95
                    Behavior on radius { Anim {} }
                    Behavior on scale { Anim {} }

                    Image {
                        anchors.fill: parent
                        source: "file://" + cell.filePath
                        sourceSize.width: 360
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { Anim {} }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        width: 28
                        height: 28
                        radius: 14
                        color: root.accent
                        visible: cell.current
                        Icon { anchors.centerIn: parent; text: Theme.icon.check; color: Theme.on_primary; font.pixelSize: 16 }
                    }

                    StateLayer {
                        id: hover
                        tint: Theme.on_surface
                        onContainsMouseChanged: if (containsMouse) grid.currentIndex = cell.index
                        onClicked: cell.pick()
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: !grid.count
                text: "No images in " + Config.wallpaperDir
                color: Theme.on_surface_variant
            }
        }
    }
}
