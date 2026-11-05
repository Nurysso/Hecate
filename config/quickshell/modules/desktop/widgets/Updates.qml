import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.config
import qs.components

// Pending package updates, and on Arch the latest news posts (worth a read before a big update).
// Arch counts repo packages with checkupdates (pacman-contrib; without it, pacman's last-synced
// database) and AUR ones with paru or yay; Fedora uses dnf.
// [desktop.updates] interval (minutes), packages (rows shown), news (true/false), news_count,
// command (what "Update" runs, in a shell)
Card {
    id: root
    widget: "updates"

    readonly property int interval: Math.max(5, Number(cfg.interval ?? 60) || 60)
    readonly property int shownPackages: Math.max(0, Math.min(15, Number(cfg.packages ?? 5)))
    readonly property int shownNews: Math.max(0, Math.min(8, Number(cfg.news_count ?? 3)))
    readonly property bool wantNews: cfg.news !== false && shownNews > 0
    readonly property string command: cfg.command ?? "kitty -e " + Config.home + "/.config/hecate/scripts/install-updates.sh"

    property var packages: []     // [{ aur, name, from, to }]
    property var news: []         // [{ title, link, date }]
    property bool arch
    property bool unsupported
    property bool stale           // no checkupdates, so the pacman database may be old
    property bool checked
    property date lastCheck

    readonly property int total: packages.length
    readonly property int aur: packages.filter(p => p.aur).length
    // the same thresholds as check-update.sh: more than 25 shifts to tertiary, more than 100 to error
    readonly property color level: total > 100 ? Theme.error : total > 25 ? Theme.tertiary : accent

    function check() { if (!scan.running) scan.running = true }
    function open(link) { Quickshell.execDetached(["xdg-open", link]) }

    function parseList(text) {
        const out = []
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab < 0) continue
            const kind = line.slice(0, tab)
            const rest = line.slice(tab + 1)
            if (kind === "U") { root.unsupported = true; continue }
            if (kind === "X") { root.arch = true; continue }
            if (kind === "F") { root.stale = true; continue }
            const m = rest.match(/^(\S+) (\S+)(?: -> (\S+))?/)
            if (m && (kind === "P" || kind === "A")) out.push({ aur: kind === "A", name: m[1], from: m[3] ? m[2] : "", to: m[3] ?? m[2] })
        }
        return out
    }

    Process {
        id: scan
        command: ["sh", "-c", `
            if command -v pacman >/dev/null; then
                printf 'X\\t\\n'
                if command -v checkupdates >/dev/null; then checkupdates 2>/dev/null
                else printf 'F\\t\\n'; pacman -Qu 2>/dev/null; fi | sed '/^F\\t/!s/^/P\\t/'
                for h in paru yay; do
                    command -v $h >/dev/null && { $h -Qua 2>/dev/null | sed 's/^/A\\t/'; break; }
                done
            elif command -v dnf >/dev/null; then
                dnf check-update -q 2>/dev/null | awk 'NF==3 && $1 ~ /\\./ { print "P\\t" $1 " " $2 }'
            else
                printf 'U\\t\\n'
            fi`]
        onStarted: { root.unsupported = false; root.stale = false }
        stdout: StdioCollector {
            onStreamFinished: {
                root.packages = root.parseList(text)
                root.checked = true
                root.lastCheck = new Date()
                if (root.arch && root.wantNews && !root.news.length) root.fetchNews()
            }
        }
    }
    Timer { running: true; repeat: true; triggeredOnStart: true; interval: root.interval * 60000; onTriggered: root.check() }
    Timer { running: root.arch && root.wantNews; repeat: true; interval: 6 * 3600000; onTriggered: root.fetchNews() }

    function decode(s) {
        return s.replace(/<!\[CDATA\[|\]\]>/g, "").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
                .replace(/&quot;/g, "\"").replace(/&#0?39;|&#x27;/g, "'").replace(/&amp;/g, "&").trim()
    }
    function fetchNews() {
        const xhr = new XMLHttpRequest()
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.status !== 200) return
            const out = []
            const item = /<item>([\s\S]*?)<\/item>/g
            let m
            while ((m = item.exec(xhr.responseText)) && out.length < 8) {
                const tag = t => decode(m[1].match(new RegExp(`<${t}>([\\s\\S]*?)</${t}>`))?.[1] ?? "")
                const link = tag("link")
                if (/^https:\/\//.test(link)) out.push({ title: tag("title"), link: link, date: new Date(tag("pubDate")) })
            }
            root.news = out
        }
        xhr.open("GET", "https://archlinux.org/feeds/news/")
        xhr.send()
    }

    CardHeader {
        icon: Theme.icon.update
        title: "Updates"
        accent: root.accent
        StyledText {
            visible: root.checked
            text: Qt.formatTime(root.lastCheck, "hh:mm")
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }
        IconButton {
            size: Theme.px(28)
            icon: Theme.icon.refresh
            fg: Theme.on_surface_variant
            opacity: scan.running ? 0.4 : 1
            onClicked: root.check()
        }
    }

    // the count, how it splits, and the button
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.px(12)
        visible: !root.unsupported

        StyledText {
            text: root.checked ? root.total : "…"
            color: root.total ? root.level : root.accent
            font.pixelSize: Theme.px(36)
            font.weight: Font.Bold
            font.features: { "tnum": 1 }
            Behavior on color { CAnim {} }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            StyledText {
                text: !root.checked ? "Checking…" : root.total ? (root.total === 1 ? "update available" : "updates available") : "Up to date"
                font.weight: Font.Medium
            }
            StyledText {
                visible: root.total > 0
                text: root.aur ? `${root.total - root.aur} repo  ·  ${root.aur} AUR` : "from the repositories"
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSmall
            }
        }
        TextButton {
            visible: root.total > 0
            icon: Theme.icon.download
            text: "Update"
            onClicked: Quickshell.execDetached(["sh", "-c", root.command])
        }
    }

    StyledText {
        visible: root.unsupported
        text: "Neither pacman nor dnf is installed"
        color: Theme.on_surface_variant
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.px(4)
        visible: root.total > 0 && root.shownPackages > 0

        Repeater {
            model: root.packages.slice(0, root.shownPackages)
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: Theme.gap
                StyledText { Layout.fillWidth: true; text: modelData.name; font.pixelSize: Theme.fontSmall + 1 }
                StyledText {
                    text: modelData.from ? `${modelData.from}  →  ${modelData.to}` : modelData.to
                    color: Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                    Layout.maximumWidth: Theme.px(190)
                }
            }
        }
        StyledText {
            visible: root.total > root.shownPackages
            text: `+ ${root.total - root.shownPackages} more`
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }
    }

    StyledText {
        visible: root.stale && root.total > 0
        text: "Install pacman-contrib for a fresh check"
        color: Theme.outline
        font.pixelSize: Theme.fontTiny
    }

    // Arch news
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.px(2)
        visible: root.arch && root.wantNews && root.news.length > 0

        Rectangle { Layout.fillWidth: true; Layout.bottomMargin: Theme.px(6); implicitHeight: 1; color: Theme.alpha(Theme.outline, 0.4) }
        StyledText { text: "Arch news"; color: Theme.on_surface_variant; font.pixelSize: Theme.fontSmall; font.weight: Font.Medium }

        Repeater {
            model: root.news.slice(0, root.shownNews)
            Item {
                id: post
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: Theme.px(30)

                StateLayer { radius: Theme.radiusSmall; onClicked: root.open(post.modelData.link) }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.px(6)
                    anchors.rightMargin: Theme.px(6)
                    spacing: Theme.gap
                    StyledText { Layout.fillWidth: true; text: post.modelData.title; font.pixelSize: Theme.fontSmall + 1 }
                    StyledText {
                        visible: !isNaN(post.modelData.date.getTime())
                        text: Qt.formatDate(post.modelData.date, "d MMM")
                        color: Theme.on_surface_variant
                        font.pixelSize: Theme.fontSmall
                    }
                }
            }
        }
    }
}
