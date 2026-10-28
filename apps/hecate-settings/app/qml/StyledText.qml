import QtQuick
import com.hecate.settings

Text {
    color: Theme.on_surface
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    Behavior on color { CAnim {} }
}
