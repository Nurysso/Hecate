import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

PanelWindow {
    anchors { top: true; right: true }
    implicitWidth: 400
    implicitHeight: screen.height / 2
    color: "transparent"
    mask: Region { item: list }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hecate-popups"

    ListView {
        id: list
        x: Theme.gap * 1.5
        width: parent.width - Theme.gap * 3
        height: contentHeight
        spacing: Theme.gap
        interactive: false
        model: ScriptModel { values: GlobalStates.panel === "notifications" ? [] : Notifs.popups }

        delegate: NotificationCard {
            id: card
            width: ListView.view.width

            Timer {
                running: !card.hovered && !card.critical
                interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout : 5000
                onTriggered: Notifs.hide(card.modelData)
            }
        }

        add: Transition {
            Anim { property: "x"; from: 120 }
            Anim { property: "opacity"; from: 0; to: 1 }
        }
        remove: Transition {
            Anim { property: "x"; to: 120 }
            Anim { property: "opacity"; to: 0 }
        }
        displaced: Displaced {}
    }
}
