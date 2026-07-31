pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
  id: osd

  required property var shell
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    visible: osd.shell.osdVisible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: 68
      implicitWidth: osdRow.implicitWidth + 36
      implicitHeight: 68
      radius: osd.shell.cornerRadius
      color: osd.shell.elevated
      border.color: osd.shell.outline
      opacity: osd.shell.osdVisible ? 1 : 0

      RowLayout {
        id: osdRow
        anchors.centerIn: parent
        spacing: 16
        Text {
          text: osd.shell.osdIcon
          color: osd.shell.foreground
          font.pixelSize: 26
        }
        Rectangle {
          visible: osd.shell.osdHasProgress
          Layout.preferredWidth: 150
          Layout.preferredHeight: 7
          radius: 4
          color: osd.shell.selectedFill
          Rectangle {
            width: parent.width * osd.shell.osdValue / 100
            height: parent.height
            radius: parent.radius
            color: osd.shell.accent
            Behavior on width {
              NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
          }
        }
        Text {
          Layout.maximumWidth: 330
          text: osd.shell.osdLabel
          color: osd.shell.foreground
          font.bold: true
          elide: Text.ElideRight
        }
      }
    }
  }
}
