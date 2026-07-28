pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ColumnLayout {
    id: todoRoot

    required property var shell
    spacing: 8

    function refresh() {
        if (!todoQuery.running)
            todoQuery.running = true;
    }

    function mutate(arguments) {
        todoAction.command = ["scylla-todo"].concat(arguments);
        todoAction.running = true;
    }

    ListModel {
        id: todos
    }

    Process {
        id: todoQuery
        command: ["scylla-todo", "list"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                todos.clear();
                try {
                    const entries = JSON.parse(text);
                    for (let i = 0; i < entries.length; ++i)
                        todos.append(entries[i]);
                } catch (error) {
                    console.warn("Unable to load todos:", error);
                }
            }
        }
    }

    Process {
        id: todoAction
        onExited: todoRoot.refresh()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 7

        TextField {
            id: todoInput
            Layout.fillWidth: true
            placeholderText: "Add a task"
            color: todoRoot.shell.foreground
            onAccepted: {
                const task = text.trim();
                if (!task.length)
                    return;
                todoRoot.mutate(["add", task]);
                text = "";
            }
            background: Rectangle {
                radius: todoRoot.shell.cornerRadius - 3
                color: todoRoot.shell.normalFill
                border.color: todoInput.activeFocus ? todoRoot.shell.accent : todoRoot.shell.outline
            }
        }

        Button {
            text: "Add"
            enabled: todoInput.text.trim().length > 0
            palette.button: "#111111"
            palette.buttonText: "#ffffff"
            onClicked: todoInput.accepted()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 5

        Repeater {
            model: todos

            Rectangle {
                required property string taskId
                required property string text
                required property bool done

                Layout.fillWidth: true
                implicitHeight: 42
                radius: todoRoot.shell.cornerRadius - 3
                color: todoMouse.containsMouse ? todoRoot.shell.hoverFill : todoRoot.shell.normalFill

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    CheckBox {
                        checked: done
                        onClicked: todoRoot.mutate(["toggle", taskId])
                    }

                    Text {
                        Layout.fillWidth: true
                        text: parent.parent.text
                        color: done ? todoRoot.shell.muted : todoRoot.shell.foreground
                        font.strikeout: done
                        elide: Text.ElideRight
                    }

                    Text {
                        text: ""
                        color: removeMouse.containsMouse ? todoRoot.shell.urgent : todoRoot.shell.muted
                        MouseArea {
                            id: removeMouse
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            onClicked: todoRoot.mutate(["remove", taskId])
                        }
                    }
                }

                MouseArea {
                    id: todoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            visible: todos.count === 0
            text: "Nothing pending"
            color: todoRoot.shell.muted
        }
    }
}
