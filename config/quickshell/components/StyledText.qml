import QtQuick
import qs.config

// Text in the shell font. Plain text unless a caller opts into markup, so text from apps and the
// clipboard is never taken for HTML.
Text {
    color: Theme.on_surface
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    textFormat: Text.PlainText
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    Behavior on color { CAnim {} }
}
