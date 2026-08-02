pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

ColumnLayout {
  id: quick

  required property var shell
  required property var core

  Layout.fillWidth: true
  spacing: 8

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 68
    radius: quick.shell.cornerRadius - 2
    color: quick.shell.selectedFill
    RowLayout {
      anchors.fill: parent; anchors.margins: 11
      Text {
        text: "󰁹"
        color: quick.core.batteryPercent < 16 ? quick.shell.urgent : quick.shell.accent
        font.pixelSize: 20
      }
      Column {
        Layout.fillWidth: true
        Text { text: "Battery"; color: quick.shell.foreground; font.bold: true }
        Text {
          text: UPower.displayDevice.ready && UPower.displayDevice.isPresent
            ? quick.core.batteryPercent + "%"
              + (UPower.onBattery ? " · on battery" : " · external power")
            : "No battery detected"
          color: quick.shell.muted
        }
      }
    }
  }
  RowLayout {
    Layout.fillWidth: true
    Repeater {
      model: [
        { name: "power-saver", label: "Saver", icon: "󰌪" },
        { name: "balanced", label: "Balanced", icon: "󰾅" },
        { name: "performance", label: "Performance", icon: "󰓅" }
      ]
      Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: quick.shell.touchLayout ? 52 : 42
        radius: quick.shell.cornerRadius - 3
        color: quick.core.activePowerProfile === modelData.name
          ? quick.shell.selectedFill : quick.shell.normalFill
        border.width: quick.core.activePowerProfile === modelData.name ? 1 : 0
        border.color: quick.shell.accent
        Row {
          anchors.centerIn: parent; spacing: 5
          Text { text: modelData.icon; color: quick.shell.accent }
          Text { text: modelData.label; color: quick.shell.foreground }
        }
        MouseArea { anchors.fill: parent; onClicked: quick.core.setPowerProfile(modelData.name) }
      }
    }
  }
}
