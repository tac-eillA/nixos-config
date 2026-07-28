pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
  id: fingerprintRoot

  required property var shell
  property string state: "checking"
  property string detail: "Checking for a fingerprint reader…"
  property string enrolled: ""
  property string selectedFinger: "right-index-finger"
  property bool confirmDelete: false

  function refresh() {
    if (!listPrints.running) {
      state = "checking";
      detail = "Checking for a fingerprint reader…";
      listPrints.running = true;
    }
  }

  function open() {
    shell.closeSurfaces();
    shell.fingerprintVisible = true;
    confirmDelete = false;
    refresh();
  }

  function close() {
    if (enrollPrint.running) enrollPrint.running = false;
    shell.fingerprintVisible = false;
    confirmDelete = false;
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true }
      margins { top: fingerprintRoot.shell.barHeight + fingerprintRoot.shell.edgeGap }
      implicitWidth: 520
      implicitHeight: 520
      visible: fingerprintRoot.shell.fingerprintVisible
      focusable: visible
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      Shortcut {
        sequence: "Escape"
        enabled: fingerprintRoot.shell.fingerprintVisible
        onActivated: fingerprintRoot.close()
      }

      Rectangle {
        anchors.fill: parent
        radius: fingerprintRoot.shell.cornerRadius
        color: fingerprintRoot.shell.surface
        border.color: fingerprintRoot.shell.outline

        ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
          Layout.fillWidth: true
          Text {
            Layout.fillWidth: true
            text: "Fingerprint authentication"
            color: fingerprintRoot.shell.foreground
            font.bold: true
            font.pixelSize: 18
          }
          Button {
            text: "×"
            flat: true
            onClicked: fingerprintRoot.close()
          }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 82
          radius: fingerprintRoot.shell.cornerRadius - 2
          color: fingerprintRoot.shell.normalFill
          border.color: fingerprintRoot.shell.outline

          RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 14
            Text {
              text: fingerprintRoot.state === "missing" ? "󰈷"
                : fingerprintRoot.state === "enrolling" ? "󰈸"
                : fingerprintRoot.state === "error" ? "" : "󰈷"
              color: fingerprintRoot.state === "error"
                || fingerprintRoot.state === "missing"
                ? fingerprintRoot.shell.urgent : fingerprintRoot.shell.accent
              font.pixelSize: 30
            }
            ColumnLayout {
              Layout.fillWidth: true
              Text {
                text: fingerprintRoot.state === "ready" ? "Reader ready"
                  : fingerprintRoot.state === "enrolling" ? "Enrollment in progress"
                  : fingerprintRoot.state === "missing" ? "No reader detected"
                  : fingerprintRoot.state === "error" ? "Fingerprint service error"
                  : "Checking hardware"
                color: fingerprintRoot.shell.foreground
                font.bold: true
              }
              Text {
                Layout.fillWidth: true
                text: fingerprintRoot.detail
                color: fingerprintRoot.shell.muted
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
              }
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 7
          Text {
            text: "Enrolled fingerprints"
            color: fingerprintRoot.shell.foreground
            font.bold: true
          }
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 76
            radius: fingerprintRoot.shell.cornerRadius - 2
            color: fingerprintRoot.shell.normalFill
            Text {
              anchors.fill: parent
              anchors.margins: 12
              text: fingerprintRoot.enrolled.length
                ? fingerprintRoot.enrolled
                : "No fingerprints are enrolled yet."
              color: fingerprintRoot.enrolled.length
                ? fingerprintRoot.shell.foreground : fingerprintRoot.shell.muted
              wrapMode: Text.Wrap
              verticalAlignment: Text.AlignVCenter
            }
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 7
          Text {
            text: "Add a fingerprint"
            color: fingerprintRoot.shell.foreground
            font.bold: true
          }
          ComboBox {
            Layout.fillWidth: true
            enabled: fingerprintRoot.state !== "missing" && !enrollPrint.running
            textRole: "label"
            valueRole: "value"
            model: [
              { label: "Right index finger", value: "right-index-finger" },
              { label: "Right thumb", value: "right-thumb" },
              { label: "Right middle finger", value: "right-middle-finger" },
              { label: "Left index finger", value: "left-index-finger" },
              { label: "Left thumb", value: "left-thumb" },
              { label: "Left middle finger", value: "left-middle-finger" }
            ]
            onActivated: fingerprintRoot.selectedFinger = currentValue
          }
          Text {
            Layout.fillWidth: true
            visible: enrollPrint.running
            text: "Touch and lift the selected finger repeatedly. Slightly change its angle each time."
            color: fingerprintRoot.shell.accent
            wrapMode: Text.Wrap
          }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
          Layout.fillWidth: true
          Button {
            text: listPrints.running ? "Refreshing…" : "Refresh"
            enabled: !listPrints.running && !enrollPrint.running
            onClicked: fingerprintRoot.refresh()
          }
          Item { Layout.fillWidth: true }
          Button {
            visible: fingerprintRoot.enrolled.length > 0
            text: fingerprintRoot.confirmDelete ? "Confirm delete all" : "Delete all"
            enabled: !enrollPrint.running && !deletePrints.running
            onClicked: {
              if (!fingerprintRoot.confirmDelete) {
                fingerprintRoot.confirmDelete = true;
              } else {
                fingerprintRoot.confirmDelete = false;
                deletePrints.running = true;
              }
            }
          }
          Button {
            text: enrollPrint.running ? "Cancel" : "Enroll"
            enabled: fingerprintRoot.state !== "missing"
              && fingerprintRoot.state !== "checking"
              && !deletePrints.running
            onClicked: {
              if (enrollPrint.running) {
                enrollPrint.running = false;
                fingerprintRoot.detail = "Enrollment cancelled.";
                fingerprintRoot.state = "ready";
              } else {
                fingerprintRoot.confirmDelete = false;
                enrollPrint.command = ["fprintd-enroll", "-f",
                  fingerprintRoot.selectedFinger];
                fingerprintRoot.state = "enrolling";
                fingerprintRoot.detail = "Waiting for the first scan…";
                enrollPrint.running = true;
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: "Fingerprints are stored by the device service for your current user. Keep your password available as a fallback."
          color: fingerprintRoot.shell.muted
          font.pixelSize: 11
          wrapMode: Text.Wrap
        }
        }
      }
    }
  }

  Process {
    id: listPrints
    command: ["fprintd-list", Quickshell.env("USER")]
    stdout: StdioCollector {
      onStreamFinished: {
        const matches = text.split("\n")
          .map(line => line.match(/\d+:\s+(.+)$/))
          .filter(match => match)
          .map(match => match[1].trim().replace(/-/g, " "));
        fingerprintRoot.enrolled = matches.join(" · ");
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.includes("No devices available")) {
          fingerprintRoot.state = "missing";
          fingerprintRoot.detail = "Connect a supported fingerprint reader, then refresh.";
        } else if (text.trim().length && !text.includes("No fingerprints")) {
          fingerprintRoot.state = "error";
          fingerprintRoot.detail = text.trim();
        }
      }
    }
    onExited: (exitCode, exitStatus) => {
      if (fingerprintRoot.state === "checking") {
        fingerprintRoot.state = "ready";
        fingerprintRoot.detail = fingerprintRoot.enrolled.length
          ? "Your saved fingerprints are ready to use."
          : "The reader is available. Enroll a finger to get started.";
      }
    }
  }

  Process {
    id: enrollPrint
    stdout: SplitParser {
      onRead: line => {
        if (line.includes("enroll-stage-passed"))
          fingerprintRoot.detail = "Scan accepted. Touch the reader again.";
        else if (line.includes("enroll-retry-scan"))
          fingerprintRoot.detail = "That scan was not clear. Please try again.";
        else if (line.includes("enroll-completed"))
          fingerprintRoot.detail = "Fingerprint enrolled successfully.";
        else if (line.trim().length)
          fingerprintRoot.detail = line.trim();
      }
    }
    stderr: SplitParser {
      onRead: line => {
        if (line.includes("Not Authorized"))
          fingerprintRoot.detail = "Authorization was denied. Enter your password in the system authorization prompt and try again.";
        else if (line.trim().length)
          fingerprintRoot.detail = line.trim();
      }
    }
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        fingerprintRoot.state = "ready";
        fingerprintRoot.detail = "Fingerprint enrolled successfully.";
        fingerprintRoot.refresh();
      } else {
        fingerprintRoot.state = "error";
        if (!fingerprintRoot.detail.length
            || fingerprintRoot.detail === "Waiting for the first scan…")
          fingerprintRoot.detail = "Enrollment did not complete. Check the system authorization prompt and try again.";
      }
    }
  }

  Process {
    id: deletePrints
    command: ["fprintd-delete", Quickshell.env("USER")]
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0) {
        fingerprintRoot.detail = "All enrolled fingerprints were removed.";
        fingerprintRoot.state = "ready";
        fingerprintRoot.refresh();
      } else {
        fingerprintRoot.detail = "Could not remove the enrolled fingerprints. Check the system authorization prompt and try again.";
        fingerprintRoot.state = "error";
      }
    }
  }
}
