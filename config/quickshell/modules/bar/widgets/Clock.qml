import QtQuick
import Quickshell
import qs.config
import qs.components

Pill {
    widget: "clock"
    label: Qt.formatDateTime(clock.date, Config.widget("clock").format ?? "ddd d MMM  ·  hh:mm")

    SystemClock { id: clock; precision: SystemClock.Minutes }
}
