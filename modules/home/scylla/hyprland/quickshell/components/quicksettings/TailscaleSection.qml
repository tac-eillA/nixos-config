pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
  id: quick

  required property var shell
  required property var core

  Layout.fillWidth: true
  spacing: 8

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 72
    radius: quick.shell.cornerRadius - 2
    color: quick.shell.selectedFill
    border.color: quick.core.tailscaleState === "Running"
      ? quick.shell.accent : quick.shell.outline
    RowLayout {
      anchors.fill: parent
      anchors.margins: 11
      Text {
        text: quick.core.tailscaleState === "Running" ? "󰌷" : "󰌸"
        color: quick.core.tailscaleState === "Running"
          ? quick.shell.accent : quick.shell.muted
        font.pixelSize: 22
      }
      Column {
        Layout.fillWidth: true
        Text {
          text: quick.core.tailscaleHost || "Tailscale"
          color: quick.shell.foreground
          font.bold: true
        }
        Text {
          text: quick.core.tailscaleState === "Running"
            ? (quick.core.tailscaleIp || "Connected") : quick.core.tailscaleState
          color: quick.shell.muted
        }
      }
      Switch {
        checked: quick.core.tailscaleState === "Running"
        enabled: !quick.core.tailscaleActionRunning
        onToggled: if (checked !== (quick.core.tailscaleState === "Running"))
          quick.core.setTailscaleEnabled(checked)
      }
    }
  }
  Text {
    text: quick.core.tailscalePeers.length + " online peers"
    color: quick.shell.muted
  }
  Repeater {
    model: ScriptModel { values: quick.core.tailscalePeers.slice(0, 8) }
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: 48
      radius: quick.shell.cornerRadius - 3
      color: modelData.active ? quick.shell.selectedFill : quick.shell.normalFill
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Text {
          text: modelData.exitNode ? "󰒋" : "󰇅"
          color: modelData.active ? quick.shell.accent : quick.shell.foreground
        }
        Column {
          Layout.fillWidth: true
          Text { text: modelData.name; color: quick.shell.foreground; font.bold: modelData.active }
          Text { text: modelData.ip; color: quick.shell.muted; font.pixelSize: 11 }
        }
        Button {
          text: modelData.exitNode ? "Clear exit" : "Use exit"
          enabled: !quick.core.tailscaleActionRunning
          onClicked: quick.core.setExitNode(modelData.exitNode ? "" : modelData.ip)
        }
      }
    }
  }
}
