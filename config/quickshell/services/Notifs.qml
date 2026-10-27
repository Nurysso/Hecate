pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    readonly property var list: server.trackedNotifications.values
    property var popups: []

    function hide(n) { popups = popups.filter(p => p !== n) }
    function clear() { for (const n of list.slice()) n.dismiss() }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true
            n.closed.connect(() => root.hide(n))
            root.popups = [n, ...root.popups]
        }
    }
}
