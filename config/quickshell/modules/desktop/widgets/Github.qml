import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.components

// GitHub contribution calendar: a column per week, filling the card width.
// [desktop.github] user and token_file (a token with the read:user scope, nothing else in the file).
Card {
    id: root
    widget: "github"

    readonly property string user: cfg.user ?? ""
    readonly property int cell: Theme.px(14)
    readonly property int cellGap: Theme.px(4)
    readonly property int weekCount: Math.max(1, Math.floor((width - Theme.pad * 2 + cellGap) / (cell + cellGap)))
    property string token
    property var weeks: []        // [[{date, contributionCount}]]
    property string error
    property var hovered: null

    readonly property var shown: weeks.slice(-weekCount)
    readonly property var shownDays: shown.reduce((all, w) => all.concat(w), [])
    readonly property int total: shownDays.reduce((n, d) => n + d.contributionCount, 0)
    readonly property int peak: shownDays.reduce((m, d) => Math.max(m, d.contributionCount), 1)

    function shade(count) {
        if (count === 0) return Theme.layerHigh
        return Theme.alpha(root.accent, [0.3, 0.5, 0.75, 1][Math.min(3, Math.floor(count / peak * 4))])
    }

    function fetch() {
        if (!token || !user) return
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
            let r = null
            try { r = JSON.parse(xhr.responseText) } catch (e) {}
            const weeks = r?.data?.user?.contributionsCollection?.contributionCalendar?.weeks
            if (Array.isArray(weeks)) {
                root.weeks = weeks.map(w => w?.contributionDays ?? []).filter(d => d.length)
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

    CardHeader {
        icon: Theme.icon.github
        title: root.user || "GitHub"
        accent: root.accent
        Rectangle {
            visible: root.shownDays.length > 0
            implicitWidth: chip.implicitWidth + Theme.pad
            implicitHeight: Theme.px(26)
            radius: height / 2
            color: Theme.layerHigh
            StyledText {
                id: chip
                anchors.centerIn: parent
                text: `<b>${root.total}</b>  ·  ${(root.total / Math.max(1, root.shownDays.length)).toFixed(1)}/day`
                textFormat: Text.StyledText
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSmall
            }
        }
    }

    Row {
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
                        radius: Theme.px(4)
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
        text: !root.user ? "Set [desktop.github] user in hecate.toml"
            : root.error ? root.error
            : root.hovered ? `${root.hovered.contributionCount} contribution${root.hovered.contributionCount === 1 ? "" : "s"} on ${Qt.formatDate(new Date(root.hovered.date + "T12:00"), "ddd d MMM")}`
            : root.shown.length ? `Last ${root.weekCount} weeks` : "Loading…"
        color: root.error ? Theme.error : Theme.on_surface_variant
        font.pixelSize: Theme.fontSmall
        Layout.alignment: Qt.AlignHCenter
    }
}
