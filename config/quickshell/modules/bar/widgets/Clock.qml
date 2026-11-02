import QtQuick
import Quickshell
import qs.config
import qs.components

// Time and date; click for the calendar. [widgets.clock] time and date are Qt formats (date = "" hides
// it). The older format = "..." still works and shows as a single label.
Pill {
    id: root
    widget: "clock"
    panel: "calendar"
    readonly property string time: cfg.time ?? "hh:mm"
    readonly property string date: cfg.date ?? "ddd d MMM"

    tooltip: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
    label: cfg.format ? Qt.formatDateTime(clock.date, cfg.format) : ""

    SystemClock { id: clock; precision: (root.cfg.format ?? root.time).includes("s") ? SystemClock.Seconds : SystemClock.Minutes }

    StyledText {
        visible: !root.cfg.format
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, root.time)
        color: root.fg
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }
    StyledText {
        visible: !root.cfg.format && text
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(clock.date, root.date)
        color: Theme.alpha(root.fg, 0.7)
    }
}
