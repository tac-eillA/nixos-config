pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

ColumnLayout {
  id: resource

  required property var shell
  required property var resources

  Layout.fillWidth: true
  spacing: 8

  function formatWatts(value) {
    return value === null || value === undefined
      ? "Unavailable" : Number(value).toFixed(1) + " W";
  }

  function formatPercent(value) {
    return value === null || value === undefined
      ? "Unavailable" : Number(value).toFixed(1) + "%";
  }

  function formatBytes(value) {
    if (value === null || value === undefined) return "Unavailable";
    let bytes = Number(value);
    if (bytes >= 1024 * 1024 * 1024)
      return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GiB";
    if (bytes >= 1024 * 1024)
      return (bytes / (1024 * 1024)).toFixed(1) + " MiB";
    if (bytes >= 1024)
      return (bytes / 1024).toFixed(1) + " KiB";
    return Math.round(bytes) + " B";
  }

  function processSummary(modelData) {
    const gpu = modelData.gpuPercent === null || modelData.gpuPercent === undefined
      ? "" : " · " + formatPercent(modelData.gpuPercent) + " GPU";
    const count = modelData.processCount === 1 ? "process" : "processes";
    return modelData.processCount + " " + count
      + " · " + formatPercent(modelData.cpuPercent) + " CPU" + gpu;
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 76
    radius: resource.shell.cornerRadius - 2
    color: resource.shell.selectedFill
    border.color: resource.shell.accent

    RowLayout {
      anchors.fill: parent
      anchors.margins: 11
      Text {
        text: "󰁹"
        color: resource.shell.accent
        font.pixelSize: 22
      }
      Column {
        Layout.fillWidth: true
        Text {
          text: "Power draw"
          color: resource.shell.foreground
          font.bold: true
        }
        Text {
          text: resource.resources.report.power.label
            + " · " + resource.resources.report.power.state
          color: resource.shell.muted
          elide: Text.ElideRight
        }
      }
      Column {
        Text {
          text: resource.formatWatts(resource.resources.report.power.watts)
          color: resource.resources.report.power.watts === null
            ? resource.shell.muted : resource.shell.foreground
          font.bold: true
          horizontalAlignment: Text.AlignRight
        }
        Text {
          text: resource.resources.report.power.exact ? "Measured" : "Estimate"
          color: resource.shell.muted
          font.pixelSize: 10
          horizontalAlignment: Text.AlignRight
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 8
    Repeater {
      model: [
        {
          label: "CPU load",
          value: resource.formatPercent(resource.resources.report.system.cpuPercent)
        },
        {
          label: "Memory",
          value: resource.formatPercent(resource.resources.report.system.memory.usedPercent)
        },
        {
          label: "GPUs",
          value: resource.resources.report.system.gpus.length
        }
      ]
      Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 54
        radius: resource.shell.cornerRadius - 2
        color: resource.shell.normalFill
        border.color: resource.shell.outline
        Column {
          anchors.centerIn: parent
          spacing: 2
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.value
            color: resource.shell.foreground
            font.bold: true
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: modelData.label
            color: resource.shell.muted
            font.pixelSize: 10
          }
        }
      }
    }
  }

  Text {
    text: "GPU capacity"
    color: resource.shell.muted
    font.pixelSize: 12
    visible: resource.resources.report.system.gpus.length > 0
  }
  Repeater {
    model: resource.resources.report.system.gpus || []
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: 50
      radius: resource.shell.cornerRadius - 2
      color: resource.shell.normalFill
      border.color: resource.shell.outline
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Text {
          text: "󰢮"
          color: resource.shell.accent
          font.pixelSize: 18
        }
        Column {
          Layout.fillWidth: true
          Text {
            text: modelData.name
            color: resource.shell.foreground
            font.bold: true
          }
          Text {
            text: modelData.source
            color: resource.shell.muted
            font.pixelSize: 10
          }
        }
        Column {
          Text {
            text: resource.formatPercent(modelData.utilizationPercent)
            color: resource.shell.foreground
            horizontalAlignment: Text.AlignRight
          }
          Text {
            text: resource.formatBytes(modelData.memoryUsedBytes)
              + " / " + resource.formatBytes(modelData.memoryTotalBytes)
            color: resource.shell.muted
            font.pixelSize: 10
            horizontalAlignment: Text.AlignRight
          }
        }
      }
    }
  }
  Text {
    Layout.fillWidth: true
    visible: resource.resources.report.system.gpus.length === 0
    text: "GPU metrics are not available."
    color: resource.shell.muted
    leftPadding: 10
  }

  Text {
    text: "Top energy users"
    color: resource.shell.muted
    font.pixelSize: 12
  }
  Text {
    Layout.fillWidth: true
    visible: resource.resources.report.applications.energy.length === 0
    text: "No application data is available."
    color: resource.shell.muted
    leftPadding: 10
  }
  Repeater {
    model: resource.resources.report.applications.energy || []
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: 48
      radius: resource.shell.cornerRadius - 2
      color: resource.shell.normalFill
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Column {
          Layout.fillWidth: true
          Text {
            text: modelData.name
            color: resource.shell.foreground
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            text: resource.processSummary(modelData)
            color: resource.shell.muted
            font.pixelSize: 10
          }
        }
        Text {
          text: Number(modelData.energyScore).toFixed(1) + " score"
          color: resource.shell.accent
        }
      }
    }
  }

  Text {
    text: "Top memory users"
    color: resource.shell.muted
    font.pixelSize: 12
  }
  Text {
    Layout.fillWidth: true
    visible: resource.resources.report.applications.memory.length === 0
    text: "No application data is available."
    color: resource.shell.muted
    leftPadding: 10
  }
  Repeater {
    model: resource.resources.report.applications.memory || []
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: 48
      radius: resource.shell.cornerRadius - 2
      color: resource.shell.normalFill
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Column {
          Layout.fillWidth: true
          Text {
            text: modelData.name
            color: resource.shell.foreground
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            text: resource.processSummary(modelData)
            color: resource.shell.muted
            font.pixelSize: 10
          }
        }
        Text {
          text: resource.formatBytes(modelData.memoryBytes)
          color: resource.shell.accent
        }
      }
    }
  }

  Text {
    text: "Top hardware users"
    color: resource.shell.muted
    font.pixelSize: 12
  }
  Text {
    Layout.fillWidth: true
    visible: resource.resources.report.applications.hardware.length === 0
    text: "No application data is available."
    color: resource.shell.muted
    leftPadding: 10
  }
  Repeater {
    model: resource.resources.report.applications.hardware || []
    Rectangle {
      required property var modelData
      Layout.fillWidth: true
      implicitHeight: 48
      radius: resource.shell.cornerRadius - 2
      color: resource.shell.normalFill
      RowLayout {
        anchors.fill: parent
        anchors.margins: 9
        Column {
          Layout.fillWidth: true
          Text {
            text: modelData.name
            color: resource.shell.foreground
            font.bold: true
            elide: Text.ElideRight
          }
          Text {
            text: resource.processSummary(modelData)
            color: resource.shell.muted
            font.pixelSize: 10
          }
        }
        Text {
          text: Number(modelData.hardwareScore).toFixed(1) + " score"
          color: resource.shell.accent
        }
      }
    }
  }
}
