pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

Variants {
  id: launcher

  required property var shell
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    focusable: launcher.shell.launcherVisible
    visible: launcher.shell.launcherVisible
    color: "#99000000"

    MouseArea {
      anchors.fill: parent
      onClicked: launcher.shell.closeSurface("launcher")
    }

    Rectangle {
      anchors.centerIn: parent
      width: 520
      height: 590
      radius: launcher.shell.cornerRadius
      color: launcher.shell.surface
      border.color: launcher.shell.outline

      MouseArea { anchors.fill: parent }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        TextField {
          id: search
          Layout.fillWidth: true
          placeholderText: "Search apps and commands"
          color: launcher.shell.foreground
          focus: launcher.shell.launcherVisible
          font.pixelSize: 15
          background: Rectangle {
            radius: launcher.shell.cornerRadius - 2
            color: search.activeFocus
              ? launcher.shell.hoverFill : launcher.shell.normalFill
            border.width: search.activeFocus ? 1 : 0
            border.color: launcher.shell.accent
          }
          Keys.onPressed: event => {
            if (event.key === Qt.Key_Down) {
              applicationList.currentIndex = Math.min(applicationList.count - 1,
                applicationList.currentIndex + 1);
              event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
              applicationList.currentIndex = Math.max(0,
                applicationList.currentIndex - 1);
              event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
              launcher.shell.closeSurfaces();
              text = "";
              event.accepted = true;
            }
          }
          onAccepted: {
            const item = applicationList.currentItem;
            if (item) {
              if (item.kind === "application") item.entry.execute();
              else launcher.shell.run(item.command);
              launcher.shell.closeSurface("launcher");
              text = "";
            }
          }
        }

        ListView {
          id: applicationList
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          spacing: 5
          currentIndex: 0
          model: ScriptModel {
            values: launcher.shell.paletteCommands
              .filter(command => launcher.shell.matchesPalette(
                command.name, command.keywords, search.text))
              .map(command => ({
                kind: "command",
                name: command.name,
                icon: command.icon,
                command: command.command
              }))
              .concat(DesktopEntries.applications.values
                .filter(entry => launcher.shell.matchesPalette(entry.name,
                  entry.comment || entry.genericName || "", search.text))
                .sort((a, b) => a.name.localeCompare(b.name))
                .slice(0, 45)
                .map(entry => ({
                  kind: "application",
                  name: entry.name,
                  icon: entry.icon,
                  entry: entry
                })))
          }

          delegate: Rectangle {
            required property int index
            required property var modelData
            property string kind: modelData.kind
            property string itemName: modelData.name
            property string itemIcon: modelData.icon || ""
            property var entry: modelData.entry || null
            property string command: modelData.command || ""
            width: applicationList.width
            height: launcher.shell.touchLayout ? 60 : 50
            radius: launcher.shell.cornerRadius - 2
            color: ListView.isCurrentItem || entryMouse.containsMouse
              ? launcher.shell.selectedFill : launcher.shell.normalFill
            border.width: ListView.isCurrentItem ? 1 : 0
            border.color: launcher.shell.accent

            RowLayout {
              anchors.fill: parent
              anchors.margins: 9
              spacing: 12
              IconImage {
                visible: kind === "application"
                implicitSize: 30
                source: kind === "application"
                  ? Quickshell.iconPath(itemIcon, "application-x-executable") : ""
              }
              Text {
                visible: kind === "command"
                Layout.preferredWidth: 30
                horizontalAlignment: Text.AlignHCenter
                text: itemIcon
                color: launcher.shell.accent
                font.pixelSize: 19
              }
              Text {
                Layout.fillWidth: true
                text: itemName
                color: launcher.shell.foreground
                elide: Text.ElideRight
              }
              Text {
                text: kind === "command" ? "Command" : "Application"
                color: launcher.shell.muted
                font.pixelSize: 11
              }
            }

            MouseArea {
              id: entryMouse
              anchors.fill: parent
              hoverEnabled: true
              onEntered: applicationList.currentIndex = index
              onClicked: {
                if (kind === "application") entry.execute();
                else launcher.shell.run(command);
                launcher.shell.closeSurface("launcher");
                search.text = "";
              }
            }
          }
        }
      }
    }
  }
}
