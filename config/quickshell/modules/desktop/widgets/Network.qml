import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.config
import qs.components
import qs.services

// Download and upload speed from /proc/net/dev, as a graph of the last minute. Loopback, containers,
// bridges and VPN tunnels are left out so traffic isn't counted twice.
// [desktop.network] seconds (history length)
Card {
    id: root
    widget: "network"

    readonly property int seconds: Math.max(10, Math.min(300, Number(cfg.seconds ?? 60) || 60))
    readonly property color upColor: Theme.tertiary

    property var down: []        // bytes per second, newest last
    property var up: []
    property real rxTotal
    property real txTotal
    property real prevRx: -1
    property real prevTx: -1
    property real prevAt

    readonly property real nowDown: down.length ? down[down.length - 1] : 0
    readonly property real nowUp: up.length ? up[up.length - 1] : 0
    readonly property real peak: Math.max(Math.max(...down, 0), Math.max(...up, 0))

    function rate(b) {
        const unit = ["B", "KB", "MB", "GB"]
        let i = 0
        while (b >= 1024 && i < 3) { b /= 1024; i++ }
        return (i ? b.toFixed(b < 10 ? 1 : 0) : Math.round(b)) + " " + unit[i] + "/s"
    }
    function size(b) {
        const unit = ["B", "KiB", "MiB", "GiB", "TiB"]
        let i = 0
        while (b >= 1024 && i < 4) { b /= 1024; i++ }
        return b.toFixed(i && b < 100 ? 1 : 0) + " " + unit[i]
    }

    function sample(src) {
        let rx = 0, tx = 0
        for (const line of src.split("\n").slice(2)) {
            const colon = line.indexOf(":")
            if (colon < 0) continue
            if (/^(lo|docker|veth|br-|virbr|tun|tap|wg|tailscale)/.test(line.slice(0, colon).trim())) continue
            const f = line.slice(colon + 1).trim().split(/\s+/)
            rx += Number(f[0]) || 0
            tx += Number(f[8]) || 0
        }
        const now = Date.now()
        if (prevRx >= 0 && now > prevAt) {
            const dt = (now - prevAt) / 1000
            // a counter that went backwards (interface reset) counts as no traffic
            const d = Math.max(0, rx - prevRx) / dt
            const u = Math.max(0, tx - prevTx) / dt
            down = [...down, d].slice(-seconds)
            up = [...up, u].slice(-seconds)
        }
        prevRx = rx; prevTx = tx; prevAt = now
        rxTotal = rx; txTotal = tx
    }

    FileView {
        id: dev
        path: "/proc/net/dev"
        printErrors: false
        onLoaded: root.sample(text())
    }
    Timer { running: true; repeat: true; triggeredOnStart: true; interval: 1000; onTriggered: dev.reload() }

    CardHeader {
        icon: Net.icon
        title: Net.label
        accent: root.accent
        StyledText {
            text: root.peak > 0 ? "peak " + root.rate(root.peak) : ""
            color: Theme.on_surface_variant
            font.pixelSize: Theme.fontSmall
        }
    }

    component Reading: RowLayout {
        id: reading
        property string icon
        property color tone
        property real speed
        property real total
        Layout.fillWidth: true
        spacing: Theme.px(8)
        Icon { text: reading.icon; color: reading.tone; font.pixelSize: Theme.px(22) }
        ColumnLayout {
            spacing: 0
            StyledText {
                text: root.rate(reading.speed)
                font.pixelSize: Theme.px(18)
                font.weight: Font.Bold
                font.features: { "tnum": 1 }
            }
            StyledText {
                text: root.size(reading.total) + " since boot"
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontTiny
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Reading { icon: Theme.icon.download; tone: root.accent; speed: root.nowDown; total: root.rxTotal }
        Reading { icon: Theme.icon.upload; tone: root.upColor; speed: root.nowUp; total: root.txTotal }
    }

    Canvas {
        id: graph
        Layout.fillWidth: true
        implicitHeight: Theme.px(84)

        function trace(ctx, values, scale, fill) {
            if (values.length < 2) return
            const step = width / (root.seconds - 1)
            const x = i => width - (values.length - 1 - i) * step
            const y = v => height - 2 - (height - 6) * Math.min(1, v / scale)
            ctx.beginPath()
            ctx.moveTo(x(0), y(values[0]))
            for (let i = 1; i < values.length; i++) ctx.lineTo(x(i), y(values[i]))
            ctx.stroke()
            if (fill) {
                ctx.lineTo(x(values.length - 1), height)
                ctx.lineTo(x(0), height)
                ctx.closePath()
                ctx.fill()
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.lineWidth = Math.max(1.5, Theme.px(2))
            ctx.lineJoin = "round"
            // a floor of 100 KB/s so idle noise doesn't fill the graph
            const scale = Math.max(root.peak, 100 * 1024)
            ctx.strokeStyle = root.upColor
            ctx.fillStyle = Theme.alpha(root.upColor, 0.12)
            trace(ctx, root.up, scale, true)
            ctx.strokeStyle = root.accent
            ctx.fillStyle = Theme.alpha(root.accent, 0.22)
            trace(ctx, root.down, scale, true)
        }

        Connections {
            target: root
            function onDownChanged() { graph.requestPaint() }
            function onAccentChanged() { graph.requestPaint() }
            function onUpColorChanged() { graph.requestPaint() }
        }
        onWidthChanged: requestPaint()
    }

    StyledText {
        text: `Last ${root.seconds} seconds`
        color: Theme.on_surface_variant
        font.pixelSize: Theme.fontSmall
        Layout.alignment: Qt.AlignHCenter
    }
}
