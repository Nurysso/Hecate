import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

Panel {
    id: root
    name: "notifications"
    docked: true

    ColumnLayout {
        width: 400
        height: Math.min(640, implicitHeight)
        spacing: Theme.gap * 1.5

        RowLayout {
            Layout.leftMargin: Theme.gap
            StyledText {
                Layout.fillWidth: true
                text: "Notifications"
                font.pixelSize: Theme.fontSize + 4
                font.weight: Font.DemiBold
            }
            Pill {
                icon: Theme.icon.clearAll
                label: "Clear"
                visible: Notifs.list.length
                color: Theme.secondary_container
                onClicked: Notifs.clear()
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: Math.max(contentHeight, 160)
            clip: true
            spacing: Theme.gap
            model: ScriptModel { values: Notifs.list.slice().reverse() }
            delegate: NotificationCard { width: ListView.view.width }

            add: Transition { Anim { property: "opacity"; from: 0; to: 1 } }
            remove: Transition {
                Anim { property: "x"; to: 120 }
                Anim { property: "opacity"; to: 0 }
            }
            displaced: Displaced {}

            ColumnLayout {
                anchors.centerIn: parent
                visible: !Notifs.list.length
                Icon { Layout.alignment: Qt.AlignHCenter; text: Theme.icon.bellOff; font.pixelSize: 48; color: Theme.on_surface_variant }
                StyledText { text: "All caught up"; color: Theme.on_surface_variant }
            }
        }
    }
}
