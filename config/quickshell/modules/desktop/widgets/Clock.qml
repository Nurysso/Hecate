import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components

// Hour and minute rings around the time, the date, and how far through the day and year we are.
Card {
    id: root
    widget: "clock"
    readonly property bool twelve: cfg.twelve_hour ?? true
    readonly property int hour: twelve ? clock.hours % 12 || 12 : clock.hours

    SystemClock { id: clock; precision: SystemClock.Minutes }

    RowLayout {
        spacing: Theme.px(20)

        Item {
            implicitWidth: Theme.px(132)
            implicitHeight: Theme.px(132)

            Ring { anchors.fill: parent; value: (clock.hours % 12 + clock.minutes / 60) / 12; thickness: Theme.px(7); color: root.accent }
            Ring { anchors.fill: parent; anchors.margins: Theme.px(14); value: clock.minutes / 60; thickness: Theme.px(4); color: Theme.alpha(root.accent, 0.5) }

            Column {
                anchors.centerIn: parent
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(root.hour).padStart(2, "0") + ":" + String(clock.minutes).padStart(2, "0")
                    font.pixelSize: Theme.px(28)
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.twelve
                    text: clock.hours < 12 ? "AM" : "PM"
                    color: root.accent
                    font.pixelSize: Theme.fontTiny
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.5
                }
            }
        }

        ColumnLayout {
            spacing: Theme.gap

            RowLayout {
                spacing: Theme.px(12)
                StyledText {
                    text: Qt.formatDate(clock.date, "dd")
                    font.pixelSize: Theme.px(56)
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
                Column {
                    spacing: Theme.px(2)
                    StyledText { text: Qt.formatDate(clock.date, "dddd").toUpperCase(); font.pixelSize: Theme.fontTiny; font.weight: Font.Bold; font.letterSpacing: 1.5; color: root.accent }
                    StyledText { text: Qt.formatDate(clock.date, "MMMM").toUpperCase(); font.pixelSize: Theme.fontTiny; font.letterSpacing: 1.5; color: Theme.on_surface_variant }
                    StyledText { text: Qt.formatDate(clock.date, "yyyy"); font.pixelSize: Theme.fontTiny; color: Theme.outline }
                }
            }

            component Progress: RowLayout {
                property alias label: caption.text
                property alias value: meter.value
                spacing: Theme.gap
                Meter { id: meter; implicitWidth: Theme.px(120); implicitHeight: Theme.px(4); fill: root.accent }
                StyledText { id: caption; font.pixelSize: Theme.px(10); font.letterSpacing: 1; color: Theme.outline }
            }

            Progress { label: "DAY"; value: (clock.hours * 60 + clock.minutes) / 1440 }
            Progress { label: "YEAR"; value: (clock.date - new Date(clock.date.getFullYear(), 0, 1)) / (365.25 * 864e5) }
        }
    }
}
