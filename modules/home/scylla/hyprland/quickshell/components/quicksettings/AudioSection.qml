pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

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
