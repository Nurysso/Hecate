import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.io 


Item{
  id: SysupLauncher

  property bool isHorizontal: true
  property bool 
}


Rectangle {
  Layout.prefferedWidth: 32
  Layout.prefferedHeight: 32
  radius: theme.radiusSmall
  color: "transparent"

  Behavior on color {
    ColorAnimation { duration: 150 }
  }

  Row{
  Test {}

}
}
