import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.components
import qs.services

// Notification popups, newest on top. [widgets.notifications]: popup = "top-right" (default), "top",
// "top-left", "bottom-right", "bottom" or "bottom-left"; timeout = seconds before one goes (default 5;
// apps can ask for longer); max = how many show at once (default 4). Critical ones stay until dismissed.
PanelWindow {
    id: root
    readonly property var cfg: Config.widget("notifications")
    readonly property string place: ["top-right", "top", "top-left", "bottom-right", "bottom", "bottom-left"].includes(cfg.popup) ? cfg.popup : "top-right"
    readonly property bool top: place.startsWith("top")
    readonly property int timeout: Math.max(1, Number(cfg.timeout) || 5) * 1000

    screen: Quickshell.screens.find(s => s.name === Config.bar.monitors[0]) ?? Quickshell.screens[0]
    anchors { top: root.top; bottom: !root.top; left: place.endsWith("left"); right: place.endsWith("right") }
    margins { top: Theme.gap; bottom: Theme.gap; left: Math.max(Theme.barMargin, Theme.gap); right: Math.max(Theme.barMargin, Theme.gap) }
    exclusiveZone: 0   // stays clear of the bar without reserving space of its own
    implicitWidth: Theme.px(400)
    implicitHeight: screen.height * 0.7
    color: "transparent"
    mask: Region { item: list }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "hecate-popups"
    BackgroundEffect.blurRegion: Region { regions: Theme.blur ? list.contentItem.children.filter(c => c.blur).map(c => c.blur) : [] }

    ListView {
        id: list
        width: parent.width
        height: Math.min(contentHeight, parent.height)
        y: root.top ? 0 : parent.height - height
        spacing: Theme.gap
        interactive: false
        verticalLayoutDirection: root.top ? ListView.TopToBottom : ListView.BottomToTop
        model: ScriptModel { values: GlobalStates.panel === "notifications" ? [] : Notifs.popups.slice(0, Math.max(1, Number(root.cfg.max) || 4)) }

        delegate: NotificationCard {
            id: card
            width: ListView.view.width
            popup: true
            onSwiped: Notifs.hide(modelData)

            NumberAnimation on countdown {
                running: !card.critical
                paused: card.hovered
                from: 1
                to: 0
                duration: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : root.timeout
                onFinished: {
                    if (card.modelData.transient) card.modelData.expire()
                    else Notifs.hide(card.modelData)
                }
            }
        }

        add: Transition {
            Anim { property: "x"; from: root.width / 3 }
            Anim { property: "opacity"; from: 0; to: 1 }
        }
        remove: Transition {
            Anim { property: "x"; to: ViewTransition.item?.x < 0 ? -root.width : root.width; duration: Theme.animFast; easing.bezierCurve: Theme.curveExit }
            Anim { property: "opacity"; to: 0; duration: Theme.animFast; easing.bezierCurve: Theme.curveExit }
        }
        displaced: Displaced {}
    }
}
