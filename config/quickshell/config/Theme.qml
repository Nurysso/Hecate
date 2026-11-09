pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Design tokens. Colors are the M3 palette matugen writes to ~/.cache/hecate/theme.json; sizes, glass and
// motion come from [theme] in hecate.toml. The bar's margin follows Hyprland's gaps_out unless [bar] margin is set.
Singleton {
    id: root

    // M3 tokens, named exactly as matugen emits them; overwritten from theme.json
    property color primary: "#b2c5ff"; property color on_primary: "#182e60"; property color primary_container: "#314578"; property color on_primary_container: "#dae2ff"
    property color secondary: "#c0c6dd"; property color on_secondary: "#2a3042"; property color secondary_container: "#404659"; property color on_secondary_container: "#dce2f9"
    property color tertiary: "#e1bbdc"; property color on_tertiary: "#422741"; property color tertiary_container: "#5a3d59"; property color on_tertiary_container: "#fed7f9"
    property color error: "#ffb4ab"; property color on_error: "#690005"; property color error_container: "#93000a"; property color on_error_container: "#ffdad6"
    property color background: "#121318"; property color on_background: "#e3e2e9"
    property color surface: "#121318"; property color on_surface: "#e3e2e9"; property color surface_variant: "#45464f"; property color on_surface_variant: "#c5c6d0"
    property color surface_container_lowest: "#0d0e13"; property color surface_container_low: "#1a1b21"; property color surface_container: "#1e1f25"
    property color surface_container_high: "#292a2f"; property color surface_container_highest: "#33343a"
    property color outline: "#8f909a"; property color outline_variant: "#45464f"
    property color inverse_surface: "#e3e2e9"; property color inverse_on_surface: "#2f3036"; property color inverse_primary: "#495d92"
    property color shadow: "#000000"; property color scrim: "#000000"
    property string wallpaper: ""

    // Size: [theme] scale multiplies every length below
    readonly property real scale: Config.theme.scale
    function px(n) { return Math.round(n * scale) }

    readonly property string font: Config.theme.font
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontTiny: px(11)
    readonly property int fontSmall: px(12)
    readonly property int fontSize: px(14)
    readonly property int fontLarge: px(16)
    readonly property int fontTitle: px(20)
    readonly property int fontDisplay: px(32)
    readonly property int iconSize: px(18)

    readonly property int gap: px(8)
    readonly property int pad: px(16)
    readonly property int radius: Math.round(Config.theme.rounding * scale)    // bar, chips' parents
    readonly property int radiusLarge: Math.round(radius * 1.25)               // panels and cards
    readonly property int radiusSmall: Math.round(radius * 0.75)               // tiles, rows, fields
    readonly property int radiusTiny: Math.round(radius * 0.5)

    // Bar geometry, shared by the bar and the panels that hang off it
    readonly property bool barBottom: Config.bar.position === "bottom"
    readonly property int barHeight: px(Config.bar.height)
    readonly property int barMargin: Config.bar.style === "full" ? 0 : Config.bar.margin >= 0 ? px(Config.bar.margin) : gapsOut[barBottom ? 2 : 0]
    readonly property int barInset: Config.bar.style === "full" ? px(6) : px(4)   // bar edge to its buttons
    readonly property int barExtent: barHeight + barMargin                         // the strip the bar reserves
    property list<int> gapsOut: [8, 8, 8, 8]                                       // Hyprland general:gaps_out (top right bottom left)

    // Glass: theme surface at [theme] opacity over Hyprland's blur, with a hairline edge
    readonly property bool blur: Config.theme.blur
    readonly property real opacity: Config.theme.opacity
    readonly property color glass: alpha(surface_container, opacity)
    readonly property color hairline: Config.theme.border ? alpha(on_surface, 0.1) : "transparent"
    readonly property color layer: alpha(on_surface, 0.06)        // fills drawn on glass: rows, tracks, fields
    readonly property color layerHigh: alpha(on_surface, 0.11)

    // Motion: M3 emphasized curves; [theme] animation_speed divides durations, animations = false zeroes them
    readonly property real speed: Config.theme.animations ? Config.theme.speed : 0
    function ms(n) { return speed > 0 ? Math.round(n / speed) : 0 }
    // Started by the login reveal: the bar and cards are ready when it opens, so they don't fade in behind it
    readonly property bool behindReveal: Quickshell.env("HECATE_REVEAL") === "1"
    readonly property int anim: ms(380)
    readonly property int animFast: ms(200)
    readonly property int animSlow: ms(700)
    readonly property list<real> curve: [0.05, 0.7, 0.1, 1, 1, 1]          // emphasized decelerate: things arriving
    readonly property list<real> curveExit: [0.3, 0, 0.8, 0.15, 1, 1]      // emphasized accelerate: things leaving
    readonly property list<real> curveStandard: [0.2, 0, 0, 1, 1, 1]       // moving between two places

    readonly property var icon: ({
        arch: "\u{f303}", owl: "\u{f03d2}", search: "\u{f0349}", apps: "\u{f003b}", calculator: "\u{f00ec}",
        wifi: ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"], wifiNone: "\u{f092f}", wifiOff: "\u{f05aa}", ethernet: "\u{f0200}",
        bt: "\u{f00af}", btOff: "\u{f00b2}", btOn: "\u{f00b1}",
        headphones: "\u{f02cb}", keyboard: "\u{f030c}", mouse: "\u{f037d}", phone: "\u{f011c}", speaker: "\u{f04c3}", gamepad: "\u{f0297}", monitor: "\u{f0379}",
        bell: "\u{f009c}", bellBadge: "\u{f0178}", bellOff: "\u{f0a91}", bellSleep: "\u{f0a93}",
        power: "\u{f0425}", reboot: "\u{f0709}", lock: "\u{f0341}", logout: "\u{f0343}", suspend: "\u{f0904}",
        clipboard: "\u{f014c}", emoji: "\u{f01f5}", text: "\u{f09ed}", image: "\u{f0976}", wallpaper: "\u{f0e09}", folder: "\u{f024f}", palette: "\u{f0e0c}",
        check: "\u{f012c}", close: "\u{f0156}", delete: "\u{f09e7}", clearAll: "\u{f0c62}", loading: "\u{f0772}", copy: "\u{f018f}",
        chevronLeft: "\u{f0141}", chevronRight: "\u{f0142}", chevronUp: "\u{f0143}", chevronDown: "\u{f0140}", back: "\u{f004d}",
        settings: "\u{f08bb}", account: "\u{f0009}", calendar: "\u{f00ed}", star: "\u{f0ae2}", info: "\u{f02fd}",
        music: "\u{f075a}", play: "\u{f040a}", pause: "\u{f03e4}", next: "\u{f04ad}", prev: "\u{f04ae}", shuffle: "\u{f049d}", repeat: "\u{f0456}",
        cpu: "\u{f061a}", memory: "\u{f035b}", gpu: "\u{f08ae}", disk: "\u{f02ca}", fan: "\u{f0210}", bolt: "\u{f0241}", timer: "\u{f13ab}",
        github: "\u{f02a4}", pin: "\u{f034e}", humidity: "\u{f058e}", wind: "\u{f059d}", umbrella: "\u{f054a}", thermometer: "\u{f050f}",
        sunrise: "\u{f059c}", sunset: "\u{f059b}",
        plus: "\u{f0415}", download: "\u{f01da}", upload: "\u{f0552}", update: "\u{f06b0}", refresh: "\u{f0450}",
        volume: ["\u{f057f}", "\u{f0580}", "\u{f057e}"], volumeOff: "\u{f0581}", mic: "\u{f036c}", micOff: "\u{f036d}",
        battery: ["\u{f007a}", "\u{f007c}", "\u{f007e}", "\u{f0080}", "\u{f0082}", "\u{f0079}"], batteryCharging: "\u{f0084}",
        coffee: "\u{f0176}", coffeeOff: "\u{f06ca}", moon: "\u{f0f65}",
        performance: "\u{f04c5}", balanced: "\u{f05d1}", powerSaver: "\u{f032a}",
        sunny: "\u{f0599}", night: "\u{f0594}", partly: "\u{f0595}", partlyNight: "\u{f0f31}", cloudy: "\u{f0590}", fog: "\u{f0591}",
        rainy: "\u{f0597}", pouring: "\u{f0596}", sleet: "\u{f067f}", snowy: "\u{f0598}", storm: "\u{f067e}", hail: "\u{f0592}"
    })

    // An icon setting from hecate.toml: a name from the table above, or any glyph
    function glyph(v, fallback) { return typeof v === "string" && v ? (typeof icon[v] === "string" ? icon[v] : v) : icon[fallback] }

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    // Text and icon color for a fill of color c, which may be any accent hecate.toml sets
    function contrast(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b > 0.5 ? surface_container_lowest : on_surface }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t) }

    FileView {
        path: Config.home + "/.cache/hecate/theme.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const d = JSON.parse(text())
            for (const k in d) if (root[k] !== undefined) root[k] = d[k]
        }
    }

    // CSS-style "t r b l" shorthand, as hyprctl reports it
    function refreshGaps() { gaps.running = true }
    Process {
        id: gaps
        running: true
        command: ["hyprctl", "-j", "getoption", "general:gaps_out"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const o = JSON.parse(text)
                    const v = String(o.css ?? o.custom ?? o.int ?? "").trim().split(/\s+/).map(Number).filter(n => !isNaN(n))
                    if (!v.length) return
                    const [t, r = t, b = t, l = r] = v
                    root.gapsOut = [t, r, b, l]
                } catch (e) {}
            }
        }
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") root.refreshGaps() }
    }
}
