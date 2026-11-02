import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// Notification history, hanging under the bell. Do not disturb keeps new ones from popping up.
Panel {
    id: root
    name: "notifications"
    contentWidth: Theme.px(400)

    ColumnLayout {
        spacing: Theme.px(14)

        RowLayout {
            id: header
            Layout.leftMargin: Theme.px(4)
            spacing: Theme.gap

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                StyledText { text: "Notifications"; font.pixelSize: Theme.fontLarge + 2; font.weight: Font.DemiBold }
                StyledText {
                    text: GlobalStates.dnd ? "Do not disturb is on" : Notifs.list.length ? `${Notifs.list.length} unread` : "You're all caught up"
                    color: GlobalStates.dnd ? root.accent : Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                }
            }
            IconButton {
                icon: GlobalStates.dnd ? Theme.icon.bellOff : Theme.icon.bell
                filled: GlobalStates.dnd
                accent: root.accent
                onClicked: GlobalStates.dnd = !GlobalStates.dnd
            }
            TextButton {
                visible: Notifs.list.length > 0
                icon: Theme.icon.clearAll
                text: "Clear all"
                onClicked: Notifs.clear()
            }
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: count ? contentHeight : Theme.px(200)   // the panel grows with the list, then scrolls
            clip: true
            spacing: Theme.gap
            model: ScriptModel { values: Notifs.list.slice().reverse() }
            delegate: NotificationCard { width: ListView.view.width }

            add: Transition { Anim { property: "opacity"; from: 0; to: 1 } }
            remove: Transition {
                Anim { property: "x"; to: list.width / 3 }
                Anim { property: "opacity"; to: 0 }
            }
            displaced: Displaced {}

            ColumnLayout {
                anchors.centerIn: parent
                visible: !list.count
                spacing: Theme.gap
                Icon { Layout.alignment: Qt.AlignHCenter; text: Theme.icon.bellSleep; font.pixelSize: Theme.px(44); color: Theme.alpha(Theme.on_surface_variant, 0.6) }
                StyledText { Layout.alignment: Qt.AlignHCenter; text: "Nothing new"; color: Theme.on_surface_variant }
            }
        }
    }
}
