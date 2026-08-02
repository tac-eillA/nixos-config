pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
  id: quick

  required property var shell
  required property var core
  property string pendingWifiSsid: ""

  Layout.fillWidth: true
  spacing: 8

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 62
    radius: quick.shell.cornerRadius - 2
    color: quick.shell.selectedFill
    border.color: quick.shell.accent
    RowLayout {
      anchors.fill: parent
      anchors.margins: 11
      Text {
        text: quick.core.wifiEnabled ? "" : "󰤭"
        color: quick.core.wifiEnabled ? quick.shell.accent : quick.shell.muted
        font.pixelSize: 20
      }
      Column {
        Layout.fillWidth: true
        Text { text: "Wi-Fi"; color: quick.shell.foreground; font.bold: true }
        Text {
          text: quick.core.wifiEnabled
            ? (quick.core.networkName === "offline"
              ? "Not connected" : quick.core.networkName) : "Disabled"
          color: quick.shell.muted
        }
      }
      Switch {
        checked: quick.core.wifiEnabled
        onToggled: quick.core.setWifiEnabled(checked)
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    visible: quick.core.wifiEnabled
    Text { Layout.fillWidth: true; text: "Available networks"; color: quick.shell.muted }
    Button {
      text: quick.core.networkScanRunning ? "Scanning…" : "Refresh"
      enabled: !quick.core.networkScanRunning
      onClicked: quick.core.scanNetworks()
    }
  }

  Repeater {
    model: ScriptModel {
      values: quick.core.wifiNetworks.count > 0
        ? Array.from({ length: Math.min(8, quick.core.wifiNetworks.count) },
          (_, index) => quick.core.wifiNetworks.get(index)) : []
    }
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: quick.shell.touchLayout ? 58 : 48
      radius: quick.shell.cornerRadius - 3
      color: modelData.active ? quick.shell.selectedFill
        : wifiMouse.containsMouse ? quick.shell.hoverFill : quick.shell.normalFill
      border.width: modelData.active ? 1 : 0
      border.color: quick.shell.accent
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Text {
          text: modelData.signal > 70 ? "󰤨"
            : modelData.signal > 45 ? "󰤥"
            : modelData.signal > 20 ? "󰤢" : "󰤟"
          color: modelData.active ? quick.shell.accent : quick.shell.foreground
          font.pixelSize: 18
        }
        Column {
          Layout.fillWidth: true
          Text {
            width: parent.width
            text: modelData.ssid
            color: quick.shell.foreground
            font.bold: modelData.active
            elide: Text.ElideRight
          }
          Text {
            text: modelData.active ? "Connected"
              : (modelData.security.length ? modelData.security : "Open network")
            color: quick.shell.muted
            font.pixelSize: 11
          }
        }
        Text { text: modelData.security.length ? "" : ""; color: quick.shell.muted }
      }
      MouseArea {
        id: wifiMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: !modelData.active && !quick.core.networkActionRunning
        onClicked: {
          if (modelData.security.length) {
            quick.pendingWifiSsid = modelData.ssid;
            wifiPassword.text = "";
            wifiPassword.forceActiveFocus();
          } else {
            quick.core.connectWifi(modelData.ssid, "");
          }
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    visible: quick.pendingWifiSsid.length > 0
    TextField {
      id: wifiPassword
      Layout.fillWidth: true
      placeholderText: "Password for " + quick.pendingWifiSsid
      echoMode: TextInput.Password
      color: quick.shell.foreground
      onAccepted: wifiConnect.clicked()
    }
    Button {
      id: wifiConnect
      text: "Connect"
      enabled: wifiPassword.text.length > 0
        && !quick.core.networkActionRunning
      onClicked: {
        quick.core.connectWifi(quick.pendingWifiSsid, wifiPassword.text);
        quick.pendingWifiSsid = "";
        wifiPassword.text = "";
      }
    }
  }
}
