import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Quick launch: [desktop.apps] apps = desktop entry ids or plain commands.
Card {
    id: root
    widget: "apps"

    GridLayout {
        columns: 4
        rowSpacing: Theme.gap
        columnSpacing: Theme.gap

        Repeater {
            model: root.cfg.apps ?? ["firefox", "kitty", "thunar"]

            Rectangle {
                id: tile
                required property string modelData
                readonly property DesktopEntry entry: DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(modelData) : null
                Layout.fillWidth: true
                implicitHeight: Theme.px(88)
                radius: Theme.radiusSmall
                color: "transparent"

                StateLayer {
                    onClicked: tile.entry ? Launches.launch(tile.entry) : Quickshell.execDetached(["sh", "-c", tile.modelData])
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.px(8)
                    AppIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        app: tile.entry?.icon ?? tile.modelData
                        implicitSize: Theme.px(42)
                    }
                    StyledText {
                        width: Theme.px(76)
                        horizontalAlignment: Text.AlignHCenter
                        text: tile.entry?.name ?? tile.modelData
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }
}
