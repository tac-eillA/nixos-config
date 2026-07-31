pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
  id: notifications

  required property var shell
  required property var core

  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; right: true }
    margins {
      top: notifications.shell.barHeight + notifications.shell.edgeGap
      right: notifications.shell.edgeGap
    }
    implicitWidth: notifications.shell.touchLayout ? 460 : 390
    implicitHeight: Math.min(notificationFrame.implicitHeight,
      screen.height - notifications.shell.barHeight - 20)
    visible: notifications.shell.notificationsVisible
      || notifications.core.notificationPopupVisible
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      id: notificationFrame
      width: parent.width
      height: parent.height
      implicitHeight: Math.min(notificationLayout.implicitHeight + 28, 620)
      radius: notifications.shell.cornerRadius
      color: notifications.shell.surface
      border.color: notifications.shell.outline

      ColumnLayout {
        id: notificationLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          Text {
            Layout.fillWidth: true
            text: "Notifications"
            color: notifications.shell.foreground
            font.bold: true
            font.pixelSize: 15
          }

          Rectangle {
            implicitWidth: dndLabel.implicitWidth + 16
            height: 28
            radius: notifications.shell.cornerRadius - 3
            color: notifications.core.doNotDisturb
              ? notifications.shell.selectedFill : notifications.shell.normalFill
            border.width: notifications.core.doNotDisturb ? 1 : 0
            border.color: notifications.shell.accent
            Text {
              id: dndLabel
              anchors.centerIn: parent
              text: notifications.core.doNotDisturb ? "DND on" : "DND off"
              color: notifications.core.doNotDisturb
                ? notifications.shell.accent : notifications.shell.muted
            }
            MouseArea {
              anchors.fill: parent
              onClicked: notifications.core.doNotDisturb
                = !notifications.core.doNotDisturb
            }
          }

          Rectangle {
            implicitWidth: clearLabel.implicitWidth + 16
            height: 28
            radius: notifications.shell.cornerRadius - 3
            color: clearMouse.containsMouse
              ? notifications.shell.hoverFill : notifications.shell.normalFill
            Text {
              id: clearLabel
              anchors.centerIn: parent
              text: "Clear"
              color: notifications.shell.muted
            }
            MouseArea {
              id: clearMouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: notifications.core.notificationHistory.clear()
            }
          }
        }

        Text {
          Layout.fillWidth: true
          visible: notifications.core.notificationHistory.count === 0
          text: notifications.core.doNotDisturb
            ? "Quiet mode is on. New notifications will be saved here."
            : "All caught up."
          color: notifications.shell.muted
          horizontalAlignment: Text.AlignHCenter
          wrapMode: Text.Wrap
          topPadding: 22
          bottomPadding: 22
        }

        ListView {
          Layout.fillWidth: true
          Layout.preferredHeight: Math.min(contentHeight, 540)
          model: notifications.core.notificationHistory
          clip: true
          spacing: 8

          delegate: Rectangle {
            required property int index
            required property string appName
            required property string summary
            required property string body
            required property string receivedAt
            width: ListView.view.width
            height: historyContent.implicitHeight + 22
            radius: notifications.shell.cornerRadius - 2
            color: historyMouse.containsMouse
              ? notifications.shell.hoverFill : notifications.shell.normalFill
            border.color: notifications.shell.outline

            Column {
              id: historyContent
              anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
              }
              anchors.margins: 11
              spacing: 5
              RowLayout {
                width: parent.width
                Text {
                  Layout.fillWidth: true
                  text: appName.length ? appName + " · " + summary : summary
                  color: notifications.shell.foreground
                  font.bold: true
                  wrapMode: Text.Wrap
                }
                Text {
                  text: receivedAt
                  color: notifications.shell.muted
                  font.pixelSize: 11
                }
              }
              Text {
                width: parent.width
                visible: body.length > 0
                text: body
                textFormat: Text.PlainText
                color: notifications.shell.muted
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
              }
            }

            MouseArea {
              id: historyMouse
              anchors.fill: parent
              hoverEnabled: true
              onClicked: notifications.core.notificationHistory.remove(index)
            }
          }
        }
      }
    }
  }
}
