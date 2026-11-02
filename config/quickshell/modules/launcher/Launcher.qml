import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.services

// App launcher. Searches names, descriptions and keywords; the apps you start most often (and lately)
// come first. A query of numbers and + - * / % ^ ( ) is worked out instead, and Enter copies the answer.
Panel {
    id: root
    name: "launcher"
    kind: "modal"
    contentWidth: Theme.px(600)
    contentHeight: Theme.px(540)

    ColumnLayout {
        id: content
        spacing: Theme.px(12)

        readonly property string query: search.text.trim().toLowerCase()
        readonly property var results: {
            const q = query
            return DesktopEntries.applications.values.filter(a => !a.noDisplay)
                .map(a => ({ a: a, s: score(a, q) }))
                .filter(x => x.s >= 0)
                .sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name))
                .map(x => x.a)
        }
        readonly property string answer: {
            const q = search.text.trim()
            if (!/^[\d\s.+\-*/%^()]+$/.test(q) || !/\d/.test(q) || !/[+\-*/%^]/.test(q)) return ""
            try {
                const v = Function(`"use strict"; return (${q.replace(/\^/g, "**")})`)()
                return typeof v === "number" && isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : ""
            } catch (e) { return "" }
        }

        // Exact name, then name start, word start, anywhere in the name, the description or keywords,
        // then the letters in order; how often an app is used breaks ties within each tier
        function score(a, q) {
            const used = Launches.score(a.id)
            if (!q) return used
            const name = a.name.toLowerCase()
            const tier = name === q ? 6 : name.startsWith(q) ? 5 : name.split(/[\s\-_.]+/).some(w => w.startsWith(q)) ? 4
                : name.includes(q) ? 3 : `${a.genericName} ${a.comment} ${a.keywords.join(" ")}`.toLowerCase().includes(q) ? 2
                : subsequence(name, q) ? 1 : 0
            return tier ? tier * 1000 + Math.min(used, 999) : -1
        }
        function subsequence(s, q) {
            let i = 0
            for (const c of s) if (c === q[i] && ++i === q.length) return true
            return false
        }
        // The name with the matching part in the accent color (StyledText, so it's escaped first)
        function mark(name) {
            const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            const i = query ? name.toLowerCase().indexOf(query) : -1
            if (i < 0) return esc(name)
            return esc(name.slice(0, i)) + `<font color="${root.accent}"><b>${esc(name.slice(i, i + query.length))}</b></font>` + esc(name.slice(i + query.length))
        }
        function run(entry) {
            Launches.launch(entry)
            GlobalStates.close()
        }

        SearchField {
            id: search
            Layout.fillWidth: true
            placeholderText: "Search apps, or type a sum"
            focus: true
            Keys.onDownPressed: list.incrementCurrentIndex()
            Keys.onUpPressed: list.decrementCurrentIndex()
            Keys.onTabPressed: list.incrementCurrentIndex()
            onAccepted: {
                if (content.answer) {
                    Quickshell.execDetached(["wl-copy", "--", content.answer])
                    GlobalStates.close()
                } else if (list.currentItem) content.run(list.currentItem.modelData)
            }
        }

        Tile {
            visible: content.answer !== ""
            Layout.fillWidth: true
            icon: Theme.icon.calculator
            fg: root.accent
            title: "= " + content.answer
            subtitle: "Enter copies the answer"
            selected: true
            onClicked: search.accepted()
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.px(2)
            highlightMoveDuration: Theme.animFast
            highlightResizeDuration: 0
            highlight: Rectangle { radius: Theme.radiusSmall; color: Theme.layerHigh }
            model: ScriptModel {
                values: content.results
                onValuesChanged: list.currentIndex = 0
            }

            delegate: Tile {
                required property DesktopEntry modelData
                width: ListView.view.width
                image: Quickshell.iconPath(modelData.icon, true)
                icon: Theme.icon.apps
                iconSize: Theme.px(34)
                rich: true
                title: content.mark(modelData.name)
                subtitle: modelData.genericName || modelData.comment
                onClicked: content.run(modelData)
            }

            add: Transition { Anim { property: "opacity"; from: 0; to: 1 } }
            displaced: Displaced {}

            StyledText {
                anchors.centerIn: parent
                visible: !list.count && !content.answer
                text: "No apps match"
                color: Theme.on_surface_variant
            }
        }

        RowLayout {
            Layout.leftMargin: Theme.px(4)
            Layout.rightMargin: Theme.px(4)
            Hints { keys: [["↑↓", "select"], ["↵", content.answer ? "copy" : "open"], ["esc", "close"]] }
            Item { Layout.fillWidth: true }
            StyledText { text: list.count + (list.count === 1 ? " app" : " apps"); color: Theme.on_surface_variant; font.pixelSize: Theme.fontSmall }
        }
    }
}
