pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

Variants {
  id: powerMenu

  required property var shell
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: powerMenu.shell.powerVisible
    visible: powerMenu.shell.powerVisible
    color: "#99000000"

    MouseArea {
      anchors.fill: parent
      onClicked: powerMenu.shell.closeSurface("power")
    }

    Rectangle {
      anchors.centerIn: parent
      width: 430
      height: 170
      radius: powerMenu.shell.cornerRadius
      color: powerMenu.shell.surface
      border.color: powerMenu.shell.outline
      MouseArea { anchors.fill: parent }

      RowLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10

        Repeater {
          model: [
            { label: "Lock", icon: "", command: ["loginctl", "lock-session"] },
            { label: "Suspend", icon: "󰤄", command: ["systemctl", "suspend"] },
            { label: "Logout", icon: "󰍃", command: ["uwsm", "stop"] },
            { label: "Reboot", icon: "󰜉", command: ["systemctl", "reboot"] },
            { label: "Power off", icon: "", command: ["systemctl", "poweroff"] }
          ]

          Rectangle {
            required property var modelData
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: powerMenu.shell.cornerRadius - 2
            color: powerMouse.containsMouse
              ? powerMenu.shell.selectedFill : powerMenu.shell.normalFill
            border.width: powerMouse.containsMouse ? 1 : 0
            border.color: powerMenu.shell.accent

            Column {
              anchors.centerIn: parent
              spacing: 6
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.icon
                color: powerMouse.containsMouse
                  ? powerMenu.shell.accent : powerMenu.shell.foreground
                font.pixelSize: 24
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: powerMouse.containsMouse
                  ? powerMenu.shell.foreground : powerMenu.shell.muted
              }
            }

            MouseArea {
              id: powerMouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: Quickshell.execDetached(modelData.command)
            }
          }
        }
      }
    }
  }
}
