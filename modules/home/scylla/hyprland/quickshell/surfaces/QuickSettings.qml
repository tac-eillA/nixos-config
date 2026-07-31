pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import Quickshell.Wayland

Variants {
  id: quick

  required property var shell
  required property var core
  required property var displays
  required property var adaptive

  property string pendingWifiSsid: ""

  readonly property var sections: [
    { name: "network", label: "Network", icon: "" },
    { name: "tailscale", label: "Tailnet", icon: "󰌷" },
    { name: "bluetooth", label: "Bluetooth", icon: "" },
    { name: "audio", label: "Audio", icon: "" },
    { name: "battery", label: "Power", icon: "󰁹" },
    { name: "display", label: "Displays", icon: "󰍹" },
    { name: "profiles", label: "Profiles", icon: "󰌪" }
  ]

  function titleFor(section) {
    const entry = sections.find(candidate => candidate.name === section);
    return entry ? entry.label : "Quick settings";
  }

  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; right: true }
    margins { top: quick.shell.barHeight + quick.shell.edgeGap; right: quick.shell.edgeGap }
    implicitWidth: quick.shell.quickSettingsSection === "display" ? 540
      : quick.shell.touchLayout ? 460 : 410
    implicitHeight: Math.min(720,
      screen.height - quick.shell.barHeight - quick.shell.edgeGap * 3)
    visible: quick.shell.quickSettingsVisible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      radius: quick.shell.cornerRadius
      color: quick.shell.surface
      border.color: quick.shell.outline
      clip: true

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          Text {
            Layout.fillWidth: true
            text: quick.titleFor(quick.shell.quickSettingsSection)
            color: quick.shell.foreground
            font.bold: true
            font.pixelSize: 16
          }
          Text {
            text: "×"
            color: closeMouse.containsMouse
              ? quick.shell.foreground : quick.shell.muted
            font.pixelSize: 20
            MouseArea {
              id: closeMouse
              anchors.fill: parent
              anchors.margins: -7
              hoverEnabled: true
              onClicked: quick.shell.closeSurface("quickSettings")
            }
          }
        }

        Flow {
          Layout.fillWidth: true
          spacing: 5
          Repeater {
            model: quick.sections
            Rectangle {
              required property var modelData
              width: sectionLabel.implicitWidth + 20
              height: quick.shell.touchLayout ? 38 : 30
              radius: quick.shell.cornerRadius - 3
              color: quick.shell.quickSettingsSection === modelData.name
                ? quick.shell.selectedFill
                : sectionMouse.containsMouse ? quick.shell.hoverFill : quick.shell.normalFill
              border.width: quick.shell.quickSettingsSection === modelData.name ? 1 : 0
              border.color: quick.shell.accent
              Text {
                id: sectionLabel
                anchors.centerIn: parent
                text: modelData.icon + "  " + modelData.label
                color: quick.shell.quickSettingsSection === modelData.name
                  ? quick.shell.accent : quick.shell.foreground
                font.pixelSize: 11
              }
              MouseArea {
                id: sectionMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: quick.shell.openQuickSettings(modelData.name)
              }
            }
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 46
          visible: quick.displays.confirmationPending
          radius: quick.shell.cornerRadius - 3
          color: quick.shell.selectedFill
          border.color: quick.shell.accent
          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            Text {
              Layout.fillWidth: true
              text: "Keep these display settings? They revert automatically."
              color: quick.shell.foreground
              wrapMode: Text.Wrap
              font.pixelSize: 11
            }
            Button { text: "Revert"; onClicked: quick.displays.rollback() }
            Button { text: "Keep"; onClicked: quick.displays.confirm() }
          }
        }

        Flickable {
          id: scroller
          Layout.fillWidth: true
          Layout.fillHeight: true
          contentWidth: width
          contentHeight: content.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          clip: true
          ScrollBar.vertical: ScrollBar {}

          ColumnLayout {
            id: content
            width: scroller.width
            spacing: 8

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "network"
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

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "tailscale"
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

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "bluetooth"
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

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "audio"
              spacing: 8
              Rectangle {
                Layout.fillWidth: true
                implicitHeight: 72
                radius: quick.shell.cornerRadius - 2
                color: quick.shell.selectedFill
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 11
                  Text {
                    text: quick.core.mutedAudio ? "󰖁" : ""
                    color: quick.core.mutedAudio ? quick.shell.muted : quick.shell.accent
                    font.pixelSize: 20
                    MouseArea { anchors.fill: parent; anchors.margins: -7; onClicked: quick.core.toggleAudioMute() }
                  }
                  ColumnLayout {
                    Layout.fillWidth: true
                    RowLayout {
                      Layout.fillWidth: true
                      Text { Layout.fillWidth: true; text: "Volume"; color: quick.shell.foreground; font.bold: true }
                      Text { text: quick.core.volume + "%"; color: quick.shell.muted }
                    }
                    Slider {
                      Layout.fillWidth: true
                      from: 0; to: 100; value: quick.core.volume
                      onMoved: if (quick.core.audioSink && quick.core.audioSink.audio)
                        quick.core.audioSink.audio.volume = value / 100
                    }
                  }
                }
              }
              Text { text: "Output device"; color: quick.shell.muted; font.pixelSize: 12 }
              Repeater {
                model: ScriptModel {
                  values: Pipewire.nodes.values.filter(node => node && node.ready
                    && node.audio && node.isSink && !node.isStream)
                    .sort((a, b) => a.description.localeCompare(b.description))
                }
                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  implicitHeight: 44
                  radius: quick.shell.cornerRadius - 3
                  color: modelData === quick.core.audioSink
                    ? quick.shell.selectedFill : quick.shell.normalFill
                  border.width: modelData === quick.core.audioSink ? 1 : 0
                  border.color: quick.shell.accent
                  RowLayout {
                    anchors.fill: parent; anchors.margins: 9
                    Text { text: "󰓃"; color: quick.shell.accent }
                    Text {
                      Layout.fillWidth: true
                      text: modelData.description || modelData.nickname || modelData.name
                      color: quick.shell.foreground; elide: Text.ElideRight
                    }
                  }
                  MouseArea { anchors.fill: parent; onClicked: Pipewire.preferredDefaultAudioSink = modelData }
                }
              }
              RowLayout {
                Layout.fillWidth: true
                visible: quick.core.audioSource !== null
                Text {
                  text: quick.core.mutedMicrophone ? "󰍭" : ""
                  color: quick.core.mutedMicrophone ? quick.shell.muted : quick.shell.accent
                  MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: quick.core.toggleMicrophoneMute() }
                }
                ColumnLayout {
                  Layout.fillWidth: true
                  RowLayout {
                    Layout.fillWidth: true
                    Text { Layout.fillWidth: true; text: "Microphone"; color: quick.shell.foreground; font.bold: true }
                    Text { text: quick.core.microphoneVolume + "%"; color: quick.shell.muted }
                  }
                  Slider {
                    Layout.fillWidth: true
                    from: 0; to: 100; value: quick.core.microphoneVolume
                    onMoved: if (quick.core.audioSource && quick.core.audioSource.audio)
                      quick.core.audioSource.audio.volume = value / 100
                  }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "battery"
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

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "display"
              spacing: 8
              RowLayout {
                Layout.fillWidth: true
                Text {
                  Layout.fillWidth: true
                  text: quick.displays.enabledMonitors.length + " active display"
                    + (quick.displays.enabledMonitors.length === 1 ? "" : "s")
                  color: quick.shell.muted
                }
                Button { text: "Refresh"; enabled: !quick.displays.busy; onClicked: quick.displays.refresh() }
                Button { text: "wdisplays"; onClicked: quick.shell.run("wdisplays") }
              }
              Text {
                Layout.fillWidth: true
                visible: quick.displays.error.length > 0
                text: quick.displays.error
                color: quick.shell.urgent
                wrapMode: Text.Wrap
              }
              Repeater {
                model: ScriptModel { values: quick.displays.monitors }
                Rectangle {
                  id: monitorCard
                  required property var modelData
                  Layout.fillWidth: true
                  implicitHeight: monitorControls.implicitHeight + 22
                  radius: quick.shell.cornerRadius - 2
                  color: modelData.focused ? quick.shell.selectedFill : quick.shell.normalFill
                  border.width: modelData.focused ? 1 : 0
                  border.color: quick.shell.accent

                  ColumnLayout {
                    id: monitorControls
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    anchors.margins: 11
                    spacing: 7
                    RowLayout {
                      Layout.fillWidth: true
                      Text { text: "󰍹"; color: modelData.enabled ? quick.shell.accent : quick.shell.muted }
                      Column {
                        Layout.fillWidth: true
                        Text { text: modelData.name; color: quick.shell.foreground; font.bold: true }
                        Text {
                          width: parent.width
                          text: modelData.description
                          color: quick.shell.muted
                          font.pixelSize: 10
                          elide: Text.ElideRight
                        }
                      }
                      Switch {
                        checked: modelData.enabled
                        onToggled: quick.displays.setMonitor(modelData.name, "enabled", checked)
                      }
                    }
                    GridLayout {
                      Layout.fillWidth: true
                      visible: modelData.enabled
                      columns: 2
                      columnSpacing: 8
                      rowSpacing: 6
                      Text { text: "Mode"; color: quick.shell.muted }
                      ComboBox {
                        Layout.fillWidth: true
                        model: modelData.availableModes.length
                          ? modelData.availableModes : [modelData.mode]
                        currentIndex: Math.max(0, model.indexOf(modelData.mode))
                        onActivated: index => quick.displays.setMonitor(
                          modelData.name, "mode", model[index])
                      }
                      Text { text: "Scale"; color: quick.shell.muted }
                      ComboBox {
                        Layout.fillWidth: true
                        model: ["1", "1.25", "1.5", "1.75", "2"]
                        currentIndex: {
                          const wanted = String(modelData.scale);
                          const found = model.indexOf(wanted);
                          return found < 0 ? 0 : found;
                        }
                        onActivated: index => quick.displays.setMonitor(
                          modelData.name, "scale", model[index])
                      }
                      Text { text: "Rotation"; color: quick.shell.muted }
                      ComboBox {
                        Layout.fillWidth: true
                        model: ["Normal", "90°", "180°", "270°"]
                        currentIndex: Math.max(0, Math.min(3, Number(modelData.transform)))
                        onActivated: index => quick.displays.setMonitor(
                          modelData.name, "transform", index)
                      }
                      Text { text: "VRR"; color: quick.shell.muted }
                      ComboBox {
                        Layout.fillWidth: true
                        model: ["Off", "On", "Fullscreen", "Content"]
                        currentIndex: Math.max(0, Math.min(3, Number(modelData.vrr)))
                        onActivated: index => quick.displays.setMonitor(modelData.name, "vrr", index)
                      }
                      Text { text: "Mirror"; color: quick.shell.muted }
                      ComboBox {
                        Layout.fillWidth: true
                        property var outputNames: ["Independent"].concat(
                          quick.displays.enabledMonitors
                            .filter(monitor => monitor.name !== modelData.name)
                            .map(monitor => monitor.name))
                        model: outputNames
                        currentIndex: modelData.mirror.length
                          ? Math.max(0, outputNames.indexOf(modelData.mirror)) : 0
                        onActivated: index => quick.displays.setMonitor(modelData.name,
                          "mirror", index === 0 ? "" : outputNames[index])
                      }
                    }
                    RowLayout {
                      Layout.fillWidth: true
                      visible: modelData.enabled && !modelData.mirror.length
                      Text { text: "Position"; color: quick.shell.muted }
                      SpinBox { id: positionX; from: -16384; to: 16384; value: modelData.x; editable: true }
                      Text { text: "×"; color: quick.shell.muted }
                      SpinBox { id: positionY; from: -16384; to: 16384; value: modelData.y; editable: true }
                      Button {
                        text: "Apply"
                        onClicked: quick.displays.setPosition(modelData.name,
                          positionX.value, positionY.value)
                      }
                    }
                  }
                }
              }
              Text { text: "Named display profiles"; color: quick.shell.muted; font.pixelSize: 12 }
              Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                  model: quick.displays.profileNames
                  Button {
                    required property string modelData
                    text: (quick.displays.currentProfile === modelData ? "✓ " : "") + modelData
                    onClicked: quick.displays.applyProfile(modelData, false)
                  }
                }
              }
              RowLayout {
                Layout.fillWidth: true
                TextField {
                  id: displayProfileName
                  Layout.fillWidth: true
                  placeholderText: "Profile name"
                  validator: RegularExpressionValidator { regularExpression: /[A-Za-z0-9._-]+/ }
                }
                Button {
                  text: "Save current"
                  enabled: displayProfileName.acceptableInput
                  onClicked: {
                    quick.displays.saveProfile(displayProfileName.text);
                    displayProfileName.text = "";
                  }
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              visible: quick.shell.quickSettingsSection === "profiles"
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
          }
        }
      }
    }
  }
}
