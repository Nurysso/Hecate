import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components

// Wallpapers in [wallpaper] dir. Picking one runs set-wallpaper.sh, which also recolors the shell
// in dynamic mode; the picker closes once it's applied.
Panel {
    id: root
    name: "wallpaper"
    kind: "modal"
    contentWidth: Theme.px(1000)
    contentHeight: Theme.px(640)

    ColumnLayout {
        spacing: Theme.px(12)

        Process {
            id: apply
            stderr: StdioCollector { onStreamFinished: status.text = text.trim() }
            onStarted: status.text = "Applying…"
            onExited: code => {
                if (code !== 0) return
                status.text = ""
                GlobalStates.close()
            }
        }

        RowLayout {
            Layout.leftMargin: Theme.px(4)
            Layout.rightMargin: Theme.px(4)
            spacing: Theme.gap
            Icon { text: Theme.icon.palette; color: root.accent }
            StyledText { text: "Wallpapers"; font.pixelSize: Theme.fontLarge; font.weight: Font.DemiBold }
            StyledText {
                Layout.fillWidth: true
                text: Config.wallpaperDir.replace(Config.home, "~")
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSmall
            }
            StyledText { id: status; color: apply.running ? root.accent : Theme.error; font.pixelSize: Theme.fontSmall }
        }

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            focus: true
            cellWidth: width / 4
            cellHeight: cellWidth * 0.66
            highlightMoveDuration: Theme.animFast
            keyNavigationWraps: true
            Keys.onReturnPressed: currentItem?.pick()
            Keys.onEnterPressed: currentItem?.pick()

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
                required property string fileBaseName
                required property int index
                readonly property bool current: filePath === Theme.wallpaper
                readonly property bool lit: GridView.isCurrentItem || hover.containsMouse
                function pick() { apply.exec([Config.home + "/.config/hecate/scripts/set-wallpaper.sh", filePath]) }
                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: Theme.px(5)
                    radius: Theme.radiusSmall
                    color: Theme.layerHigh
                    border.width: cell.current ? Theme.px(3) : cell.lit ? Theme.px(2) : 0
                    border.color: cell.current ? root.accent : Theme.alpha(Theme.on_surface, 0.5)
                    scale: cell.lit ? 1 : 0.96
                    Behavior on scale { Anim {} }

                    Image {
                        anchors.fill: parent
                        source: "file://" + cell.filePath
                        sourceSize.width: Theme.px(360)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { Anim {} }
                    }

                    // name on hover
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.px(34)
                        opacity: cell.lit ? 1 : 0
                        Behavior on opacity { Anim { duration: Theme.animFast } }
                        gradient: Gradient {
                            GradientStop { position: 0; color: "transparent" }
                            GradientStop { position: 1; color: Theme.alpha(Theme.scrim, 0.7) }
                        }
                        StyledText {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: Theme.px(10)
                            text: cell.fileBaseName
                            color: "white"
                            font.pixelSize: Theme.fontSmall
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.px(10)
                        width: Theme.px(28)
                        height: width
                        radius: width / 2
                        color: root.accent
                        visible: cell.current
                        Icon { anchors.centerIn: parent; text: Theme.icon.check; color: Theme.contrast(root.accent); font.pixelSize: Theme.px(16) }
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
                text: "No images in " + Config.wallpaperDir.replace(Config.home, "~")
                color: Theme.on_surface_variant
            }
        }

        Hints {
            Layout.leftMargin: Theme.px(4)
            keys: [["←↑↓→", "choose"], ["↵", "apply"], ["esc", "close"]]
        }
    }
}
