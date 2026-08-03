pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components/diagnostics"

Variants {
  id: drawer

  required property var shell
  required property var diagnostics
  required property var resources

  property string activeTab: "diagnostics"
  readonly property bool busy: diagnostics.busy || resources.busy
  readonly property string activeError: activeTab === "resources"
    ? resources.error : diagnostics.error

  function selectTab(tab) {
    activeTab = tab;
    if (tab === "resources") resources.refresh();
  }

  function refreshActiveTab() {
    if (activeTab === "resources") resources.refresh();
    else diagnostics.refresh();
  }

  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; right: true }
    margins { top: drawer.shell.barHeight + drawer.shell.edgeGap; right: drawer.shell.edgeGap }
    implicitWidth: drawer.shell.touchLayout ? 560 : 480
    implicitHeight: Math.min(760, screen.height - drawer.shell.barHeight
      - drawer.shell.edgeGap * 3)
    visible: drawer.shell.diagnosticsVisible
    focusable: visible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    Shortcut {
      sequence: "Escape"
      enabled: drawer.shell.diagnosticsVisible
      onActivated: drawer.shell.closeSurface("diagnostics")
    }

    Rectangle {
      anchors.fill: parent
      radius: drawer.shell.cornerRadius
      color: drawer.shell.surface
      border.color: drawer.shell.outline

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          Text {
            Layout.fillWidth: true
            text: "System diagnostics"
            color: drawer.shell.foreground
            font.bold: true
            font.pixelSize: 16
          }
          Text {
            text: drawer.busy ? "Refreshing…" : "󰑐"
            color: refreshMouse.containsMouse
              ? drawer.shell.accent : drawer.shell.muted
            MouseArea {
              id: refreshMouse
              anchors.fill: parent
              anchors.margins: -7
              hoverEnabled: true
              enabled: !drawer.busy
              onClicked: drawer.refreshActiveTab()
            }
          }
          Text {
            text: "×"
            color: closeMouse.containsMouse
              ? drawer.shell.foreground : drawer.shell.muted
            font.pixelSize: 20
            MouseArea {
              id: closeMouse
              anchors.fill: parent
              anchors.margins: -7
              hoverEnabled: true
              onClicked: drawer.shell.closeSurface("diagnostics")
            }
          }
        }

        Text {
          Layout.fillWidth: true
          visible: drawer.activeError.length > 0
          text: drawer.activeError
          color: drawer.shell.urgent
          wrapMode: Text.Wrap
        }

        Flow {
          Layout.fillWidth: true
          spacing: 5
          Repeater {
            model: [
              { name: "diagnostics", label: "Diagnostics", icon: "󰒡" },
              { name: "resources", label: "Resource usage", icon: "󰍛" }
            ]
            Rectangle {
              required property var modelData
              width: tabLabel.implicitWidth + 20
              height: drawer.shell.touchLayout ? 38 : 30
              radius: drawer.shell.cornerRadius - 3
              color: drawer.activeTab === modelData.name
                ? drawer.shell.selectedFill
                : tabMouse.containsMouse ? drawer.shell.hoverFill
                  : drawer.shell.normalFill
              border.width: drawer.activeTab === modelData.name ? 1 : 0
              border.color: drawer.shell.accent
              Text {
                id: tabLabel
                anchors.centerIn: parent
                text: modelData.icon + "  " + modelData.label
                color: drawer.activeTab === modelData.name
                  ? drawer.shell.accent : drawer.shell.foreground
                font.pixelSize: 11
              }
              MouseArea {
                id: tabMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: drawer.selectTab(modelData.name)
              }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          visible: drawer.activeTab === "diagnostics"
          spacing: 8
          Repeater {
            model: [
              { label: "Failed services", value: drawer.diagnostics.failedServiceCount,
                warning: drawer.diagnostics.failedServiceCount > 0 },
              { label: "Thermal alerts", value: drawer.diagnostics.thermalWarningCount,
                warning: drawer.diagnostics.thermalWarningCount > 0 },
              { label: "Battery alerts", value: drawer.diagnostics.batteryWarningCount,
                warning: drawer.diagnostics.batteryWarningCount > 0 }
            ]
            Rectangle {
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: 58
              radius: drawer.shell.cornerRadius - 2
              color: modelData.warning
                ? Qt.rgba(drawer.shell.urgent.r, drawer.shell.urgent.g,
                  drawer.shell.urgent.b, 0.16) : drawer.shell.normalFill
              border.width: modelData.warning ? 1 : 0
              border.color: drawer.shell.urgent
              Column {
                anchors.centerIn: parent
                spacing: 2
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.value
                  color: modelData.warning
                    ? drawer.shell.urgent : drawer.shell.foreground
                  font.bold: true
                }
                Text {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: modelData.label
                  color: drawer.shell.muted
                  font.pixelSize: 10
                }
              }
            }
          }
        }

        Flickable {
          id: scroller
          Layout.fillWidth: true
          Layout.fillHeight: drawer.activeTab === "diagnostics"
          visible: drawer.activeTab === "diagnostics"
          contentWidth: width
          contentHeight: content.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          clip: true
          ScrollBar.vertical: ScrollBar {}

          ColumnLayout {
            id: content
            width: scroller.width
            spacing: 10

            Text {
              text: "System state"
              color: drawer.shell.muted
              font.pixelSize: 12
            }
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: generationContent.implicitHeight + 20
              radius: drawer.shell.cornerRadius - 2
              color: drawer.shell.normalFill
              border.color: drawer.shell.outline
              Column {
                id: generationContent
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 10
                spacing: 5
                Text {
                  text: drawer.diagnostics.rebootPending
                    ? "Reboot recommended"
                    : drawer.diagnostics.activationPending
                      ? "A newer generation is not active" : "Running generation is current"
                  color: drawer.diagnostics.rebootPending
                    || drawer.diagnostics.activationPending
                      ? drawer.shell.urgent : drawer.shell.foreground
                  font.bold: true
                }
                Text {
                  width: parent.width
                  text: (drawer.diagnostics.report.generations.generations || []).length
                    + " recent NixOS generations available"
                  color: drawer.shell.muted
                }
                Text {
                  width: parent.width
                  visible: (drawer.diagnostics.report.hyprlandErrors || []).length > 0
                  text: drawer.diagnostics.report.hyprlandErrors.join("\n")
                  color: drawer.shell.urgent
                  wrapMode: Text.Wrap
                }
              }
            }

            Text {
              text: "Failed services"
              color: drawer.shell.muted
              font.pixelSize: 12
            }
            Text {
              Layout.fillWidth: true
              visible: drawer.diagnostics.failedServiceCount === 0
              text: "No failed system or user services."
              color: drawer.shell.muted
              leftPadding: 10
            }
            Repeater {
              model: ScriptModel {
                values: (drawer.diagnostics.report.failedServices.system || [])
                  .map(unit => Object.assign({ scope: "system" }, unit))
                  .concat((drawer.diagnostics.report.failedServices.user || [])
                    .map(unit => Object.assign({ scope: "user" }, unit)))
              }
              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 52
                radius: drawer.shell.cornerRadius - 2
                color: drawer.shell.normalFill
                border.color: drawer.shell.urgent
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 10
                  Text { text: ""; color: drawer.shell.urgent }
                  Column {
                    Layout.fillWidth: true
                    Text {
                      width: parent.width
                      text: modelData.unit
                      color: drawer.shell.foreground
                      font.bold: true
                      elide: Text.ElideRight
                    }
                    Text {
                      width: parent.width
                      text: modelData.scope + " · " + modelData.description
                      color: drawer.shell.muted
                      elide: Text.ElideRight
                      font.pixelSize: 11
                    }
                  }
                }
              }
            }

            Text {
              text: "Battery health"
              visible: (drawer.diagnostics.report.batteries || []).length > 0
              color: drawer.shell.muted
              font.pixelSize: 12
            }
            Repeater {
              model: ScriptModel { values: drawer.diagnostics.report.batteries || [] }
              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 54
                radius: drawer.shell.cornerRadius - 2
                color: drawer.shell.normalFill
                border.width: modelData.health !== null && modelData.health < 80 ? 1 : 0
                border.color: drawer.shell.urgent
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 10
                  Text { text: "󰁹"; color: drawer.shell.accent; font.pixelSize: 18 }
                  Text {
                    Layout.fillWidth: true
                    text: modelData.name + " · " + modelData.capacity + "% · " + modelData.status
                    color: drawer.shell.foreground
                  }
                  Text {
                    text: modelData.health === null ? "Health unavailable"
                      : modelData.health + "% health"
                    color: modelData.health !== null && modelData.health < 80
                      ? drawer.shell.urgent : drawer.shell.muted
                  }
                }
              }
            }

            Text {
              text: "Thermal state"
              visible: (drawer.diagnostics.report.thermal || []).length > 0
              color: drawer.shell.muted
              font.pixelSize: 12
            }
            Repeater {
              model: ScriptModel { values: drawer.diagnostics.report.thermal || [] }
              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 44
                radius: drawer.shell.cornerRadius - 2
                color: drawer.shell.normalFill
                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 10
                  Text {
                    text: modelData.severity === "normal" ? "" : ""
                    color: modelData.severity === "normal"
                      ? drawer.shell.accent : drawer.shell.urgent
                  }
                  Text {
                    Layout.fillWidth: true
                    text: modelData.name
                    color: drawer.shell.foreground
                  }
                  Text {
                    text: Number(modelData.temperature).toFixed(1) + "°C"
                    color: modelData.severity === "normal"
                      ? drawer.shell.muted : drawer.shell.urgent
                  }
                }
              }
            }

            Text {
              text: "Suspend and resume"
              color: drawer.shell.muted
              font.pixelSize: 12
            }
            Rectangle {
              Layout.fillWidth: true
              implicitHeight: suspendContent.implicitHeight + 20
              radius: drawer.shell.cornerRadius - 2
              color: drawer.shell.normalFill
              Column {
                id: suspendContent
                anchors { left: parent.left; right: parent.right; top: parent.top }
                anchors.margins: 10
                spacing: 5
                Text {
                  text: "Last result: " + (drawer.diagnostics.report.suspend.result || "unknown")
                  color: drawer.diagnostics.report.suspend.result === "success"
                    ? drawer.shell.foreground : drawer.shell.muted
                  font.bold: true
                }
                Repeater {
                  model: (drawer.diagnostics.report.suspend.recent || []).slice(-4)
                  Text {
                    required property string modelData
                    width: suspendContent.width
                    text: modelData
                    color: drawer.shell.muted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                  }
                }
              }
            }
          }
        }

        Flickable {
          id: resourceScroller
          Layout.fillWidth: true
          Layout.fillHeight: drawer.activeTab === "resources"
          visible: drawer.activeTab === "resources"
          contentWidth: width
          contentHeight: resourceContent.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          clip: true
          ScrollBar.vertical: ScrollBar {}

          ColumnLayout {
            id: resourceContent
            width: resourceScroller.width
            spacing: 10

            ResourceUsageSection {
              shell: drawer.shell
              resources: drawer.resources
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: drawer.diagnostics.updatedAt.length
            ? "Updated " + drawer.diagnostics.updatedAt : "Not yet refreshed"
          color: drawer.shell.muted
          font.pixelSize: 10
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }
}
