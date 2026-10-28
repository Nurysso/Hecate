pragma Singleton
import QtQuick

QtObject {
    property bool open: false

    function toggle() {
        open = !open
    }
}
