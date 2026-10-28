import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../utils"

PanelWindow {
    id: notifCenter

    visible: NotificationState.open

    anchors { top: true; right: true; bottom: true; left: true }

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-notifications"

    readonly property color accent: "#8ab4f8"
    readonly property real  accR: accent.r
    readonly property real  accG: accent.g
    readonly property real  accB: accent.b

    function closePanel() {
        NotificationState.open = false
    }

    onVisibleChanged: {
        if (visible) {
            focusScope.forceActiveFocus()
            refreshAll()
            pollTimer.start()
        } else {
            pollTimer.stop()
        }
    }

    // ── Audio state (PipeWire via wpctl) ───────────────────────────
    property real  volume: 0.5
    property bool  muted: false
    property real  micVolume: 0.5
    property bool  micMuted: false

    // ── Brightness state (ddcutil) ────────────────────────────────
    property int brightness: 50
    property int brightnessMax: 100
    property int displayIndex: 1
    property bool brightnessAvailable: true

    // ── Calendar state ────────────────────────────────────────────
    property var displayedDate: new Date()
    property var calendarCells: []
    property string clockText: ""

    function updateClock() {
        const d = new Date()
        clockText = d.toLocaleDateString(Qt.locale(), Locale.ShortFormat) + " · "
                  + d.toLocaleTimeString(Qt.locale(), "HH:mm")
    }

    Timer {
        id: clockTimer
        interval: 30000
        running: notifCenter.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: notifCenter.updateClock()
    }

    function rebuildCalendar() {
        const y = displayedDate.getFullYear()
        const m = displayedDate.getMonth()
        const first = new Date(y, m, 1)
        let startDay = first.getDay()                 // 0=Sun … 6=Sat
        startDay = (startDay + 6) % 7                 // shift to Mon-first
        const start = new Date(y, m, 1 - startDay)
        const cells = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(start)
            d.setDate(start.getDate() + i)
            cells.push(d)
        }
        calendarCells = cells
    }

    function prevMonth() {
        const d = new Date(displayedDate)
        d.setDate(1)
        d.setMonth(d.getMonth() - 1)
        displayedDate = d
    }
    function nextMonth() {
        const d = new Date(displayedDate)
        d.setDate(1)
        d.setMonth(d.getMonth() + 1)
        displayedDate = d
    }
    function jumpToToday() {
        displayedDate = new Date()
    }
    function isCurrentMonth(d) {
        return d.getMonth() === displayedDate.getMonth()
            && d.getFullYear() === displayedDate.getFullYear()
    }
    function isToday(d) {
        const t = new Date()
        return d.getDate() === t.getDate()
            && d.getMonth() === t.getMonth()
            && d.getFullYear() === t.getFullYear()
    }
    function monthName(d) {
        const names = ["January","February","March","April","May","June",
                       "July","August","September","October","November","December"]
        return names[d.getMonth()] + " " + d.getFullYear()
    }

    onDisplayedDateChanged: rebuildCalendar()
    Component.onCompleted: { rebuildCalendar(); updateClock() }

    // ── Refresh / polling ──────────────────────────────────────────
    function refreshAll() { refreshAudio(); refreshBrightness() }
    function refreshAudio() {
        readVolProc.running   = true
        readMicProc.running   = true
    }
    function refreshBrightness() { readBrightProc.running = true }

    Timer {
        id: pollTimer
        interval: 2000
        repeat: true
        onTriggered: notifCenter.refreshAll()
    }

    // ── wpctl readers ──────────────────────────────────────────────
    Process {
        id: readVolProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: data => {
            const m = data.match(/Volume:\s*([\d.]+)/)
            if (m) notifCenter.volume = parseFloat(m[1])
            notifCenter.muted = data.includes("[MUTED]")
        }
    }
    Process {
        id: readMicProc
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]
        stdout: data => {
            const m = data.match(/Volume:\s*([\d.]+)/)
            if (m) notifCenter.micVolume = parseFloat(m[1])
            notifCenter.micMuted = data.includes("[MUTED]")
        }
    }

    // ── wpctl writers ──────────────────────────────────────────────
    function setVolume(v) {
        volume = v
        const pct = Math.max(0, Math.min(150, Math.round(v * 100)))
        setVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", pct + "%"]
        setVolProc.running = true
    }
    function setMicVolume(v) {
        micVolume = v
        const pct = Math.max(0, Math.min(150, Math.round(v * 100)))
        setMicVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", pct + "%"]
        setMicVolProc.running = true
    }
    function toggleMute()      { toggleMuteProc.running = true }
    function toggleMicMute()   { toggleMicMuteProc.running = true }

    Process { id: setVolProc }
    Process { id: setMicVolProc }
    Process { id: toggleMuteProc;    command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@",   "toggle"] }
    Process { id: toggleMicMuteProc; command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"] }

    // ── ddcutil brightness ─────────────────────────────────────────
    Process {
        id: readBrightProc
        command: ["ddcutil", "-d", String(notifCenter.displayIndex), "getvcp", "10"]
        stdout: data => {
            // "VCP 10 C 47 60" → current=47, max=60
            const m = data.match(/VCP\s+10\s+C\s+(\d+)\s+(\d+)/)
            if (m) {
                notifCenter.brightness     = parseInt(m[1])
                notifCenter.brightnessMax  = parseInt(m[2])
                notifCenter.brightnessAvailable = true
            }
        }
        onExited: (code) => {
            if (code !== 0) notifCenter.brightnessAvailable = false
        }
    }
    function setBrightness(v) {
        brightness = v
        setBrightProc.command = ["ddcutil", "-d", String(displayIndex),
                                 "setvcp", "10", String(v)]
        setBrightProc.running = true
    }
    Process { id: setBrightProc }

    // ── Notification server ───────────────────────────────────────
    NotificationServer {
        id: notifServer
        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        onNotification: notification => { notification.tracked = true }
    }

    function urgencyColor(u) {
        if (u === NotificationUrgency.Critical) return "#f28b82"
        if (u === NotificationUrgency.Low)      return "#9aa0a6"
        return notifCenter.accent
    }

    // ── Click-outside-to-close ────────────────────────────────────
    MouseArea {
        id: outsideArea
        anchors.fill: parent
        propagateComposedEvents: false
        onClicked: notifCenter.closePanel()
    }

    // ── Esc-to-close + card ───────────────────────────────────────
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: notifCenter.closePanel()

        Item {
            id: card
            width: 420
            anchors { top: parent.top; right: parent.right; bottom: parent.bottom; margins: 10 }

            Rectangle {
                anchors.fill: parent
                radius: 20
                color: Qt.rgba(0.07, 0.07, 0.09, 0.88)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.09)
            }

            // Eat clicks that land on the card itself
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }

            // ── Single scroll container, everything stacked ─────────
            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: width
                contentHeight: contentCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                ColumnLayout {
                    id: contentCol
                    width: flick.width
                    spacing: 14

                    // ══════ Header ═══════════════════════════════════
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        spacing: 10

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: "Control Center"
                                color: "#f5f5f5"
                                font.pixelSize: 17
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: notifCenter.clockText
                                color: Qt.rgba(1, 1, 1, 0.45)
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            visible: notifServer.trackedNotifications.values.length > 0
                            Layout.preferredWidth: clearLabel.implicitWidth + 20
                            Layout.preferredHeight: 30
                            radius: 15
                            color: clearArea.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.1)
                            Behavior on color { ColorAnimation { duration: 120 } }
                            Text {
                                id: clearLabel
                                anchors.centerIn: parent
                                text: "Clear all"
                                color: Qt.rgba(1, 1, 1, 0.75)
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: clearArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const items = notifServer.trackedNotifications.values.slice()
                                    for (const n of items) n.dismiss()
                                }
                            }
                        }
                    }

                    // ══════ Quick controls (volume / mic / brightness) ═
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        spacing: 10

                        // Volume row
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: notifCenter.muted ? "🔇" : "🔊"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: "Volume"
                                    color: Qt.rgba(1, 1, 1, 0.85)
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: notifCenter.muted
                                          ? "Muted"
                                          : Math.round(notifCenter.volume * 100) + "%"
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 48
                                    horizontalAlignment: Text.AlignRight
                                }
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: muteArea.containsMouse
                                           ? Qt.rgba(1, 1, 1, 0.12)
                                           : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: notifCenter.muted ? "🔇" : "🔊"
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: muteArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notifCenter.toggleMute()
                                    }
                                }
                            }
                            Slider {
                                id: volSlider
                                Layout.fillWidth: true
                                from: 0; to: 1.5
                                stepSize: 0.01
                                value: notifCenter.volume
                                enabled: !notifCenter.muted
                                onMoved: notifCenter.volume = value
                                onPressedChanged: {
                                    if (!pressed) notifCenter.setVolume(value)
                                }
                            }
                        }

                        // Mic row
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: notifCenter.micMuted ? "🚫" : "🎤"
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: "Microphone"
                                    color: Qt.rgba(1, 1, 1, 0.85)
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: notifCenter.micMuted
                                          ? "Muted"
                                          : Math.round(notifCenter.micVolume * 100) + "%"
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 48
                                    horizontalAlignment: Text.AlignRight
                                }
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: micMuteArea.containsMouse
                                           ? Qt.rgba(1, 1, 1, 0.12)
                                           : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: notifCenter.micMuted ? "🚫" : "🎤"
                                        font.pixelSize: 12
                                    }
                                    MouseArea {
                                        id: micMuteArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notifCenter.toggleMicMute()
                                    }
                                }
                            }
                            Slider {
                                id: micSlider
                                Layout.fillWidth: true
                                from: 0; to: 1.5
                                stepSize: 0.01
                                value: notifCenter.micVolume
                                enabled: !notifCenter.micMuted
                                onMoved: notifCenter.micVolume = value
                                onPressedChanged: {
                                    if (!pressed) notifCenter.setMicVolume(value)
                                }
                            }
                        }

                        // Brightness row
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text {
                                    text: "☀"
                                    font.pixelSize: 14
                                    color: notifCenter.brightnessAvailable
                                           ? Qt.rgba(1, 1, 1, 0.9)
                                           : Qt.rgba(1, 1, 1, 0.25)
                                }
                                Text {
                                    text: "Brightness"
                                    color: Qt.rgba(1, 1, 1, 0.85)
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: notifCenter.brightnessAvailable
                                          ? Math.round(notifCenter.brightness
                                                       / notifCenter.brightnessMax * 100) + "%"
                                          : "N/A"
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 48
                                    horizontalAlignment: Text.AlignRight
                                }
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: brightRefreshArea.containsMouse
                                           ? Qt.rgba(1, 1, 1, 0.12)
                                           : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "⟳"
                                        font.pixelSize: 14
                                        color: "#f5f5f5"
                                    }
                                    MouseArea {
                                        id: brightRefreshArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: notifCenter.refreshBrightness()
                                    }
                                }
                            }
                            Slider {
                                id: brightSlider
                                Layout.fillWidth: true
                                from: 0
                                to: Math.max(100, notifCenter.brightnessMax)
                                stepSize: 1
                                value: notifCenter.brightness
                                enabled: notifCenter.brightnessAvailable
                                onMoved: notifCenter.brightness = Math.round(value)
                                onPressedChanged: {
                                    if (!pressed) notifCenter.setBrightness(Math.round(value))
                                }
                            }
                        }
                    }

                    // Subtle divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.06)
                    }

                    // ══════ Calendar ═══════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: notifCenter.monthName(notifCenter.displayedDate)
                                color: "#f5f5f5"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            // Today pill
                            Rectangle {
                                visible: {
                                    const t = new Date()
                                    return t.getMonth() !== notifCenter.displayedDate.getMonth()
                                        || t.getFullYear() !== notifCenter.displayedDate.getFullYear()
                                }
                                radius: 10
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: todayLbl.implicitWidth + 16
                                color: todayArea.containsMouse
                                       ? Qt.rgba(notifCenter.accR, notifCenter.accG, notifCenter.accB, 0.25)
                                       : Qt.rgba(notifCenter.accR, notifCenter.accG, notifCenter.accB, 0.12)
                                Behavior on color { ColorAnimation { duration: 120 } }
                                Text {
                                    id: todayLbl
                                    anchors.centerIn: parent
                                    text: "Today"
                                    color: notifCenter.accent
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                                MouseArea {
                                    id: todayArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: notifCenter.jumpToToday()
                                }
                            }
                            // Prev / next
                            Repeater {
                                model: [{icon: "‹", step: -1}, {icon: "›", step: 1}]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: 26; height: 26; radius: 13
                                    color: navMouse.containsMouse
                                           ? Qt.rgba(1, 1, 1, 0.12)
                                           : "transparent"
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.icon
                                        color: "#f5f5f5"
                                        font.pixelSize: 16
                                    }
                                    MouseArea {
                                        id: navMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.step < 0
                                                   ? notifCenter.prevMonth()
                                                   : notifCenter.nextMonth()
                                    }
                                }
                            }
                        }

                        // Day-of-week header row
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Repeater {
                                model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                                delegate: Text {
                                    required property string modelData
                                    text: modelData
                                    color: Qt.rgba(1, 1, 1, 0.35)
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        // Day grid
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            columnSpacing: 2
                            rowSpacing: 2
                            Repeater {
                                model: notifCenter.calendarCells
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 34
                                    radius: 8
                                    color: notifCenter.isToday(modelData)
                                           ? Qt.rgba(notifCenter.accR, notifCenter.accG, notifCenter.accB, 0.28)
                                           : (cellMouse.containsMouse
                                              && notifCenter.isCurrentMonth(modelData)
                                                ? Qt.rgba(1, 1, 1, 0.06)
                                                : "transparent")
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.getDate()
                                        color: notifCenter.isToday(modelData)
                                               ? notifCenter.accent
                                               : (notifCenter.isCurrentMonth(modelData)
                                                  ? Qt.rgba(1, 1, 1, 0.85)
                                                  : Qt.rgba(1, 1, 1, 0.22))
                                        font.pixelSize: 12
                                        font.weight: notifCenter.isToday(modelData)
                                                     ? Font.DemiBold
                                                     : Font.Normal
                                    }
                                    MouseArea {
                                        id: cellMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            const d = new Date(modelData)
                                            notifCenter.displayedDate = d
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Subtle divider
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.06)
                    }

                    // ══════ Notifications section ═══════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.bottomMargin: 16
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Notifications"
                                color: "#f5f5f5"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }
                            Text {
                                text: notifServer.trackedNotifications.values.length === 0
                                      ? "All caught up"
                                      : notifServer.trackedNotifications.values.length + " unread"
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.pixelSize: 11
                            }
                        }

                        // Empty state
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 24
                            Layout.bottomMargin: 24
                            visible: notifServer.trackedNotifications.values.length === 0
                            spacing: 8
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "🔔"
                                font.pixelSize: 28
                                opacity: 0.3
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "No notifications"
                                color: Qt.rgba(1, 1, 1, 0.35)
                                font.pixelSize: 12
                            }
                        }

                        // Notification list
                        ListView {
                            id: list
                            Layout.fillWidth: true
                            visible: notifServer.trackedNotifications.values.length > 0
                            spacing: 8
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds
                            interactive: false   // outer Flickable handles scrolling
                            model: notifServer.trackedNotifications

                            add: Transition {
                                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 160 }
                                NumberAnimation { properties: "y"; from: -12; duration: 160; easing.type: Easing.OutCubic }
                            }
                            removeDisplaced: Transition {
                                NumberAnimation { properties: "y"; duration: 160; easing.type: Easing.OutCubic }
                            }
                            remove: Transition {
                                NumberAnimation { properties: "opacity"; to: 0; duration: 120 }
                            }

                            delegate: Item {
                                id: delegateRoot
                                width: ListView.view.width
                                height: cardBg.height

                                Rectangle {
                                    id: cardBg
                                    width: parent.width
                                    height: contentCol2.implicitHeight + 24
                                    radius: 14
                                    color: hoverArea.containsMouse
                                           ? Qt.rgba(1, 1, 1, 0.07)
                                           : Qt.rgba(1, 1, 1, 0.045)
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, 0.06)
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Rectangle {
                                        width: 3
                                        radius: 1.5
                                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 8 }
                                        color: notifCenter.urgencyColor(modelData.urgency)
                                        opacity: 0.85
                                    }

                                    RowLayout {
                                        id: contentRow
                                        anchors { fill: parent; margins: 12; leftMargin: 20 }
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 36
                                            Layout.preferredHeight: 36
                                            Layout.alignment: Qt.AlignTop
                                            radius: 10
                                            color: Qt.rgba(1, 1, 1, 0.08)
                                            visible: !!(modelData.image || modelData.appIcon)
                                            Image {
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                fillMode: Image.PreserveAspectFit
                                                source: modelData.image
                                                     || (modelData.appIcon
                                                         ? "image://icon/" + modelData.appIcon
                                                         : "")
                                                asynchronous: true
                                            }
                                        }

                                        ColumnLayout {
                                            id: contentCol2
                                            Layout.fillWidth: true
                                            spacing: 3

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 6
                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.summary || modelData.appName || "Notification"
                                                    color: "#f2f2f2"
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    visible: !!modelData.appName && modelData.summary
                                                    text: modelData.appName
                                                    color: Qt.rgba(1, 1, 1, 0.35)
                                                    font.pixelSize: 10
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                visible: !!modelData.body
                                                text: modelData.body
                                                textFormat: notifServer.bodyMarkupSupported
                                                            ? Text.RichText
                                                            : Text.PlainText
                                                color: Qt.rgba(1, 1, 1, 0.62)
                                                font.pixelSize: 11
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 3
                                                elide: Text.ElideRight
                                            }

                                            Flow {
                                                Layout.fillWidth: true
                                                Layout.topMargin: 4
                                                visible: modelData.actions && modelData.actions.length > 0
                                                spacing: 6
                                                Repeater {
                                                    model: modelData.actions
                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        width: actionLabel.implicitWidth + 16
                                                        height: 24
                                                        radius: 12
                                                        color: actionArea.containsMouse
                                                               ? Qt.rgba(notifCenter.accR, notifCenter.accG, notifCenter.accB, 0.28)
                                                               : Qt.rgba(notifCenter.accR, notifCenter.accG, notifCenter.accB, 0.15)
                                                        Behavior on color { ColorAnimation { duration: 120 } }
                                                        Text {
                                                            id: actionLabel
                                                            anchors.centerIn: parent
                                                            text: modelData.text
                                                            color: notifCenter.accent
                                                            font.pixelSize: 10
                                                        }
                                                        MouseArea {
                                                            id: actionArea
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: modelData.invoke()
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 22
                                            Layout.preferredHeight: 22
                                            Layout.alignment: Qt.AlignTop
                                            radius: 11
                                            color: closeArea.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                            Behavior on color { ColorAnimation { duration: 100 } }
                                            Text {
                                                anchors.centerIn: parent
                                                text: "✕"
                                                font.pixelSize: 10
                                                color: Qt.rgba(1, 1, 1, closeArea.containsMouse ? 0.85 : 0.4)
                                            }
                                            MouseArea {
                                                id: closeArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: modelData.dismiss()
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: hoverArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        z: -1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
