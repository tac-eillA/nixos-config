pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower

ColumnLayout {
  id: quick

  required property var shell
  required property var adaptive
  required property var displays

  Layout.fillWidth: true
  spacing: 8

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 66
    radius: quick.shell.cornerRadius - 2
    color: quick.shell.selectedFill
    border.color: quick.shell.accent
    RowLayout {
      anchors.fill: parent; anchors.margins: 11
      Text { text: "󰌪"; color: quick.shell.accent; font.pixelSize: 20 }
      Column {
        Layout.fillWidth: true
        Text {
          text: quick.adaptive.activeProfile.length
            ? quick.adaptive.activeProfile : "No matching profile"
          color: quick.shell.foreground
          font.bold: true
        }
        Text {
          text: quick.adaptive.manualProfile.length
            ? "Manual override" : "Selected automatically"
          color: quick.shell.muted
        }
      }
    }
  }
  RowLayout {
    Layout.fillWidth: true
    Repeater {
      model: [
        { label: UPower.onBattery ? "Battery" : "AC power", active: UPower.onBattery },
        { label: !quick.displays.internalDisplayPresent ? "Desktop"
            : quick.displays.externalMonitorConnected ? "Docked" : "Undocked",
          active: quick.displays.externalMonitorConnected },
        { label: quick.adaptive.tabletMode ? "Tablet" : "Laptop",
          active: quick.adaptive.tabletMode }
      ]
      Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 36
        radius: quick.shell.cornerRadius - 3
        color: modelData.active ? quick.shell.selectedFill : quick.shell.normalFill
        Text { anchors.centerIn: parent; text: modelData.label; color: quick.shell.muted }
      }
    }
  }
  Text { text: "Policy mode"; color: quick.shell.muted; font.pixelSize: 12 }
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: quick.shell.touchLayout ? 54 : 44
    radius: quick.shell.cornerRadius - 3
    color: quick.adaptive.manualProfile.length === 0
      ? quick.shell.selectedFill : autoMouse.containsMouse
        ? quick.shell.hoverFill : quick.shell.normalFill
    border.width: quick.adaptive.manualProfile.length === 0 ? 1 : 0
    border.color: quick.shell.accent
    RowLayout {
      anchors.fill: parent; anchors.margins: 10
      Text { text: "󰑐"; color: quick.shell.accent }
      Text { Layout.fillWidth: true; text: "Automatic"; color: quick.shell.foreground; font.bold: true }
      Text { text: quick.adaptive.manualProfile.length === 0 ? "Active" : ""; color: quick.shell.accent }
    }
    MouseArea { id: autoMouse; anchors.fill: parent; hoverEnabled: true; onClicked: quick.adaptive.setManualProfile("auto") }
  }
  Repeater {
    model: quick.adaptive.profileNames
    Rectangle {
      required property string modelData
      Layout.fillWidth: true
      implicitHeight: quick.shell.touchLayout ? 54 : 44
      radius: quick.shell.cornerRadius - 3
      color: quick.adaptive.manualProfile === modelData
        ? quick.shell.selectedFill : profileMouse.containsMouse
          ? quick.shell.hoverFill : quick.shell.normalFill
      border.width: quick.adaptive.manualProfile === modelData ? 1 : 0
      border.color: quick.shell.accent
      RowLayout {
        anchors.fill: parent; anchors.margins: 10
        Text {
          text: modelData === "presentation" ? "󰐩"
            : modelData === "tablet" ? "󰓶" : "󰌪"
          color: quick.shell.accent
        }
        Text {
          Layout.fillWidth: true
          text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
          color: quick.shell.foreground
          font.bold: quick.adaptive.activeProfile === modelData
        }
        Text {
          text: quick.adaptive.activeProfile === modelData ? "Active" : ""
          color: quick.shell.accent
        }
      }
      MouseArea {
        id: profileMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: quick.adaptive.setManualProfile(modelData)
      }
    }
  }
}
