pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: wallpaperRoot

    required property var shell
    property string repositoryWallpapers: "@REPOSITORY_WALLPAPERS@"

    function toggle() {
        shell.wallpaperPickerVisible = !shell.wallpaperPickerVisible;
        shell.launcherVisible = false;
        shell.powerVisible = false;
        shell.quickSettingsVisible = false;
        shell.notificationsVisible = false;
        shell.calendarVisible = false;
        if (shell.wallpaperPickerVisible && !wallpaperScan.running)
            wallpaperScan.running = true;
    }

    ListModel {
        id: wallpaperChoices
    }

    Process {
        id: wallpaperScan
        command: ["sh", "-lc", "user_dir=\"${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers\"; " + "mkdir -p \"$user_dir\"; " + "find '" + wallpaperRoot.repositoryWallpapers + "' \"$user_dir\" -maxdepth 1 -type f " + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " + "-print | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperChoices.clear();
                const paths = text.trim().length ? text.trim().split("\n") : [];
                for (let i = 0; i < paths.length; ++i) {
                    const path = paths[i];
                    const filename = path.substring(path.lastIndexOf("/") + 1);
                    wallpaperChoices.append({
                        path: path,
                        label: filename.replace(/\.[^.]+$/, "").replace(/[-_]/g, " ")
                    });
                }
            }
        }
    }

    Process {
        id: wallpaperApply
        property string selectedPath: ""
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                wallpaperRoot.shell.showOsd("", "Unable to apply wallpaper", 0, false);
            } else {
                wallpaperRoot.shell.wallpaper = "file://" + selectedPath + "?changed=" + Date.now();
                wallpaperRoot.shell.reloadGeneratedTheme();
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            focusable: wallpaperRoot.shell.wallpaperPickerVisible
            visible: wallpaperRoot.shell.wallpaperPickerVisible
            color: "#b3000000"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore

            Shortcut {
                sequence: "Escape"
                enabled: wallpaperRoot.shell.wallpaperPickerVisible
                onActivated: wallpaperRoot.shell.wallpaperPickerVisible = false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: wallpaperRoot.shell.wallpaperPickerVisible = false
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 980)
                height: Math.min(parent.height - 80, 700)
                radius: wallpaperRoot.shell.cornerRadius + 2
                color: "#000000"
                border.color: wallpaperRoot.shell.outline

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true

                        Column {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                text: "Choose wallpaper"
                                color: wallpaperRoot.shell.foreground
                                font.pixelSize: 20
                                font.bold: true
                            }

                            Text {
                                text: "The desktop palette will be generated from your selection"
                                color: wallpaperRoot.shell.muted
                            }

                            Text {
                                text: "Sources: ~/nixos-config/img/wallpaper and ~/Pictures/Wallpapers"
                                color: wallpaperRoot.shell.muted
                                font.pixelSize: 11
                            }
                        }

                        Button {
                            text: ""
                            flat: true
                            onClicked: wallpaperRoot.shell.wallpaperPickerVisible = false
                        }
                    }

                    GridView {
                        id: wallpaperGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        cellWidth: width / Math.max(1, Math.min(3, wallpaperChoices.count))
                        cellHeight: 210
                        model: wallpaperChoices

                        delegate: Item {
                            required property string path
                            required property string label
                            width: wallpaperGrid.cellWidth
                            height: wallpaperGrid.cellHeight

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 7
                                radius: wallpaperRoot.shell.cornerRadius
                                color: wallpaperMouse.containsMouse ? wallpaperRoot.shell.selectedFill : wallpaperRoot.shell.normalFill
                                border.width: wallpaperMouse.containsMouse ? 2 : 1
                                border.color: wallpaperMouse.containsMouse ? wallpaperRoot.shell.accent : wallpaperRoot.shell.outline
                                clip: true

                                Image {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        bottom: wallpaperLabel.top
                                    }
                                    anchors.margins: 7
                                    source: "file://" + path
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                }

                                Text {
                                    id: wallpaperLabel
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                    }
                                    height: 38
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: label
                                    color: wallpaperRoot.shell.foreground
                                    elide: Text.ElideRight
                                    leftPadding: 8
                                    rightPadding: 8
                                }

                                MouseArea {
                                    id: wallpaperMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        wallpaperRoot.shell.wallpaperPickerVisible = false;
                                        wallpaperApply.selectedPath = path;
                                        wallpaperApply.command = ["scylla-theme", path];
                                        wallpaperApply.running = true;
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: wallpaperRoot.shell.transitionDuration
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {}
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        visible: !wallpaperScan.running && wallpaperChoices.count === 0
                        text: "No wallpapers found"
                        color: wallpaperRoot.shell.muted
                    }
                }
            }
        }
    }
}
