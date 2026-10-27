import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.components

// GitHub contribution calendar: a column per week, filling the card width.
Card {
    id: root
    widget: "github"

    readonly property string user: cfg.user ?? "Nurysso"
    readonly property int cell: 14
    readonly property int cellGap: 4
    readonly property int weekCount: Math.floor((width - Theme.pad * 2 + cellGap) / (cell + cellGap))
    property string token
    property var weeks: []        // [[{date, contributionCount}]]
    property string error
    property var hovered: null

    readonly property var shown: weeks.slice(-weekCount)
    readonly property var shownDays: [].concat(...shown)
    readonly property int total: shownDays.reduce((n, d) => n + d.contributionCount, 0)
    readonly property int peak: Math.max(1, ...shownDays.map(d => d.contributionCount))

    function shade(count) {
        if (count === 0) return Theme.alpha(Theme.on_surface, 0.08)
        return Theme.alpha(root.accent, [0.3, 0.5, 0.75, 1][Math.min(3, Math.floor(count / peak * 4))])
    }

    function fetch() {
        if (!token) return
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            const r = xhr.status === 200 ? JSON.parse(xhr.responseText) : null
            const cal = r?.data?.user?.contributionsCollection.contributionCalendar
            if (cal) {
                root.weeks = cal.weeks.map(w => w.contributionDays)
                root.error = ""
            } else {
                root.error = r?.errors?.[0]?.message ?? (xhr.status === 401 ? "GitHub token rejected" : "GitHub unavailable")
            }
        }
        xhr.open("POST", "https://api.github.com/graphql")
        xhr.setRequestHeader("Authorization", "bearer " + token)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.send(JSON.stringify({
            query: "query($login: String!) { user(login: $login) { contributionsCollection { contributionCalendar { weeks { contributionDays { date contributionCount } } } } } }",
            variables: { login: user }
        }))
    }

    FileView {
        path: Config.expand(root.cfg.token_file ?? "~/.config/tokens/gpat.txt")
        printErrors: false
        onLoaded: { root.token = text().trim(); root.fetch() }
        onLoadFailed: root.error = "No token in " + path.replace(Config.home, "~")
    }
    onUserChanged: fetch()
    Timer { running: true; repeat: true; interval: 30 * 60000; onTriggered: root.fetch() }

    RowLayout {
        spacing: Theme.gap
        Rectangle {
            implicitWidth: 32
            implicitHeight: 32
            radius: 16
            color: Theme.alpha(root.accent, 0.16)
            Icon { anchors.centerIn: parent; text: Theme.icon.github; color: root.accent; font.pixelSize: 16 }
        }
        StyledText { text: root.user; font.weight: Font.DemiBold; Layout.fillWidth: true }
        Rectangle {
            visible: root.shownDays.length > 0
            implicitWidth: chip.implicitWidth + Theme.pad
            implicitHeight: 26
            radius: 13
            color: Theme.surface_container_highest
            StyledText {
                id: chip
                anchors.centerIn: parent
                text: `<b>${root.total}</b>  ·  ${(root.total / Math.max(1, root.shownDays.length)).toFixed(1)}/day`
                textFormat: Text.StyledText
                color: Theme.on_surface_variant
                font.pixelSize: 12
            }
        }
    }

    Row {
        id: grid
        Layout.fillWidth: true
        spacing: root.cellGap
        visible: root.shown.length > 0

        Repeater {
            model: root.shown
            Column {
                required property var modelData
                spacing: root.cellGap
                Repeater {
                    model: modelData
                    Rectangle {
                        required property var modelData
                        width: root.cell
                        height: root.cell
                        radius: 4
                        color: root.shade(modelData.contributionCount)
                        scale: hover.containsMouse ? 1.25 : 1
                        Behavior on scale { Anim { duration: Theme.animFast } }
                        Behavior on color { CAnim {} }
                        MouseArea {
                            id: hover
                            anchors.fill: parent
                            hoverEnabled: true
                            onContainsMouseChanged: root.hovered = containsMouse ? parent.modelData : null
                        }
                    }
                }
            }
        }
    }

    StyledText {
        text: root.error ? root.error
            : root.hovered ? `${root.hovered.contributionCount} contribution${root.hovered.contributionCount === 1 ? "" : "s"} on ${Qt.formatDate(new Date(root.hovered.date + "T12:00"), "ddd d MMM")}`
            : root.shown.length ? `Last ${root.weekCount} weeks` : "Loading…"
        color: root.error ? Theme.error : Theme.on_surface_variant
        font.pixelSize: Theme.fontSize - 2
        Layout.alignment: Qt.AlignHCenter
    }
}
