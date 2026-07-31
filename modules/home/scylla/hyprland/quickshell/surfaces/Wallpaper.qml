pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Variants {
  id: wallpaper

  required property var shell
  model: Quickshell.screens

  PanelWindow {
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    aboveWindows: false
    exclusiveZone: -1
    color: "#000000"

    Image {
      anchors.fill: parent
      source: wallpaper.shell.wallpaper
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }
  }
}
