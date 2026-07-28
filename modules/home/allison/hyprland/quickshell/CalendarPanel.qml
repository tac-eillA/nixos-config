pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
    id: calendarRoot

    required property var shell
    property date visibleMonth: new Date()

    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData
        anchors {
            top: true
        }
        margins {
            top: calendarRoot.shell.barHeight + calendarRoot.shell.edgeGap
        }
        implicitWidth: 720
        implicitHeight: 570
        visible: calendarRoot.shell.calendarVisible
        focusable: visible
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore

        Shortcut {
            sequence: "Escape"
            enabled: calendarRoot.shell.calendarVisible
            onActivated: calendarRoot.shell.calendarVisible = false
        }

        Rectangle {
            anchors.fill: parent
            radius: calendarRoot.shell.cornerRadius
            color: "#000000"
            border.color: calendarRoot.shell.outline

            RowLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 18

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 3
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: "‹"
                            palette.button: "#111111"
                            palette.buttonText: "#ffffff"
                            onClicked: calendarRoot.visibleMonth = new Date(calendarRoot.visibleMonth.getFullYear(), calendarRoot.visibleMonth.getMonth() - 1, 1)
                        }
                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: Qt.formatDateTime(calendarRoot.visibleMonth, "MMMM yyyy")
                            color: calendarRoot.shell.foreground
                            font.bold: true
                            font.pixelSize: 17
                        }
                        Button {
                            text: "›"
                            palette.button: "#111111"
                            palette.buttonText: "#ffffff"
                            onClicked: calendarRoot.visibleMonth = new Date(calendarRoot.visibleMonth.getFullYear(), calendarRoot.visibleMonth.getMonth() + 1, 1)
                        }
                    }

                    DayOfWeekRow {
                        Layout.fillWidth: true
                        locale: Qt.locale()
                        delegate: Text {
                            required property var model
                            height: 28
                            text: model.shortName
                            color: calendarRoot.shell.muted
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                        }
                    }

                    MonthGrid {
                        id: calendarGrid
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        month: calendarRoot.visibleMonth.getMonth()
                        year: calendarRoot.visibleMonth.getFullYear()
                        locale: Qt.locale()
                        delegate: Rectangle {
                            required property var model
                            implicitWidth: 42
                            implicitHeight: 42
                            color: model.today ? calendarRoot.shell.selectedFill : "transparent"
                            radius: calendarRoot.shell.cornerRadius - 4

                            Text {
                                anchors.centerIn: parent
                                text: parent.model.day
                                color: parent.model.month === calendarGrid.month ? calendarRoot.shell.foreground : calendarRoot.shell.muted
                                font.bold: parent.model.today
                            }
                        }
                    }

                    Button {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Today"
                        palette.button: "#111111"
                        palette.buttonText: "#ffffff"
                        onClicked: calendarRoot.visibleMonth = new Date()
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: calendarRoot.shell.outline
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 2
                    spacing: 10

                    Text {
                        text: "Todo"
                        color: calendarRoot.shell.foreground
                        font.bold: true
                        font.pixelSize: 17
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: todoList.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        ScrollBar.vertical: ScrollBar {}

                        TodoList {
                            id: todoList
                            width: parent.width
                            shell: calendarRoot.shell
                        }
                    }
                }
            }
        }
    }
}
