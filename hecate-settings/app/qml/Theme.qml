pragma Singleton
import QtQuick
import com.hecate.settings

QtObject {
    id: root

    property color primary: "#b2c5ff"; property color on_primary: "#182e60"; property color primary_container: "#314578"; property color on_primary_container: "#dae2ff"
    property color secondary: "#c0c6dd"; property color on_secondary: "#2a3042"; property color secondary_container: "#404659"; property color on_secondary_container: "#dce2f9"
    property color tertiary: "#e1bbdc"; property color on_tertiary: "#422741"; property color tertiary_container: "#5a3d59"; property color on_tertiary_container: "#fed7f9"
    property color error: "#ffb4ab"; property color on_error: "#690005"; property color error_container: "#93000a"; property color on_error_container: "#ffdad6"
    property color background: "#121318"; property color on_background: "#e3e2e9"
    property color surface: "#121318"; property color on_surface: "#e3e2e9"; property color surface_variant: "#45464f"; property color on_surface_variant: "#c5c6d0"
    property color surface_container_low: "#1a1b21"; property color surface_container: "#1e1f25"
    property color surface_container_high: "#292a2f"; property color surface_container_highest: "#33343a"
    property color outline: "#8f909a"; property color outline_variant: "#45464f"
    property color scrim: "#000000"

    property string font: "Inter"
    readonly property string iconFont: "Symbols Nerd Font"
    readonly property int fontSize: 14
    readonly property int pad: 16
    readonly property int gap: 8
    readonly property int radius: 24
    readonly property int radiusSmall: 16
    readonly property int anim: 320
    readonly property int animFast: 160
    readonly property list<real> curve: [0.05, 0.7, 0.1, 1, 1, 1]

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

    property QtObject backend: Backend {}

    Component.onCompleted: {
        const d = JSON.parse(backend.theme())
        if (d.font) font = d.font
        for (const k in d.colors) if (root[k] !== undefined) root[k] = d.colors[k]
    }
}
