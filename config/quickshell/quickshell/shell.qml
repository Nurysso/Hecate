import Quickshell
import Quickshell.Io
import QtQuick
import "widgets"
import "modules/Bar"
import "launcher/notify"

ShellRoot {
    // failsafe: never leave a blank desktop if the call is missed
    Timer {
        interval: 1200
        running: true
        onTriggered: widgets.active = true
    }

    LazyLoader {
        id: widgets
        active: false
        Scope {
            ClockWidget {}
            SystemInfoWidget {}
            Bar {}
            GitHubContributionsWidget {}
            // AudioWidget {}
            // QuickAppsWidget {}
            // WeatherWidget {}
            NotificationPanel {}
        }
    }
}
