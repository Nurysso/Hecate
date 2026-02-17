import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import "../utils"

PanelWindow {
    id: root

    implicitWidth: calculateWidth()
    implicitHeight: 220
    visible: true
    color: "transparent"
    mask: Region { item: container }

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-contributions"
    WlrLayershell.exclusiveZone: -1

    property int visibilityCheckCount: 0

    Timer {
        id: persistenceTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!root.visible) {
                visibilityCheckCount++
                root.visible = true
                if (visibilityCheckCount > 3) visibilityCheckCount = 0
            } else {
                visibilityCheckCount = 0
            }
        }
    }

    Component.onCompleted: { visible = true }

    anchors {
        top: true
        right: true
    }
    margins {
        top: 50
        right: 40
    }

    property string githubToken: ""
    property string username: "Nurysso"
    property string apiResponse: ""
    property var contributionsData: []
    property int totalContributions: 0
    property int maxContributions: 0
    property int daysToShow: 30
    property int cellSize: 13
    property int cellSpacing: 3

    function calculateWidth() {
        const columns = 7
        const rows = Math.ceil(daysToShow / columns)
        const gridWidth = (columns * cellSize) + ((columns - 1) * cellSpacing)
        return gridWidth + 80
    }

    Process {
        id: tokenReader
        command: ["cat", `${Quickshell.env("HOME")}/.config/tokens/gpat.txt`]
        running: true
        stdout: SplitParser {
            onRead: data => { githubToken = data.trim() }
        }
        onRunningChanged: {
            if (!running && githubToken) fetchContributions.running = true
        }
    }

    Process {
        id: fetchContributions
        running: false
        command: [
            "curl", "-s",
            "-H", `Authorization: bearer ${githubToken}`,
            "-H", "Content-Type: application/json",
            "-X", "POST",
            "-d", JSON.stringify({
                query: `{
                    user(login: "${username}") {
                        contributionsCollection {
                            contributionCalendar {
                                weeks {
                                    contributionDays {
                                        date
                                        contributionCount
                                    }
                                }
                            }
                        }
                    }
                }`
            }),
            "https://api.github.com/graphql"
        ]
        stdout: SplitParser {
            onRead: data => {
                apiResponse = apiResponse ? apiResponse + data : data
            }
        }
        onRunningChanged: {
            if (!running && apiResponse) {
                parseContributions()
                apiResponse = ""
            }
        }
    }

    function parseContributions() {
        try {
            const response = JSON.parse(apiResponse)
            if (!response.data || !response.data.user) return

            const weeks = response.data.user.contributionsCollection.contributionCalendar.weeks
            let allDays = []
            for (let i = 0; i < weeks.length; i++) {
                const days = weeks[i].contributionDays
                for (let j = 0; j < days.length; j++) allDays.push(days[j])
            }

            const lastNDays = allDays.slice(-daysToShow)
            let total = 0, max = 0
            for (let i = 0; i < lastNDays.length; i++) {
                const count = lastNDays[i].contributionCount
                total += count
                if (count > max) max = count
            }

            contributionsData = lastNDays
            totalContributions = total
            maxContributions = max
        } catch (e) {
            console.log("Error parsing contributions:", e)
        }
    }


    function hexToRgb(hex) {
        const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
        return result ? {
            r: parseInt(result[1], 16),
            g: parseInt(result[2], 16),
            b: parseInt(result[3], 16)
        } : { r: 0, g: 0, b: 0 }
    }

    function getContributionColor(count) {
    if (count === 0 || maxContributions === 0) return "#1a1a1a"

    const intensity = count / maxContributions
    const base = hexToRgb(ColorManager.accentColor)

    // Tier 1: Very Dull Accent (Dimmest)
    if (intensity <= 0.25)
        return Qt.rgba(base.r/255, base.g/255, base.b/255, 0.2) // 20% Opacity

    // Tier 2: Muted Accent
    if (intensity <= 0.5)
        return Qt.rgba(base.r/255, base.g/255, base.b/255, 0.45) // 45% Opacity

    // Tier 3: Strong Accent
    if (intensity <= 0.75)
        return Qt.rgba(base.r/255, base.g/255, base.b/255, 0.7) // 70% Opacity

    // Tier 4: Pure Accent (Max Brightness)
    return root.accentColor
}

    function formatDate(dateStr) {
        const date = new Date(dateStr)
        const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec']
        return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()}`
    }

    Timer {
        interval: 1800000
        running: true
        repeat: true
        triggeredOnStart: false
        onTriggered: { if (githubToken) fetchContributions.running = true }
    }

    Item {
        id: container
        anchors.fill: parent

        Rectangle {
            anchors.fill: innerPanel
            anchors.margins: -6
            radius: innerPanel.radius + 6
            color: "transparent"
            border.width: 0
            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: parent.radius + 4
                color: "#000000"
                opacity: 0.18
                z: -3
            }
        }

        Rectangle {
            id: innerPanel
            anchors.fill: parent
            anchors.margins: 8
            radius: 14
            color: ColorManager.bgColor
            opacity: 0.92

            // Subtle top highlight border
            // Rectangle {
            //     anchors.top: parent.top
            //     anchors.left: parent.left
            //     anchors.right: parent.right
            //     height: 1
            //     radius: parent.radius
            //     color: ColorManager.fgColor
            //     opacity: 0.06
            // }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                // ── Header row ──
                Row {
                    width: parent.width
                    spacing: 0

                    // Icon + title
                    Row {
                        spacing: 8
                        anchors.verticalCenter: parent.verticalCenter

                        // Git icon dot
                        Rectangle {
                                width: 44
                                height: 24
                                radius: width / 2
                                color: "transparent"
                                anchors.verticalCenter: parent.verticalCenter

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: ColorManager.accentColor
                                    opacity: 0.2
                                }
                                Item {
                                    width: 15
                                    height: 1
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: "\ue709"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    color: ColorManager.accentColor
                                    style: Text.Normal
                                }
                            }

                        Text {
                            text: username
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.5
                            color: ColorManager.fgDimColor
                            style: Text.Raised
                            styleColor: "#000000"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Item { width: parent.width - statsChip.width - 130; height: 1 }

                    // Stats chip
                    Rectangle {
                        id: statsChip
                        color: ColorManager.bgLightColor
                        radius: 20
                        width: statsRow.width + 16
                        height: statsRow.height + 8
                        anchors.verticalCenter: parent.verticalCenter

                        // Chip border
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.width: 1
                            border.color: ColorManager.accentColor
                            opacity: 0.3
                        }

                        Row {
                            id: statsRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: totalContributions
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                color: ColorManager.primaryColor
                                style: Text.Raised
                                styleColor: "#000000"
                            }

                            Rectangle {
                                width: 1
                                height: 10
                                color: ColorManager.mutedColor
                                opacity: 0.4
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: `${(totalContributions / daysToShow).toFixed(1)}/day`
                                font.pixelSize: 11
                                color: ColorManager.fgDimColor
                                style: Text.Raised
                                styleColor: "#000000"
                            }
                        }
                    }
                }

                //  Contribution grid
                Grid {
                    id: contributionGrid
                    columns: 7
                    columnSpacing: cellSpacing
                    rowSpacing: cellSpacing
                    anchors.horizontalCenter: parent.horizontalCenter

                    Repeater {
                        model: root.contributionsData

                        Rectangle {
                            width: cellSize
                            height: cellSize
                            radius: 3
                            color: contributionsData.length > 0 ? getContributionColor(modelData.contributionCount) : ColorManager.bgLightColor
                            border.width: cellHover.containsMouse ? 1 : 0
                            border.color: ColorManager.accentColor

                            Rectangle {
                                visible: modelData.contributionCount > 0
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 1
                                anchors.leftMargin: 1
                                width: parent.width - 2
                                height: 1
                                radius: 1
                                color: "#ffffff"
                                opacity: 0.15
                            }

                            Rectangle {
                                visible: cellHover.containsMouse
                                width: tipCol.width + 18
                                height: tipCol.height + 12
                                radius: 8
                                color: ColorManager.bgDarkColor
                                border.width: 1
                                border.color: ColorManager.accentColor
                                opacity: 0.97
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 6
                                anchors.horizontalCenter: parent.horizontalCenter
                                z: 100

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    radius: parent.radius + 3
                                    color: "#000000"
                                    opacity: 0.3
                                    z: -1
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 2
                                    radius: parent.radius
                                    color: ColorManager.accentColor
                                    opacity: 0.8
                                }

                                Column {
                                    id: tipCol
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        text: `${modelData.contributionCount} commit${modelData.contributionCount !== 1 ? "s" : ""}`
                                        font.pixelSize: 11
                                        font.weight: Font.SemiBold
                                        color: ColorManager.fgColor
                                        horizontalAlignment: Text.AlignHCenter
                                        style: Text.Raised
                                        styleColor: "#000000"
                                    }

                                    Text {
                                        text: formatDate(modelData.date)
                                        font.pixelSize: 9
                                        color: ColorManager.fgDimColor
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                }
                            }

                            MouseArea {
                                id: cellHover
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            Behavior on color { ColorAnimation { duration: 200 } }
                            Behavior on border.width { NumberAnimation { duration: 100 } }
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                            scale: cellHover.containsMouse ? 1.3 : 1.0
                        }
                    }
                }

                Text {
                    text: `last ${daysToShow} days`
                    font.pixelSize: 9
                    font.letterSpacing: 1.2
                    color: ColorManager.mutedColor
                    opacity: 0.5
                    anchors.horizontalCenter: parent.horizontalCenter
                    style: Text.Raised
                    styleColor: "#000000"
                }
            }

            Text {
                visible: contributionsData.length === 0
                anchors.centerIn: parent
                text: "loading..."
                font.pixelSize: 12
                font.letterSpacing: 1.5
                color: ColorManager.mutedColor
                opacity: 0.4
                style: Text.Raised
                styleColor: "#000000"
            }
        }
    }
}
