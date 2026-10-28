import QtQuick
import com.hecate.settings

Row {
    id: root
    property var value
    signal committed(string value)

    readonly property string text: typeof value === "string" ? value : JSON.stringify(value ?? "")

    function parse(s) {
        let m = /^rgba\(([0-9a-f]{6})([0-9a-f]{2})\)/i.exec(s)
        if (m) return Qt.color("#" + m[2] + m[1])
        m = /^rgb\(([0-9a-f]{6})\)/i.exec(s)
        if (m) return Qt.color("#" + m[1])
        m = /^0x([0-9a-f]{8})/i.exec(s)
        if (m) return Qt.color("#" + m[1])
        return undefined
    }

    spacing: Theme.gap

    Repeater {
        model: ["primary", "secondary", "tertiary", "error"]

        Rectangle {
            required property string modelData
            width: 24
            height: 24
            anchors.verticalCenter: parent.verticalCenter
            radius: 12
            color: Theme[modelData]
            border.color: Theme.outline_variant
            visible: typeof root.value === "string"

            StateLayer { onClicked: root.committed("rgb(" + Theme[modelData].toString().slice(1, 7) + ")") }
        }
    }

    Rectangle {
        width: 28
        height: 28
        anchors.verticalCenter: parent.verticalCenter
        radius: 14
        color: root.parse(root.text) ?? "transparent"
        border.color: Theme.outline
    }

    Field {
        width: 200
        text: root.text
        readOnly: typeof root.value !== "string"
        invalid: !readOnly && !root.parse(text)
        onEditingFinished: if (!invalid) root.committed(text)
    }
}
