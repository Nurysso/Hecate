import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components

Card {
    id: root
    widget: "clock"
    readonly property bool twelve: cfg.twelve_hour ?? true
    readonly property int hour: twelve ? clock.hours % 12 || 12 : clock.hours

    SystemClock { id: clock; precision: SystemClock.Minutes }

    RowLayout {
        spacing: Theme.pad * 1.25

        Item {
            implicitWidth: 132
            implicitHeight: 132

            Ring { anchors.fill: parent; value: (clock.hours % 12 + clock.minutes / 60) / 12; thickness: 6; color: root.accent }
            Ring { anchors.fill: parent; anchors.margins: 14; value: clock.minutes / 60; thickness: 4; color: Theme.alpha(root.accent, 0.55) }

            Column {
                anchors.centerIn: parent
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: String(root.hour).padStart(2, "0") + ":" + String(clock.minutes).padStart(2, "0")
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.twelve
                    text: clock.hours < 12 ? "AM" : "PM"
                    color: root.accent
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 1.5
                }
            }
        }

        Rectangle { implicitWidth: 1; implicitHeight: 88; color: Theme.outline_variant }

        ColumnLayout {
            spacing: Theme.gap

            RowLayout {
                spacing: Theme.gap * 1.5
                StyledText {
                    text: Qt.formatDate(clock.date, "dd")
                    font.pixelSize: 54
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }
                Column {
                    spacing: 2
                    StyledText { text: Qt.formatDate(clock.date, "dddd").toUpperCase(); font.pixelSize: 11; font.weight: Font.Bold; font.letterSpacing: 1.5; color: root.accent }
                    StyledText { text: Qt.formatDate(clock.date, "MMMM").toUpperCase(); font.pixelSize: 11; font.letterSpacing: 1.5; color: Theme.on_surface_variant }
                    StyledText { text: Qt.formatDate(clock.date, "yyyy"); font.pixelSize: 11; color: Theme.outline }
                }
            }

            component Progress: RowLayout {
                property alias label: caption.text
                property alias value: meter.value
                spacing: Theme.gap
                Meter { id: meter; implicitWidth: 120; implicitHeight: 4; fill: root.accent }
                StyledText { id: caption; font.pixelSize: 10; font.letterSpacing: 1; color: Theme.outline }
            }

            Progress { label: "DAY"; value: (clock.hours * 60 + clock.minutes) / 1440 }
            Progress { label: "YEAR"; value: (clock.date - new Date(clock.date.getFullYear(), 0, 1)) / (365.25 * 864e5) }
        }
    }
}
