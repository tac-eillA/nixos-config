pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Rectangle {
  id: control

  required property var shell
  property alias text: statusLabel.text
  property alias icon: statusIcon.text
  property color textColor: shell.foreground
  property int horizontalPadding: shell.touchLayout ? 10 : 6
  property int iconSize: shell.touchLayout ? 18 : 15

  signal clicked(var mouse)
  signal wheeled(var wheel)

  implicitWidth: statusContent.implicitWidth + horizontalPadding * 2
  implicitHeight: shell.touchLayout ? 36 : 28
  Layout.minimumWidth: implicitWidth
  Layout.preferredWidth: implicitWidth
  Layout.maximumWidth: implicitWidth
  Layout.minimumHeight: implicitHeight
  Layout.preferredHeight: implicitHeight
  Layout.maximumHeight: implicitHeight
  Layout.alignment: Qt.AlignVCenter
  radius: shell.cornerRadius - 3
  color: statusMouse.pressed ? shell.selectedFill
    : statusMouse.containsMouse ? shell.hoverFill : "transparent"

  Row {
    id: statusContent
    anchors.centerIn: parent
    spacing: statusLabel.visible ? 4 : 0

    Text {
      id: statusIcon
      color: control.textColor
      font.pixelSize: control.iconSize
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      id: statusLabel
      visible: text.length > 0
      color: control.textColor
      verticalAlignment: Text.AlignVCenter
    }
  }

  MouseArea {
    id: statusMouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
    onClicked: mouse => control.clicked(mouse)
    onWheel: wheel => control.wheeled(wheel)
  }

  Behavior on color {
    ColorAnimation { duration: control.shell.transitionDuration; easing.type: Easing.OutCubic }
  }
}
