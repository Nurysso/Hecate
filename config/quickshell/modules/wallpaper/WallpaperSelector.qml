import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.config
import qs.components

// A carousel of the wallpapers in [wallpaper] dir: the one in the middle is the one you'll get. Arrows,
// the wheel or a click move along it, Enter applies. Type to search by name, Tab (or the chips) to
// filter by colour, Ctrl+S to sort by name or newest, Ctrl+R for a random one. Highlights take the
// colour of the wallpaper in the middle. Applying runs set-wallpaper.sh, which also recolors the shell
// in dynamic mode; the picker closes once it's applied.
// The carousel never decodes the originals: wallpaper-index.py keeps a database of small cached
// thumbnails and each image's main colours, and only works on files added or edited since the last
// time, so folders of many GB of 4K/8K images open instantly. Colours need Pillow; without it that
// part (chips, the palette and the changing highlight) is off.
Panel {
    id: root
    name: "wallpaper"
    kind: "modal"
    contentWidth: Theme.px(1200)
    contentHeight: Theme.px(510)

    ColumnLayout {
        id: view
        spacing: Theme.px(12)

        property var all: []             // [{ path, name, thumb, colors, tones, mtime }] in name order
        property int pillow: -1          // -1 until the script says, then 0 or 1
        property string tone: ""         // the colour family chosen, "" for all
        property bool newest             // sort by when it was added or changed, not by name
        property bool placed             // false until you move, so the picker opens on the wallpaper in use
        property bool animate            // off while it opens, so it appears on the wallpaper in use instead of gliding there
        onPlacedChanged: if (placed) animate = true
        readonly property var families: [
            { id: "red", label: "Red", color: "#e5484d" }, { id: "orange", label: "Orange", color: "#f76b15" },
            { id: "yellow", label: "Yellow", color: "#f5d90a" }, { id: "green", label: "Green", color: "#30a46c" },
            { id: "cyan", label: "Cyan", color: "#12a594" }, { id: "blue", label: "Blue", color: "#3e63dd" },
            { id: "purple", label: "Purple", color: "#8e4ec6" }, { id: "pink", label: "Pink", color: "#d6409f" },
            { id: "white", label: "White", color: "#ededed" }, { id: "grey", label: "Grey", color: "#8b8d98" },
            { id: "black", label: "Black", color: "#1c1c1f" }
        ]
        // the families that have at least one wallpaper, in the order above
        readonly property var present: families.filter(f => all.some(w => w.tones.includes(f.id)))

        readonly property var shown: {
            const q = search.text.trim().toLowerCase()
            const out = all.filter(w => (!q || w.name.toLowerCase().includes(q)) && (!tone || w.tones.includes(tone)))
            return newest ? out.sort((a, b) => b.mtime - a.mtime) : out
        }
        readonly property var current: shown[list.currentIndex] ?? null
        readonly property bool applied: !!current && current.path === Theme.wallpaper
        // the most vivid of the middle wallpaper's colours, lifted so it reads on glass
        property color tint: {
            let best = null, score = 0
            for (const hex of current?.colors ?? []) {
                const c = Qt.color(hex)
                if (c.hsvValue < 0.2) continue
                const s = c.hsvSaturation * (0.5 + c.hsvValue)
                if (s > score) { score = s; best = c }
            }
            return best && best.hsvSaturation > 0.12 ? Qt.hsva(best.hsvHue, Math.max(best.hsvSaturation, 0.45), Math.max(best.hsvValue, 0.8), 1) : root.accent
        }
        Behavior on tint { CAnim {} }

        function family(hex) {
            const c = Qt.color(hex)
            const h = c.hsvHue * 360
            // black is near-black, or dark and nearly colourless; a dark green or navy keeps its colour
            if (c.hsvValue < 0.1 || (c.hsvValue < 0.25 && c.hsvSaturation < 0.25)) return "black"
            if (c.hsvSaturation < 0.15) return c.hsvValue > 0.8 ? "white" : "grey"
            return h < 15 || h >= 345 ? "red" : h < 45 ? "orange" : h < 70 ? "yellow" : h < 165 ? "green"
                 : h < 200 ? "cyan" : h < 255 ? "blue" : h < 290 ? "purple" : "pink"
        }
        // Tab steps through "all" and the families present
        function step(by) {
            const ids = ["", ...present.map(f => f.id)]
            tone = ids[(ids.indexOf(tone) + by + ids.length) % ids.length]
        }
        // back to the first one, without sliding there, once the filtered list has replaced the old one
        function restart() {
            placed = true
            animate = false
            Qt.callLater(() => { list.currentIndex = 0; list.positionViewAtIndex(0, ListView.Center); settle.restart() })
        }
        onToneChanged: restart()
        onNewestChanged: restart()

        function pick(path) { apply.exec([Config.home + "/.config/hecate/scripts/set-wallpaper.sh", path]) }
        function random() { if (shown.length) pick(shown[Math.floor(Math.random() * shown.length)].path) }

        Process {
            id: lister
            running: true
            command: ["python3", Config.home + "/.config/hecate/scripts/wallpaper-index.py", Config.wallpaperDir]
            stdout: SplitParser {
                splitMarker: "\n"
                onRead: line => {
                    const f = line.split("\t")
                    if (f[0] === "P") {
                        view.pillow = Number(f[1])
                    } else if (f[0] === "F") {
                        const colors = f[4] ? f[4].split(",") : []
                        // it shows under its main colour's family and the second colour's, except that black,
                        // white and grey only count as the main colour (a shadow isn't what the image is about)
                        const fams = colors.slice(0, 2).map(view.family)
                        const tones = [...new Set(fams.filter((t, i) => i === 0 || !["black", "white", "grey"].includes(t)))]
                        batch.files.push({ path: f[1], name: f[2], thumb: f[3], colors: colors, mtime: Number(f[5]) || 0,
                                           tones: tones })
                        batch.dirty = true
                    }
                    if (!batch.running) batch.start()
                }
            }
        }

        // Applies what the script printed a few times a second instead of once per line
        Timer {
            id: batch
            property var files: []
            property bool dirty
            interval: 120
            onTriggered: {
                if (!dirty) return
                dirty = false
                if (!view.animate && !settle.running) settle.start()
                // files finished later arrive after the rest, so keep them in name order
                view.all = files.slice().sort((a, b) => a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1)
                if (!view.placed) {
                    const i = view.shown.findIndex(w => w.path === Theme.wallpaper)
                    if (i >= 0) list.currentIndex = i
                }
            }
        }

        Timer { id: settle; interval: 400; onTriggered: view.animate = true }

        Process {
            id: apply
            stderr: StdioCollector { onStreamFinished: status.text = text.trim() }
            onStarted: status.text = "Applying…"
            onExited: code => {
                if (code !== 0) return
                status.text = ""
                GlobalStates.close()
            }
        }

        // search, sort, random
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.gap

            SearchField {
                id: search
                Layout.fillWidth: true
                placeholderText: "Search wallpapers"
                focus: true
                // sideways moves along the carousel once the text cursor has nowhere left to go
                Keys.onLeftPressed: e => { if (cursorPosition === 0) { view.placed = true; list.decrementCurrentIndex() } else e.accepted = false }
                Keys.onRightPressed: e => { if (cursorPosition === length) { view.placed = true; list.incrementCurrentIndex() } else e.accepted = false }
                Keys.onTabPressed: view.step(1)
                Keys.onBacktabPressed: view.step(-1)
                Keys.onPressed: e => {
                    if (!(e.modifiers & Qt.ControlModifier)) return
                    if (e.key === Qt.Key_R) { view.random(); e.accepted = true }
                    else if (e.key === Qt.Key_S) { view.newest = !view.newest; e.accepted = true }
                }
                onAccepted: if (view.current) view.pick(view.current.path)
                onTextChanged: view.restart()
            }
            TextButton {
                icon: view.newest ? Theme.icon.calendar : Theme.icon.text
                text: view.newest ? "Newest" : "Name"
                implicitHeight: Theme.px(40)
                onClicked: view.newest = !view.newest
            }
            IconButton {
                size: Theme.px(40)
                icon: Theme.icon.shuffle
                filled: true
                accent: view.tint
                enabled: view.shown.length > 0
                onClicked: view.random()
            }
        }

        // colour families
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.px(4)
            spacing: Theme.px(6)
            visible: view.pillow === 1 && view.present.length > 0

            Repeater {
                model: [{ id: "", label: "All", color: "" }, ...view.present]

                Rectangle {
                    id: chip
                    required property var modelData
                    readonly property bool on: view.tone === modelData.id
                    implicitWidth: chipRow.implicitWidth + Theme.px(20)
                    implicitHeight: Theme.px(28)
                    radius: height / 2
                    color: on ? Theme.alpha(view.tint, 0.28) : Theme.layerHigh
                    border.width: on ? Math.max(1, Theme.px(1)) : 0
                    border.color: view.tint
                    Behavior on color { CAnim {} }

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: Theme.px(6)
                        Rectangle {
                            visible: !!chip.modelData.color
                            anchors.verticalCenter: parent.verticalCenter
                            width: Theme.px(12)
                            height: width
                            radius: width / 2
                            color: chip.modelData.color
                            border.width: 1
                            border.color: Theme.alpha(Theme.on_surface, 0.25)
                        }
                        StyledText { anchors.verticalCenter: parent.verticalCenter; text: chip.modelData.label; font.pixelSize: Theme.fontSmall }
                    }

                    StateLayer { onClicked: view.tone = chip.modelData.id }
                }
            }
        }
        StyledText {
            visible: view.pillow === 0
            Layout.leftMargin: Theme.px(4)
            text: "Colour groups are off. Install Pillow (python-pillow) to turn them on."
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }

        // the carousel: the current wallpaper sits in the middle at full size, its neighbours shrink and fade away
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: -Theme.px(150)
            clip: true
            model: view.shown   // a plain array: every filter or sort rebuilds the carousel instead of shuffling old tiles
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: width / 2 - Theme.px(200)
            preferredHighlightEnd: width / 2 + Theme.px(200)
            highlightMoveDuration: view.animate ? Theme.anim : 0
            snapMode: ListView.SnapToItem
            cacheBuffer: Theme.px(1600)

            WheelHandler {
                onWheel: e => {
                    view.placed = true
                    if (e.angleDelta.y + e.angleDelta.x > 0) list.decrementCurrentIndex()
                    else list.incrementCurrentIndex()
                }
            }

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool focused: ListView.isCurrentItem
                readonly property bool inUse: modelData.path === Theme.wallpaper
                // how many places from the middle: 0 in the middle, negative to the left
                readonly property real away: Math.max(-3, Math.min(3, (x + width / 2 - list.contentX - list.width / 2) / (width + list.spacing)))
                readonly property real far: Math.abs(away)
                width: Theme.px(400)
                height: list.height
                z: -far
                scale: 1 - 0.25 * Math.min(far, 2)
                opacity: far <= 1 ? 1 - 0.3 * far : Math.max(0, 0.7 - 0.3 * (far - 1))

                ClippingRectangle {
                    anchors.centerIn: parent
                    width: Theme.px(400)
                    height: Theme.px(250)
                    radius: Theme.radiusLarge
                    color: Theme.layerHigh
                    border.width: cell.focused ? Theme.px(3) : 0
                    border.color: view.tint
                    Behavior on border.color { CAnim {} }

                    Image {
                        anchors.fill: parent
                        source: "file://" + cell.modelData.thumb
                        sourceSize.width: Theme.px(480)
                        cache: false
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { Anim {} }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.px(12)
                        width: Theme.px(28)
                        height: width
                        radius: width / 2
                        color: view.tint
                        visible: cell.inUse
                        Icon { anchors.centerIn: parent; text: Theme.icon.check; color: Theme.contrast(view.tint); font.pixelSize: Theme.px(16) }
                    }

                    StateLayer {
                        tint: Theme.on_surface
                        onClicked: { view.placed = true; if (cell.focused) view.pick(cell.modelData.path); else list.currentIndex = cell.index }
                    }
                }
            }

            StyledText {
                anchors.centerIn: parent
                visible: !list.count
                text: lister.running && !view.all.length ? "Reading " + Config.wallpaperDir.replace(Config.home, "~") + "…"
                    : view.all.length ? "Nothing matches" : "No images in " + Config.wallpaperDir.replace(Config.home, "~")
                color: Theme.on_surface_variant
            }
        }

        // the one in the middle: name, palette, apply
        Item {
            Layout.fillWidth: true
            implicitHeight: info.implicitHeight
            opacity: view.current ? 1 : 0

        ColumnLayout {
            id: info
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.px(10)

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.px(8)
                StyledText {
                    Layout.maximumWidth: Theme.px(800)
                    text: view.current?.name ?? " "
                    font.pixelSize: Theme.fontTitle
                    font.weight: Font.DemiBold
                }
                Icon { visible: view.applied; text: Theme.icon.check; color: view.tint }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Theme.px(18)

                Row {
                    spacing: Theme.px(6)
                    Repeater {
                        model: view.current?.colors ?? []
                        Rectangle {
                            required property string modelData
                            width: Theme.px(20)
                            height: width
                            radius: width / 2
                            color: modelData
                            border.width: 1
                            border.color: Theme.alpha(Theme.on_surface, 0.25)
                        }
                    }
                }

                Rectangle {
                    implicitWidth: applyRow.implicitWidth + Theme.px(36)
                    implicitHeight: Theme.px(40)
                    radius: height / 2
                    color: view.tint
                    Row {
                        id: applyRow
                        anchors.centerIn: parent
                        spacing: Theme.px(8)
                        Icon { anchors.verticalCenter: parent.verticalCenter; text: Theme.icon.wallpaper; color: Theme.contrast(view.tint) }
                        StyledText { anchors.verticalCenter: parent.verticalCenter; text: "Apply"; color: Theme.contrast(view.tint); font.weight: Font.DemiBold }
                    }
                    StateLayer { tint: Theme.contrast(view.tint); onClicked: if (view.current) view.pick(view.current.path) }
                }

                StyledText {
                    text: `${list.currentIndex + 1} / ${list.count}`
                    color: Theme.on_surface_variant
                    font.pixelSize: Theme.fontSmall
                    font.features: { "tnum": 1 }
                }
            }
        }
        }

        RowLayout {
            Layout.leftMargin: Theme.px(4)
            Layout.rightMargin: Theme.px(4)
            Hints {
                keys: [["←→", "browse"], ["↵", "apply"], ...(view.pillow === 1 ? [["tab", "colour"]] : []), ["^S", "sort"], ["^R", "random"], ["esc", "close"]]
            }
            Item { Layout.fillWidth: true }
            StyledText { id: status; color: apply.running ? view.tint : Theme.error; font.pixelSize: Theme.fontSmall }
            StyledText { text: Config.wallpaperDir.replace(Config.home, "~"); color: Theme.on_surface_variant; font.pixelSize: Theme.fontSmall }
        }
    }
}
