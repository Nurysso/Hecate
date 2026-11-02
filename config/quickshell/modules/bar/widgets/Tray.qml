import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.config
import qs.components

// System tray: click activates, right-click opens the item's menu, middle-click its secondary action.
Pill {
    widget: "tray"
    interactive: false
    spacing: Theme.px(12)
    padding: Theme.px(10)
    visible: SystemTray.items.values.length > 0

    Repeater {
        model: SystemTray.items.values

        IconImage {
            required property SystemTrayItem modelData
            anchors.verticalCenter: parent.verticalCenter
            source: modelData.icon
            implicitSize: Theme.px(17)
            opacity: hover.containsMouse ? 1 : 0.85

            MouseArea {
                id: hover
                anchors.fill: parent
                anchors.margins: -Theme.px(5)
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: e => {
                    const item = parent.modelData
                    if (e.button === Qt.MiddleButton) item.secondaryActivate()
                    else if (e.button === Qt.RightButton || item.onlyMenu) {
                        const p = parent.QsWindow.window.mapFromItem(parent, 0, Theme.barBottom ? -Theme.gap : parent.height + Theme.barInset + Theme.gap)
                        item.display(parent.QsWindow.window, p.x, p.y)
                    } else item.activate()
                }
            }
        }
    }
}
