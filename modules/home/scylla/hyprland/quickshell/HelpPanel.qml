pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
  id: helpRoot
  required property var shell
  property int currentTab: 0

  property var shortcuts: [
    ["Super + Space", "Open Vicinae"],
    ["Super + Return", "Open Ghostty terminal"],
    ["Super + B", "Open Firefox"],
    ["Super + Shift + B", "Open Helium"],
    ["Super + Shift + C", "Open T3 Code"],
    ["Super + E", "Open Thunar files"],
    ["Super + Q", "Close the focused window"],
    ["Super + F", "Toggle fullscreen"],
    ["Super + V", "Toggle floating"],
    ["Super + H / J / K / L", "Move focus"],
    ["Super + Shift + H / J / K / L", "Move the focused window"],
    ["Super + 1–5", "Switch workspace"],
    ["Super + Shift + 1–5", "Send window to workspace"],
    ["Super + M", "Open display controls"],
    ["Super + Shift + M", "Open wdisplays fallback"],
    ["Super + D", "Open system diagnostics"],
    ["Super + Shift + P", "Toggle presentation mode"],
    ["Super + drag", "Move a window"],
    ["Super + right-drag", "Resize a window"],
    ["Print", "Copy an area screenshot"],
    ["Shift + Print", "Save an area screenshot"],
    ["Super + Escape", "Lock the session"]
  ]

  property var defaults: [
    ["Web", "Firefox · Helium is the secondary browser"],
    ["Terminal", "Ghostty"],
    ["Files", "Thunar"],
    ["Editor", "Neovim"],
    ["Images", "imv"],
    ["Documents", "LibreOffice"],
    ["App search", "Vicinae"]
  ]

  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true }
    margins { top: helpRoot.shell.barHeight + helpRoot.shell.edgeGap }
    implicitWidth: 760
    implicitHeight: Math.min(680, screen.height - helpRoot.shell.barHeight
      - helpRoot.shell.edgeGap * 3)
    visible: helpRoot.shell.helpVisible
    focusable: visible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    Shortcut {
      sequence: "Escape"
      enabled: helpRoot.shell.helpVisible
      onActivated: helpRoot.shell.helpVisible = false
    }

    Rectangle {
      anchors.fill: parent
      radius: helpRoot.shell.cornerRadius
      color: helpRoot.shell.surface
      border.color: helpRoot.shell.outline

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          Text {
            Layout.fillWidth: true
            text: "System guide"
            color: helpRoot.shell.foreground
            font.bold: true
            font.pixelSize: 19
          }
          Text {
            text: "Hyprland · NixOS"
            color: helpRoot.shell.accent
          }
          Button {
            text: "×"
            flat: true
            onClicked: helpRoot.shell.helpVisible = false
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 7

          Repeater {
            model: [
              { label: "Keybinds", icon: "󰌌" },
              { label: "Applications", icon: "󰀻" },
              { label: "Workflow", icon: "󰙅" }
            ]

            Rectangle {
              required property int index
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: 42
              radius: helpRoot.shell.cornerRadius - 2
              color: helpRoot.currentTab === index
                ? helpRoot.shell.selectedFill
                : tabMouse.containsMouse
                  ? helpRoot.shell.hoverFill : helpRoot.shell.normalFill
              border.width: helpRoot.currentTab === index ? 1 : 0
              border.color: helpRoot.shell.accent

              Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                  text: modelData.icon
                  color: helpRoot.currentTab === index
                    ? helpRoot.shell.accent : helpRoot.shell.muted
                  font.pixelSize: 17
                }

                Text {
                  text: modelData.label
                  color: helpRoot.currentTab === index
                    ? helpRoot.shell.foreground : helpRoot.shell.muted
                  font.bold: helpRoot.currentTab === index
                }
              }

              MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: helpRoot.currentTab = index
              }

              Behavior on color {
                ColorAnimation {
                  duration: helpRoot.shell.transitionDuration
                  easing.type: Easing.OutCubic
                }
              }
            }
          }
        }

        StackLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          currentIndex: helpRoot.currentTab

          Flickable {
            contentWidth: width
            contentHeight: shortcutColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
              id: shortcutColumn
              width: parent.width
              spacing: 5
              Repeater {
                model: helpRoot.shortcuts
                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  implicitHeight: 42
                  radius: helpRoot.shell.cornerRadius - 3
                  color: helpRoot.shell.normalFill
                  RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    Text {
                      Layout.preferredWidth: 245
                      text: modelData[0]
                      color: helpRoot.shell.accent
                      font.bold: true
                    }
                    Text {
                      Layout.fillWidth: true
                      text: modelData[1]
                      color: helpRoot.shell.foreground
                    }
                  }
                }
              }
            }
          }

          ColumnLayout {
            spacing: 7
            Repeater {
              model: helpRoot.defaults
              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 52
                radius: helpRoot.shell.cornerRadius - 3
                color: helpRoot.shell.normalFill
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  Text {
                    Layout.preferredWidth: 145
                    text: modelData[0]
                    color: helpRoot.shell.muted
                  }
                  Text {
                    Layout.fillWidth: true
                    text: modelData[1]
                    color: helpRoot.shell.foreground
                    font.bold: true
                  }
                }
              }
            }
            Item { Layout.fillHeight: true }
          }

          Flickable {
            contentWidth: width
            contentHeight: workflowColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {}
            ColumnLayout {
              id: workflowColumn
              width: parent.width
              spacing: 10
              Repeater {
                model: [
                  ["1", "Launch", "Press Super + Space to open Vicinae. Use Super + Return when you want a terminal."],
                  ["2", "Organize", "Windows tile automatically. Use workspaces 1–5 for separate activities, and Super + Shift + a number to send a window there."],
                  ["3", "Navigate", "Use Super + H/J/K/L to focus adjacent windows. A three-finger horizontal swipe changes workspaces on a touchpad."],
                  ["4", "Adjust", "The top bar controls Wi-Fi, Bluetooth, audio, power, notifications, wallpaper, and fingerprints. Right-click some status items for quick toggles."],
                  ["5", "Make it yours", "Super + Shift + W opens the wallpaper picker. Display layouts saved through Super + M persist across rebuilds."],
                  ["6", "Recover", "Super + Escape locks the system. Super + Shift + E opens session and power controls. Your password always remains the authentication fallback."]
                ]
                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  implicitHeight: workflowText.implicitHeight + 26
                  radius: helpRoot.shell.cornerRadius - 3
                  color: helpRoot.shell.normalFill
                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 13
                    Rectangle {
                      Layout.preferredWidth: 32
                      Layout.preferredHeight: 32
                      radius: 16
                      color: helpRoot.shell.selectedFill
                      Text {
                        anchors.centerIn: parent
                        text: modelData[0]
                        color: helpRoot.shell.accent
                        font.bold: true
                      }
                    }
                    ColumnLayout {
                      Layout.fillWidth: true
                      Text {
                        text: modelData[1]
                        color: helpRoot.shell.foreground
                        font.bold: true
                      }
                      Text {
                        id: workflowText
                        Layout.fillWidth: true
                        text: modelData[2]
                        color: helpRoot.shell.muted
                        wrapMode: Text.Wrap
                      }
                    }
                  }
                }
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: "Tip: Super is usually the key with the Windows or Command logo."
          color: helpRoot.shell.muted
          font.pixelSize: 11
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }
  }
}
