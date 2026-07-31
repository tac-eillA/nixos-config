import QtQuick

QtObject {
  id: state

  property bool visible: false
  property string icon: ""
  property string label: ""
  property int value: 0
  property bool hasProgress: true
  property Timer hideTimer: Timer {
    interval: 1200
    onTriggered: state.visible = false
  }

  function show(iconValue, labelValue, progressValue, progressVisible) {
    icon = iconValue;
    label = labelValue;
    value = Math.max(0, Math.min(100, progressValue));
    hasProgress = progressVisible;
    visible = true;
    hideTimer.restart();
  }
}
