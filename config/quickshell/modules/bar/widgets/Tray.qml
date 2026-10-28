import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components

Pill {
    widget: "tray"
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values

        IconImage {
            required property SystemTrayItem modelData
            anchors.verticalCenter: parent.verticalCenter
            source: modelData.icon
            implicitSize: 18

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: e => {
                    const item = parent.modelData
                    if (e.button === Qt.MiddleButton) item.secondaryActivate()
                    else if (e.button === Qt.RightButton || item.onlyMenu) {
                        const p = parent.QsWindow.window.mapFromItem(parent, 0, parent.height + 12)
                        item.display(parent.QsWindow.window, p.x, p.y)
                    } else item.activate()
                }
            }
        }
    }
}
