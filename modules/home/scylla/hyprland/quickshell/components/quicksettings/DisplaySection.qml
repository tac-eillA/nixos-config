pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ColumnLayout {
  id: quick

  required property var shell
  required property var displays

  Layout.fillWidth: true
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
          visible: modelData.enabled && modelData.brightness
          Text { text: "Brightness"; color: quick.shell.muted }
          Slider {
            id: brightnessSlider
            Layout.fillWidth: true
            from: 0
            to: 100
            enabled: modelData.brightness && modelData.brightness.supported
            value: enabled ? Number(modelData.brightness.value) : 0
            property bool changedByUser: false
            onMoved: {
              if (!enabled) return;
              changedByUser = true;
              quick.displays.setBrightness(modelData.name, value);
            }
            onPressedChanged: {
              if (!pressed && changedByUser) {
                quick.displays.setBrightness(modelData.name, value);
                changedByUser = false;
              }
            }
          }
          Text {
            text: brightnessSlider.enabled
              ? Math.round(brightnessSlider.value) + "%" : "—"
            color: quick.shell.muted
          }
        }
        Text {
          Layout.fillWidth: true
          visible: modelData.enabled && modelData.brightness
            && !modelData.brightness.supported
          text: modelData.brightness.reason || "Brightness unavailable"
          color: quick.shell.muted
          font.pixelSize: 10
          elide: Text.ElideRight
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
