pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Wayland
import Quickshell.Widgets

Variants {
  id: notifications

  required property var shell
  required property var core

  model: Quickshell.screens

  function urgencyColor(urgency) {
    if (urgency === NotificationUrgency.Critical)
      return notifications.shell.urgent;
    if (urgency === NotificationUrgency.Low)
      return notifications.shell.muted;
    return notifications.shell.outline;
  }

  function urgencyLabel(urgency) {
    return urgency === NotificationUrgency.Normal
      ? "" : NotificationUrgency.toString(urgency);
  }

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
              onClicked: notifications.core.clearNotifications()
            }
          }
        }

        Text {
          Layout.fillWidth: true
          visible: notifications.core.notificationCount === 0
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
            required property Notification modelData
            readonly property string appIconSource: modelData.appIcon.length
              ? Quickshell.iconPath(modelData.appIcon, true) : ""
            readonly property string urgencyText:
              notifications.urgencyLabel(modelData.urgency)
            width: ListView.view.width
            height: historyContent.implicitHeight + 22
            radius: notifications.shell.cornerRadius - 2
            color: historyMouse.containsMouse
              ? notifications.shell.hoverFill : notifications.shell.normalFill
            border.color: notifications.urgencyColor(modelData.urgency)
            border.width: modelData.urgency === NotificationUrgency.Critical ? 2 : 1

            MouseArea {
              id: historyMouse
              anchors.fill: parent
              z: 0
              hoverEnabled: true
              onClicked: notifications.core.dismissNotification(modelData)
            }

            Rectangle {
              width: 3
              anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
              }
              z: 1
              radius: 2
              color: notifications.urgencyColor(modelData.urgency)
            }

            Column {
              id: historyContent
              anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
              }
              anchors.margins: 11
              spacing: 5
              z: 1

              RowLayout {
                width: parent.width

                Item {
                  Layout.preferredWidth: 30
                  Layout.preferredHeight: 30

                  IconImage {
                    anchors.fill: parent
                    visible: appIconSource.length > 0
                    source: appIconSource
                    asynchronous: true
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: appIconSource.length === 0
                    text: "󰂚"
                    color: notifications.shell.accent
                    font.pixelSize: 23
                  }
                }

                Text {
                  Layout.fillWidth: true
                  text: modelData.appName.length
                    ? modelData.appName
                      + (modelData.summary.length ? " · " + modelData.summary : "")
                    : modelData.summary
                  color: notifications.shell.foreground
                  font.bold: true
                  wrapMode: Text.Wrap
                }

                Text {
                  visible: urgencyText.length > 0
                  text: urgencyText
                  color: notifications.urgencyColor(modelData.urgency)
                  font.bold: true
                  font.pixelSize: 11
                }

                Text {
                  text: notifications.core.notificationReceivedAt(modelData.id)
                  color: notifications.shell.muted
                  font.pixelSize: 11
                }
              }

              Image {
                width: parent.width
                height: visible ? Math.min(140, implicitHeight) : 0
                visible: modelData.image.length > 0
                source: modelData.image
                asynchronous: true
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width
                sourceSize.height: 140
              }

              Text {
                width: parent.width
                visible: modelData.body.length > 0
                text: modelData.body
                textFormat: Text.PlainText
                color: notifications.shell.muted
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
              }

              Flow {
                id: actionRow
                width: parent.width
                visible: modelData.actions.length > 0
                height: visible ? implicitHeight : 0
                spacing: 6
                z: 2

                Repeater {
                  model: modelData.actions

                  delegate: Rectangle {
                    required property NotificationAction actionData
                    implicitWidth: actionLabel.implicitWidth + 20
                    height: 28
                    radius: notifications.shell.cornerRadius - 3
                    color: actionMouse.containsMouse
                      ? notifications.shell.hoverFill : notifications.shell.normalFill
                    border.color: notifications.shell.outline

                    Text {
                      id: actionLabel
                      anchors.centerIn: parent
                      text: actionData.text.length
                        ? actionData.text : actionData.identifier
                      color: notifications.shell.foreground
                    }

                    MouseArea {
                      id: actionMouse
                      anchors.fill: parent
                      z: 3
                      hoverEnabled: true
                      onClicked: actionData.invoke()
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
