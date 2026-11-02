import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components

// Month calendar, hanging under the clock. Scroll or use the arrows to change month.
Panel {
    id: root
    name: "calendar"
    side: "center"
    contentWidth: Theme.px(328)

    ColumnLayout {
        id: cal
        spacing: Theme.px(14)

        property int offset: 0   // months away from this one
        readonly property date today: clock.date
        readonly property date month: new Date(today.getFullYear(), today.getMonth() + offset, 1)
        // the grid starts on the locale's first weekday on or before the 1st
        readonly property date start: {
            const d = new Date(month)
            d.setDate(1 - (month.getDay() - Qt.locale().firstDayOfWeek + 7) % 7)
            return d
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }

        ColumnLayout {
            Layout.leftMargin: Theme.px(4)
            spacing: 0
            StyledText {
                text: Qt.formatDate(cal.today, "dddd")
                color: root.accent
                font.pixelSize: Theme.fontSmall
                font.weight: Font.DemiBold
                font.letterSpacing: 1
                font.capitalization: Font.AllUppercase
            }
            StyledText { text: Qt.formatDate(cal.today, "d MMMM yyyy"); font.pixelSize: Theme.fontTitle + 2; font.weight: Font.DemiBold }
        }

        RowLayout {
            Layout.leftMargin: Theme.px(4)
            spacing: Theme.px(4)
            StyledText { Layout.fillWidth: true; text: Qt.formatDate(cal.month, "MMMM yyyy"); font.weight: Font.DemiBold }
            TextButton { visible: cal.offset !== 0; text: "Today"; onClicked: cal.offset = 0 }
            IconButton { size: Theme.px(32); icon: Theme.icon.chevronLeft; onClicked: cal.offset-- }
            IconButton { size: Theme.px(32); icon: Theme.icon.chevronRight; onClicked: cal.offset++ }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 7
            uniformCellWidths: true
            rowSpacing: Theme.px(2)
            columnSpacing: Theme.px(2)

            Repeater {
                model: 7
                StyledText {
                    required property int index
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.locale().dayName((Qt.locale().firstDayOfWeek + index) % 7, Locale.ShortFormat).slice(0, 2)
                    color: Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                    font.weight: Font.Medium
                }
            }

            Repeater {
                model: 42

                Item {
                    id: day
                    required property int index
                    readonly property date date: new Date(cal.start.getFullYear(), cal.start.getMonth(), cal.start.getDate() + index)
                    readonly property bool inMonth: date.getMonth() === cal.month.getMonth()
                    readonly property bool isToday: date.toDateString() === cal.today.toDateString()

                    Layout.fillWidth: true
                    implicitHeight: Theme.px(38)

                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.px(34)
                        height: width
                        radius: width / 2
                        color: root.accent
                        visible: day.isToday
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: day.date.getDate()
                        color: day.isToday ? Theme.contrast(root.accent) : day.inMonth ? Theme.on_surface : Theme.alpha(Theme.on_surface, 0.32)
                        font.weight: day.isToday ? Font.Bold : Font.Normal
                        font.features: { "tnum": 1 }
                    }
                }
            }
        }

        WheelHandler { onWheel: e => cal.offset += e.angleDelta.y > 0 ? -1 : 1 }
    }
}
