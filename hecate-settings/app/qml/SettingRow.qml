import QtQuick
import QtQuick.Layouts
import com.hecate.settings

Rectangle {
    id: row
    required property var modelData
    property bool mismatch
    property var cur: modelData.value ?? modelData.default
    readonly property bool limited: modelData.min !== undefined
    readonly property bool isInt: modelData.type === "int"
    signal edited(var value)

    function commit(v) {
        cur = v
        edited(v)
    }

    implicitHeight: layout.implicitHeight + Theme.pad * 2
    radius: Theme.radiusSmall
    color: Theme.surface_container

    RowLayout {
        id: layout
        anchors.fill: parent
        anchors.margins: Theme.pad
        spacing: Theme.pad

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: row.modelData.name
                font.weight: Font.Medium
                Layout.fillWidth: true
            }
            StyledText {
                text: row.modelData.description.replace(/\[([^\]]+)\]\([^)]*\)/g, "$1").replace(/`/g, "")
                color: Theme.on_surface_variant
                font.pixelSize: Theme.fontSize - 2
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                Layout.fillWidth: true
            }
            StyledText {
                visible: row.modelData.is_dynamic || row.mismatch
                text: row.modelData.is_dynamic ? "Set by a script, edit it in your config" : "Your config sets a value of the wrong type"
                color: row.modelData.is_dynamic ? Theme.tertiary : Theme.error
                font.pixelSize: Theme.fontSize - 2
            }
        }

        Loader {
            enabled: !row.modelData.is_dynamic
            opacity: enabled ? 1 : 0.4
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: {
                const t = row.modelData.type
                if (t === "bool") return toggle
                if (t === "color") return color
                if ((t === "int" || t === "float") && row.limited) return slider
                if (t === "int" || t === "float") return number
                return text
            }
        }
    }

    Component {
        id: toggle
        Toggle { checked: row.cur === true; onToggled: row.commit(!checked) }
    }

    Component {
        id: slider
        RowLayout {
            spacing: Theme.gap
            StyledText {
                text: Number(row.cur).toFixed(row.isInt ? 0 : 2)
                color: Theme.on_surface_variant
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 44
            }
            Slider {
                from: row.modelData.min
                to: row.modelData.max
                stepSize: row.isInt ? 1 : (to - from) / 200
                value: Number(row.cur)
                onReleased: v => row.commit(v)
            }
        }
    }

    Component {
        id: number
        Field {
            implicitWidth: 120
            text: String(row.cur ?? 0)
            validator: DoubleValidator {}
            onEditingFinished: row.commit(row.isInt ? Math.round(Number(text)) : Number(text))
        }
    }

    Component {
        id: color
        ColorField { value: row.cur; onCommitted: v => row.commit(v) }
    }

    Component {
        id: text
        Field {
            implicitWidth: 240
            text: typeof row.cur === "string" ? row.cur : JSON.stringify(row.cur ?? "")
            onEditingFinished: {
                if (row.modelData.type === "string") return row.commit(text)
                try { row.commit(JSON.parse(text)) } catch (e) { row.commit(text) }
            }
        }
    }
}
