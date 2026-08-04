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

  function wiredStateLabel(device) {
    if (device.active) return "Connected";
    if (device.state === "unavailable") return "Unavailable";
    if (device.state === "unmanaged") return "Unmanaged";
    return "Disconnected";
  }

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
            ? (quick.core.wifiNetworkName === "offline"
              ? "Not connected" : quick.core.wifiNetworkName) : "Disabled"
          color: quick.shell.muted
        }
      }
      Switch {
        checked: quick.core.wifiEnabled
        enabled: !quick.core.networkActionRunning
        onToggled: quick.core.setWifiEnabled(checked)
      }
    }
  }

  Text {
    Layout.fillWidth: true
    visible: quick.core.wiredDevices.count > 0
    text: "Wired"
    color: quick.shell.muted
  }

  Repeater {
    model: ScriptModel {
      values: quick.core.wiredDevices.count > 0
        ? Array.from({ length: quick.core.wiredDevices.count },
          (_, index) => quick.core.wiredDevices.get(index)) : []
    }
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: quick.shell.touchLayout ? 58 : 48
      radius: quick.shell.cornerRadius - 3
      color: modelData.active ? quick.shell.selectedFill : quick.shell.normalFill
      border.width: modelData.active ? 1 : 0
      border.color: quick.shell.accent
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Text {
          text: modelData.active ? "󰈀" : "󰈂"
          color: modelData.active ? quick.shell.accent : quick.shell.foreground
          font.pixelSize: 18
        }
        Column {
          Layout.fillWidth: true
          Text {
            width: parent.width
            text: modelData.connectionName.length
              ? modelData.connectionName : modelData.interfaceName
            color: quick.shell.foreground
            font.bold: modelData.active
            elide: Text.ElideRight
          }
          Text {
            text: modelData.interfaceName + " · " + quick.wiredStateLabel(modelData)
            color: quick.shell.muted
            font.pixelSize: 11
          }
        }
        Button {
          text: modelData.active ? "Disconnect" : "Connect"
          enabled: !quick.core.networkActionRunning
            && (modelData.active || modelData.state === "disconnected"
              || modelData.state === "failed")
          onClicked: {
            if (modelData.active)
              quick.core.disconnectWired(modelData.interfaceName);
            else
              quick.core.connectWired(modelData.interfaceName);
          }
        }
      }
    }
  }

  Text {
    Layout.fillWidth: true
    text: "VPN"
    color: quick.shell.muted
  }

  Text {
    Layout.fillWidth: true
    visible: quick.core.vpnConnections.count === 0
    text: "No VPN profiles"
    color: quick.shell.muted
    font.pixelSize: 11
  }

  Repeater {
    model: ScriptModel {
      values: quick.core.vpnConnections.count > 0
        ? Array.from({ length: quick.core.vpnConnections.count },
          (_, index) => quick.core.vpnConnections.get(index)) : []
    }
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: quick.shell.touchLayout ? 58 : 48
      radius: quick.shell.cornerRadius - 3
      color: modelData.active ? quick.shell.selectedFill : quick.shell.normalFill
      border.width: modelData.active ? 1 : 0
      border.color: quick.shell.accent
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Text {
          text: modelData.active ? "󰌆" : "󰌇"
          color: modelData.active ? quick.shell.accent : quick.shell.foreground
          font.pixelSize: 18
        }
        Column {
          Layout.fillWidth: true
          Text {
            width: parent.width
            text: modelData.name
            color: quick.shell.foreground
            font.bold: modelData.active
            elide: Text.ElideRight
          }
          Text {
            text: modelData.type + " · " + (modelData.active ? "Connected" : "Disconnected")
            color: quick.shell.muted
            font.pixelSize: 11
          }
        }
        Button {
          text: modelData.active ? "Disconnect" : "Connect"
          enabled: !quick.core.networkActionRunning
          onClicked: {
            if (modelData.active)
              quick.core.disconnectVpn(modelData.uuid, modelData.name);
            else
              quick.core.connectVpn(modelData.uuid, modelData.name);
          }
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    visible: quick.core.wifiEnabled
    Text { Layout.fillWidth: true; text: "Available networks"; color: quick.shell.muted }
    Button {
      text: quick.core.networkScanRunning ? "Scanning…" : "Refresh"
      enabled: !quick.core.networkScanRunning && !quick.core.networkActionRunning
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
