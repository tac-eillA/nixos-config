import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    color: "#111318"

    property bool authenticating: false
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    function submit() {
        if (username.text.length === 0 || password.text.length === 0 || authenticating)
            return

        authenticating = true
        status.text = "Authenticating…"
        sddm.login(username.text, password.text, sessions.currentIndex)
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.authenticating = false
            password.text = ""
            status.text = "Login failed"
            password.forceActiveFocus()
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 64)
        spacing: 14

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(root.now, "ddd, MMM d  •  hh:mm")
            color: "#8b93a7"
            font.family: "monospace"
            font.pixelSize: 16
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 14
            text: "Welcome back"
            color: "#e6e9ef"
            font.family: "monospace"
            font.pixelSize: 28
        }

        TextField {
            id: username

            Layout.fillWidth: true
            placeholderText: "Username"
            text: userModel.lastUser
            enabled: !root.authenticating
            font.family: "monospace"
            font.pixelSize: 16
            selectByMouse: true
            KeyNavigation.tab: password
            onAccepted: password.forceActiveFocus()
        }

        TextField {
            id: password

            Layout.fillWidth: true
            placeholderText: "Password"
            echoMode: TextInput.Password
            enabled: !root.authenticating
            font.family: "monospace"
            font.pixelSize: 16
            KeyNavigation.tab: sessions
            onAccepted: root.submit()
        }

        ComboBox {
            id: sessions

            Layout.fillWidth: true
            model: sessionModel
            textRole: "name"
            currentIndex: sessionModel.lastIndex
            enabled: !root.authenticating
            font.family: "monospace"
            font.pixelSize: 15
            KeyNavigation.tab: loginButton
        }

        Button {
            id: loginButton

            Layout.fillWidth: true
            text: root.authenticating ? "Logging in…" : "Login"
            enabled: !root.authenticating
            font.family: "monospace"
            font.pixelSize: 16
            onClicked: root.submit()
        }

        Label {
            id: status

            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 4
            text: ""
            color: "#e78284"
            font.family: "monospace"
            font.pixelSize: 14
        }
    }

    Component.onCompleted: {
        if (username.text.length > 0)
            password.forceActiveFocus()
        else
            username.forceActiveFocus()
    }
}
