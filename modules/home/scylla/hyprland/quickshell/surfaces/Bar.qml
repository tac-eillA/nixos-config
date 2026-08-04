pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "../components"

Variants {
  id: bar

  required property var shell
  required property var core
  required property var diagnostics
  required property var adaptive

  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; left: true; right: true }
    implicitHeight: bar.shell.barHeight
    exclusiveZone: bar.shell.barHeight
    color: bar.shell.background

    Item {
      anchors.fill: parent

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
          model: 5

          Rectangle {
            required property int index
            property var workspace: {
              const wanted = index + 1;
              for (let i = 0; i < Hyprland.workspaces.values.length; ++i) {
                if (Hyprland.workspaces.values[i].id === wanted)
                  return Hyprland.workspaces.values[i];
              }
              return null;
            }
            width: workspace && workspace.focused ? 30 : 24
            height: bar.shell.touchLayout ? 34 : 26
            radius: bar.shell.cornerRadius - 4
            color: workspace && workspace.focused ? bar.shell.selectedFill
              : workspaceMouse.containsMouse ? bar.shell.hoverFill : "transparent"
            border.width: workspace && workspace.focused ? 1 : 0
            border.color: bar.shell.accent

            Text {
              anchors.centerIn: parent
              text: parent.index + 1
              color: parent.workspace && parent.workspace.focused
                ? bar.shell.accent : bar.shell.foreground
              font.bold: parent.workspace && parent.workspace.focused
            }

            MouseArea {
              id: workspaceMouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
            }

            Behavior on width {
              NumberAnimation {
                duration: bar.shell.transitionDuration
                easing.type: Easing.OutCubic
              }
            }
            Behavior on color {
              ColorAnimation {
                duration: bar.shell.transitionDuration
                easing.type: Easing.OutCubic
              }
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, 360)
          text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
          color: bar.shell.muted
          elide: Text.ElideRight
        }
      }

      SystemClock {
        id: clock
        precision: SystemClock.Minutes
      }

      Rectangle {
        id: clockButton
        anchors.centerIn: parent
        implicitWidth: clockText.implicitWidth + 20
        height: bar.shell.touchLayout ? 36 : 28
        radius: bar.shell.cornerRadius - 3
        color: clockMouse.containsMouse ? bar.shell.hoverFill : "transparent"

        Text {
          id: clockText
          anchors.centerIn: parent
          text: bar.shell.clockAlternate
            ? Qt.formatDateTime(clock.date, "yyyy-MM-dd  'W'ww")
            : Qt.formatDateTime(clock.date, "ddd MMM dd  HH:mm")
          color: bar.shell.foreground
          font.bold: true
        }

        MouseArea {
          id: clockMouse
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
              bar.shell.clockAlternate = !bar.shell.clockAlternate;
            else
              bar.shell.toggleSurface("calendar");
          }
        }
      }

      StatusItem {
        shell: bar.shell
        anchors.right: clockButton.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        icon: "󰈷"
        text: ""
        iconSize: 19
        textColor: bar.shell.fingerprintVisible
          ? bar.shell.accent : bar.shell.foreground
        onClicked: bar.shell.toggleFingerprint()
      }

      Row {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Rectangle {
          visible: bar.core.activePlayer !== null
          width: visible ? Math.min(mediaText.implicitWidth + 38, 280) : 0
          height: bar.shell.touchLayout ? 36 : 28
          radius: bar.shell.cornerRadius - 3
          color: mediaMouse.containsMouse
            ? bar.shell.hoverFill : bar.shell.normalFill

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 6
            Text {
              text: bar.core.activePlayer && bar.core.activePlayer.isPlaying ? "" : ""
              color: bar.shell.accent
            }
            Text {
              id: mediaText
              Layout.fillWidth: true
              text: bar.core.mediaLabel
              color: bar.shell.foreground
              elide: Text.ElideRight
            }
          }

          MouseArea {
            id: mediaMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: mouse => bar.core.mediaAction(mouse.button === Qt.MiddleButton
              ? "next" : "playPause")
          }
        }

        StatusItem {
          shell: bar.shell
          icon: bar.core.networkName === "offline" ? "󰤭"
            : bar.core.networkTransport === "ethernet" ? "󰈀" : ""
          text: bar.core.networkName === "offline" ? "" : bar.core.networkName
          textColor: bar.core.networkName === "offline"
            ? bar.shell.muted : bar.shell.foreground
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
              bar.core.setWifiEnabled(!bar.core.wifiEnabled);
            else
              bar.shell.toggleQuickSettings("network");
          }
        }

        StatusItem {
          shell: bar.shell
          icon: bar.core.tailscaleState === "Running" ? "󰌷" : "󰌸"
          text: bar.core.tailscaleState === "Running"
            ? bar.core.tailscalePeers.length : ""
          textColor: bar.core.tailscaleState === "Running"
            ? bar.shell.accent : bar.shell.muted
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
              bar.core.setTailscaleEnabled(bar.core.tailscaleState !== "Running");
            else
              bar.shell.toggleQuickSettings("tailscale");
          }
        }

        StatusItem {
          shell: bar.shell
          visible: Bluetooth.defaultAdapter !== null
          icon: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "" : "󰂲"
          text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
            && bar.core.bluetoothConnectedCount > 0
              ? bar.core.bluetoothConnectedCount : ""
          textColor: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
            ? bar.shell.foreground : bar.shell.muted
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton && Bluetooth.defaultAdapter)
              bar.core.setBluetoothEnabled(!Bluetooth.defaultAdapter.enabled);
            else
              bar.shell.toggleQuickSettings("bluetooth");
          }
        }

        StatusItem {
          shell: bar.shell
          icon: bar.core.mutedAudio ? "󰖁" : ""
          text: bar.core.volume + "%"
          textColor: bar.core.mutedAudio ? bar.shell.muted : bar.shell.foreground
          onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) bar.core.toggleAudioMute();
            else bar.shell.toggleQuickSettings("audio");
          }
          onWheeled: wheel => bar.core.adjustVolume(wheel.angleDelta.y > 0 ? 3 : -3)
        }

        StatusItem {
          shell: bar.shell
          visible: UPower.displayDevice.ready && UPower.displayDevice.isPresent
          icon: "󰁹"
          text: bar.core.batteryPercent + "%"
          textColor: bar.core.batteryPercent < 16
            ? bar.shell.urgent : bar.shell.foreground
          onClicked: bar.shell.toggleQuickSettings("battery")
        }

        StatusItem {
          shell: bar.shell
          icon: "󰍹"
          textColor: bar.shell.quickSettingsVisible
            && bar.shell.quickSettingsSection === "display"
            ? bar.shell.accent : bar.shell.foreground
          onClicked: bar.shell.toggleQuickSettings("display")
        }

        StatusItem {
          shell: bar.shell
          icon: bar.adaptive.manualProfile === "presentation" ? "󰐩" : "󰌪"
          text: bar.adaptive.activeProfile
          textColor: bar.adaptive.manualProfile.length
            ? bar.shell.accent : bar.shell.muted
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
              bar.adaptive.setManualProfile("auto");
            else
              bar.shell.toggleQuickSettings("profiles");
          }
        }

        StatusItem {
          shell: bar.shell
          icon: "󰒡"
          text: bar.diagnostics.issueCount > 0 ? bar.diagnostics.issueCount : ""
          textColor: bar.diagnostics.issueCount > 0
            ? bar.shell.urgent : bar.shell.muted
          onClicked: bar.shell.toggleSurface("diagnostics")
        }

        StatusItem {
          shell: bar.shell
          icon: bar.core.idleInhibited ? "󰅶" : "󰾪"
          textColor: bar.core.idleInhibited ? bar.shell.accent : bar.shell.muted
          onClicked: bar.core.setIdleInhibited(!bar.core.idleInhibited, false)
        }

        StatusItem {
          shell: bar.shell
          icon: bar.core.doNotDisturb ? "󰂛" : "󰂚"
          text: bar.core.doNotDisturb ? "" : bar.core.notificationHistory.count
          textColor: bar.core.doNotDisturb ? bar.shell.muted : bar.shell.foreground
          onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
              bar.core.doNotDisturb = !bar.core.doNotDisturb;
            else
              bar.shell.toggleSurface("notifications");
          }
        }

        StatusItem {
          shell: bar.shell
          icon: "?"
          textColor: bar.shell.helpVisible ? bar.shell.accent : bar.shell.foreground
          onClicked: bar.shell.toggleSurface("help")
        }

        StatusItem {
          shell: bar.shell
          icon: ""
          onClicked: bar.shell.toggleSurface("power")
        }
      }
    }
  }
}
