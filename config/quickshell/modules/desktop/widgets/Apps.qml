import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.components

// Quick launch: [desktop.apps] apps = desktop-entry ids or plain commands.
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
                id: app
                required property string modelData
                readonly property DesktopEntry entry: DesktopEntries.heuristicLookup(modelData)
                Layout.fillWidth: true
                implicitHeight: 84
                radius: Theme.radiusSmall
                color: "transparent"

                StateLayer {
                    onClicked: app.entry ? app.entry.execute() : Quickshell.execDetached(["sh", "-c", app.modelData])
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6
                    IconImage {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !!app.entry
                        implicitSize: 40
                        source: app.entry ? Quickshell.iconPath(app.entry.icon, true) : ""
                    }
                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: !app.entry
                        text: Theme.icon.apps
                        color: root.accent
                        font.pixelSize: 36
                    }
                    StyledText {
                        width: 72
                        horizontalAlignment: Text.AlignHCenter
                        text: app.entry?.name ?? app.modelData
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
