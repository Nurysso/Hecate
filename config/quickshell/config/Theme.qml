pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

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

    readonly property string font: Config.font
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontSize: 14
    readonly property int pad: 16
    readonly property int gap: 8
    readonly property int radius: 24
    readonly property int radiusSmall: 16
    readonly property int barHeight: 48
    readonly property int anim: 320
    readonly property int animFast: 160
    readonly property list<real> curve: [0.05, 0.7, 0.1, 1, 1, 1]

    readonly property var icon: ({
        arch: "\u{f303}", search: "\u{f0349}", apps: "\u{f003b}",
        wifi: ["\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"], wifiNone: "\u{f092f}", wifiOff: "\u{f05aa}", ethernet: "\u{f0200}",
        bt: "\u{f00af}", btOff: "\u{f00b2}", btOn: "\u{f00b1}",
        headphones: "\u{f02cb}", keyboard: "\u{f030c}", mouse: "\u{f037d}", phone: "\u{f011c}", speaker: "\u{f04c3}", gamepad: "\u{f0297}",
        bell: "\u{f009c}", bellBadge: "\u{f116b}", bellOff: "\u{f0a93}",
        power: "\u{f0425}", reboot: "\u{f0709}", lock: "\u{f033e}", logout: "\u{f0343}", suspend: "\u{f0904}",
        clipboard: "\u{f014c}", emoji: "\u{f01f4}", text: "\u{f09ed}", image: "\u{f02e9}", wallpaper: "\u{f0e09}", folder: "\u{f024f}",
        check: "\u{f05e0}", close: "\u{f0156}", delete: "\u{f09e7}", clearAll: "\u{f0c62}", loading: "\u{f0772}",
        music: "\u{f075a}", play: "\u{f040a}", pause: "\u{f03e4}", next: "\u{f04ad}", prev: "\u{f04ae}", shuffle: "\u{f049d}", repeat: "\u{f0456}",
        cpu: "\u{f061a}", memory: "\u{f035b}", gpu: "\u{f08ae}", disk: "\u{f02ca}", fan: "\u{f0210}", bolt: "\u{f0241}", timer: "\u{f13ab}",
        github: "\u{f02a4}", pin: "\u{f034e}", humidity: "\u{f058e}", wind: "\u{f059d}", umbrella: "\u{f054a}", thermometer: "\u{f050f}",
        sunrise: "\u{f059c}", sunset: "\u{f059b}",
        volume: ["\u{f057f}", "\u{f0580}", "\u{f057e}"], volumeOff: "\u{f0581}",
        battery: ["\u{f007a}", "\u{f007c}", "\u{f007e}", "\u{f0080}", "\u{f0082}", "\u{f0079}"], batteryCharging: "\u{f0084}",
        coffee: "\u{f0176}", coffeeOff: "\u{f06ca}",
        sunny: "\u{f0599}", night: "\u{f0594}", partly: "\u{f0595}", partlyNight: "\u{f0f31}", cloudy: "\u{f0590}", fog: "\u{f0591}",
        rainy: "\u{f0597}", pouring: "\u{f0596}", sleet: "\u{f067f}", snowy: "\u{f0598}", storm: "\u{f067e}", hail: "\u{f0592}"
    })

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

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
}
