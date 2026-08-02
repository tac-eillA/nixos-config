pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components/quicksettings"

Variants {
  id: quick

  required property var shell
  required property var core
  required property var displays
  required property var adaptive

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

            NetworkSection {
              shell: quick.shell
              core: quick.core
              visible: quick.shell.quickSettingsSection === "network"
            }

            TailscaleSection {
              shell: quick.shell
              core: quick.core
              visible: quick.shell.quickSettingsSection === "tailscale"
            }

            BluetoothSection {
              shell: quick.shell
              core: quick.core
              visible: quick.shell.quickSettingsSection === "bluetooth"
            }

            AudioSection {
              shell: quick.shell
              core: quick.core
              visible: quick.shell.quickSettingsSection === "audio"
            }

            PowerSection {
              shell: quick.shell
              core: quick.core
              visible: quick.shell.quickSettingsSection === "battery"
            }

            DisplaySection {
              shell: quick.shell
              displays: quick.displays
              visible: quick.shell.quickSettingsSection === "display"
            }

            ProfileSection {
              shell: quick.shell
              adaptive: quick.adaptive
              displays: quick.displays
              visible: quick.shell.quickSettingsSection === "profiles"
            }
          }
        }
      }
    }
  }
}
