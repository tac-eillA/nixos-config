pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth

ColumnLayout {
  id: quick

  required property var shell
  required property var core

  Layout.fillWidth: true
  spacing: 8

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 64
    radius: quick.shell.cornerRadius - 2
    color: quick.shell.selectedFill
    RowLayout {
      anchors.fill: parent
      anchors.margins: 11
      Text { text: ""; color: quick.shell.accent; font.pixelSize: 20 }
      Column {
        Layout.fillWidth: true
        Text { text: "Bluetooth"; color: quick.shell.foreground; font.bold: true }
        Text {
          text: quick.core.bluetoothConnectedCount > 0
            ? quick.core.bluetoothConnectedCount + " connected"
            : Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
              ? "No devices connected" : "Disabled"
          color: quick.shell.muted
        }
      }
      Switch {
        enabled: Bluetooth.defaultAdapter !== null
        checked: Bluetooth.defaultAdapter
          ? Bluetooth.defaultAdapter.enabled : false
        onToggled: quick.core.setBluetoothEnabled(checked)
      }
    }
  }
  RowLayout {
    Layout.fillWidth: true
    visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
    Text { Layout.fillWidth: true; text: "Devices"; color: quick.shell.muted }
    Button {
      text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering
        ? "Scanning…" : "Scan"
      enabled: Bluetooth.defaultAdapter && !Bluetooth.defaultAdapter.discovering
      onClicked: quick.core.setBluetoothDiscovery(true)
    }
  }
  Repeater {
    model: ScriptModel {
      values: Bluetooth.devices.values
        .filter(device => device && (device.name || device.deviceName))
        .sort((a, b) => {
          if (a.connected !== b.connected) return a.connected ? -1 : 1;
          if (a.paired !== b.paired) return a.paired ? -1 : 1;
          return (a.name || a.deviceName).localeCompare(b.name || b.deviceName);
        }).slice(0, 8)
    }
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: 50
      radius: quick.shell.cornerRadius - 3
      color: modelData.connected ? quick.shell.selectedFill
        : bluetoothMouse.containsMouse ? quick.shell.hoverFill : quick.shell.normalFill
      border.width: modelData.connected ? 1 : 0
      border.color: quick.shell.accent
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Text { text: ""; color: modelData.connected ? quick.shell.accent : quick.shell.muted }
        Column {
          Layout.fillWidth: true
          Text {
            width: parent.width
            text: modelData.name || modelData.deviceName
            color: quick.shell.foreground
            font.bold: modelData.connected
            elide: Text.ElideRight
          }
          Text {
            text: modelData.pairing ? "Pairing…"
              : modelData.connected ? "Connected"
              : modelData.paired ? "Paired" : "Available"
            color: quick.shell.muted
            font.pixelSize: 11
          }
        }
        Text {
          text: modelData.batteryAvailable
            ? Math.round(modelData.battery * 100) + "%" : ""
          color: quick.shell.muted
        }
      }
      MouseArea {
        id: bluetoothMouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: {
          if (modelData.connected) modelData.disconnect();
          else if (modelData.paired) modelData.connect();
          else modelData.pair();
        }
      }
    }
  }
}
