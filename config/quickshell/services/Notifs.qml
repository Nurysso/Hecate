pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.config

// The notification server. Every notification lands in the history (list); while do not disturb
// is off it also pops up, critical ones regardless.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values
    property var popups: []
    property var arrived: ({})   // notification id → time it came in (ms)

    function hide(n) { popups = popups.filter(p => p !== n) }
    function clear() { for (const n of list.slice()) n.dismiss() }

    // "now", "5m", "2h", or the time of day after that
    function ago(n, now) {
        const t = arrived[n.id]
        if (!t) return ""
        const m = Math.floor((now - t) / 60000)
        return m < 1 ? "now" : m < 60 ? m + "m" : m < 360 ? Math.floor(m / 60) + "h" : Qt.formatTime(new Date(t), "hh:mm")
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true
            root.arrived = Object.assign({}, root.arrived, { [n.id]: Date.now() })
            n.closed.connect(() => {
                root.hide(n)
                const a = Object.assign({}, root.arrived)
                delete a[n.id]
                root.arrived = a
            })
            if (!GlobalStates.dnd || n.urgency === NotificationUrgency.Critical) root.popups = [n, ...root.popups]
        }
    }
}
