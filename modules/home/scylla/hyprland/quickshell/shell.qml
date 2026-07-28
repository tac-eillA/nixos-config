//@ pragma ShellId scylla
//@ pragma IconTheme Adwaita

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets

ShellRoot {
  id: root

  // Quattro-inspired semantic palette and interaction tokens. The palette
  // remains compatible with the existing Macchiato desktop theme.
  property color background: "#000000"
  property color surface: "#000000"
  property color elevated: "#0a0a0a"
  property color foreground: "#ffffff"
  property color muted: "#a6a6a6"
  property color accent: "#8aadf4"
  property color urgent: "#ed8796"
  property color normalFill: "#0ac6d0f5"
  property color hoverFill: "#14c6d0f5"
  property color selectedFill: "#2ec6d0f5"
  property color outline: "#66494d64"
  property int cornerRadius: 10
  property int edgeGap: 5
  property int barHeight: 39
  property int transitionDuration: 420

  property bool launcherVisible: false
  property bool powerVisible: false
  property bool wallpaperPickerVisible: false
  property bool calendarVisible: false
  property bool fingerprintVisible: false
  property bool helpVisible: false
  property bool quickSettingsVisible: false
  property string quickSettingsSection: "network"
  property bool notificationsVisible: false
  property bool doNotDisturb: false
  property bool notificationPopupVisible: false
  property string networkName: "offline"
  property string networkState: "disconnected"
  property bool wifiEnabled: false
  property string pendingWifiSsid: ""
  property string pendingWifiSecurity: ""
  property string activePowerProfile: ""
  property bool clockAlternate: false
  property bool idleInhibited: idleInhibitor.running
  property bool osdVisible: false
  property string osdIcon: ""
  property string osdLabel: ""
  property int osdValue: 0
  property bool osdHasProgress: true
  property string wallpaper: "file://" +
    (Quickshell.env("XDG_STATE_HOME")
      || (Quickshell.env("HOME") + "/.local/state")) +
    "/scylla-theme/wallpaper"

  function applyGeneratedTheme(data) {
    try {
      const theme = JSON.parse(data);
      accent = theme.accent || accent;
      urgent = theme.urgent || urgent;
      outline = theme.outline || outline;
    } catch (error) {
      console.warn("Unable to load generated desktop theme:", error);
    }
  }

  function reloadGeneratedTheme() {
    if (!generatedTheme.running) generatedTheme.running = true;
  }

  Process {
    id: generatedTheme
    command: ["sh", "-lc",
      "state=\"${XDG_STATE_HOME:-$HOME/.local/state}/scylla-theme\"; " +
      "[ -r \"$state/theme.json\" ] && cat \"$state/theme.json\" || true"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: if (text.trim().length) root.applyGeneratedTheme(text)
    }
  }

  readonly property var audioSink: Pipewire.defaultAudioSink
  readonly property var audioSource: Pipewire.defaultAudioSource
  readonly property int volume: audioSink && audioSink.audio
    ? Math.round(audioSink.audio.volume * 100) : 0
  readonly property bool mutedAudio: audioSink && audioSink.audio
    ? audioSink.audio.muted : false
  readonly property int microphoneVolume: audioSource && audioSource.audio
    ? Math.round(audioSource.audio.volume * 100) : 0
  readonly property bool mutedMicrophone: audioSource && audioSource.audio
    ? audioSource.audio.muted : false
  readonly property int batteryPercent: UPower.displayDevice.ready
    ? Math.round(UPower.displayDevice.percentage * 100) : 0
  readonly property int bluetoothConnectedCount: Bluetooth.devices.values
    .filter(device => device && device.connected).length
  readonly property var mediaPlayers: Mpris.players ? Mpris.players.values : []
  readonly property var activePlayer: {
    for (let i = 0; i < mediaPlayers.length; ++i)
      if (mediaPlayers[i] && mediaPlayers[i].isPlaying) return mediaPlayers[i];
    for (let i = 0; i < mediaPlayers.length; ++i)
      if (mediaPlayers[i] && (mediaPlayers[i].trackTitle || mediaPlayers[i].identity))
        return mediaPlayers[i];
    return null;
  }
  readonly property string mediaLabel: activePlayer
    ? (activePlayer.trackTitle || activePlayer.identity || "") : ""

  component StatusItem: Rectangle {
    property alias text: statusLabel.text
    property alias icon: statusIcon.text
    property color textColor: root.foreground
    property int horizontalPadding: 6
    property int iconSize: 15
    signal clicked(var mouse)
    signal wheeled(var wheel)

    implicitWidth: statusContent.implicitWidth + horizontalPadding * 2
    implicitHeight: 28
    Layout.minimumWidth: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.maximumWidth: implicitWidth
    Layout.minimumHeight: implicitHeight
    Layout.preferredHeight: implicitHeight
    Layout.maximumHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter
    radius: root.cornerRadius - 3
    color: statusMouse.pressed ? root.selectedFill
      : statusMouse.containsMouse ? root.hoverFill : "transparent"

    Row {
      id: statusContent
      anchors.centerIn: parent
      spacing: statusLabel.visible ? 4 : 0

      Text {
        id: statusIcon
        color: parent.parent.textColor
        font.pixelSize: parent.parent.iconSize
        verticalAlignment: Text.AlignVCenter
      }

      Text {
        id: statusLabel
        visible: text.length > 0
        color: parent.parent.textColor
        verticalAlignment: Text.AlignVCenter
      }
    }

    MouseArea {
      id: statusMouse
      anchors.fill: parent
      hoverEnabled: true
      acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
      onClicked: mouse => parent.clicked(mouse)
      onWheel: wheel => parent.wheeled(wheel)
    }

    Behavior on color {
      ColorAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
    }
  }

  property var paletteCommands: [
    { name: "Lock session", icon: "", command: "loginctl lock-session", keywords: "secure screen" },
    { name: "Suspend", icon: "󰤄", command: "systemctl suspend", keywords: "sleep" },
    { name: "Log out", icon: "󰍃", command: "uwsm stop", keywords: "exit session" },
    { name: "Reboot", icon: "󰜉", command: "systemctl reboot", keywords: "restart" },
    { name: "Power off", icon: "", command: "systemctl poweroff", keywords: "shutdown" }
  ]

  function run(command) {
    Quickshell.execDetached(["sh", "-lc", command]);
  }

  function matchesPalette(label, keywords, query) {
    const needle = query.trim().toLowerCase();
    if (!needle.length) return true;
    const haystack = (label + " " + (keywords || "")).toLowerCase();
    if (haystack.includes(needle)) return true;
    const acronym = label.split(/\s+/).map(word => word[0] || "").join("").toLowerCase();
    return acronym.includes(needle);
  }

  function closeSurfaces() {
    launcherVisible = false;
    powerVisible = false;
    wallpaperPickerVisible = false;
    calendarVisible = false;
    fingerprintVisible = false;
    helpVisible = false;
    quickSettingsVisible = false;
    notificationsVisible = false;
    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering)
      Bluetooth.defaultAdapter.discovering = false;
  }

  function toggleQuickSettings(section) {
    const changingSection = quickSettingsSection !== section;
    quickSettingsSection = section;
    quickSettingsVisible = changingSection || !quickSettingsVisible;
    if ((!quickSettingsVisible || section !== "bluetooth")
        && Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering)
      Bluetooth.defaultAdapter.discovering = false;
    if (quickSettingsVisible && section === "battery" && !powerProfileQuery.running)
      powerProfileQuery.running = true;
    if (quickSettingsVisible && section === "network" && !networkScan.running)
      networkScan.running = true;
    if (quickSettingsVisible && section === "bluetooth"
        && Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
      Bluetooth.defaultAdapter.discovering = true;
    launcherVisible = false;
    powerVisible = false;
    notificationsVisible = false;
    wallpaperPickerVisible = false;
    calendarVisible = false;
    fingerprintVisible = false;
    helpVisible = false;
  }

  function showOsd(icon, label, value, hasProgress) {
    osdIcon = icon;
    osdLabel = label;
    osdValue = Math.max(0, Math.min(100, value));
    osdHasProgress = hasProgress;
    osdVisible = true;
    osdTimer.restart();
  }

  function adjustVolume(delta) {
    if (!audioSink || !audioSink.audio) return;
    audioSink.audio.volume = Math.max(0, Math.min(1, audioSink.audio.volume + delta / 100));
    showOsd(audioSink.audio.muted ? "󰖁" : "",
      Math.round(audioSink.audio.volume * 100) + "%",
      Math.round(audioSink.audio.volume * 100), true);
  }

  function toggleAudioMute() {
    if (!audioSink || !audioSink.audio) return;
    audioSink.audio.muted = !audioSink.audio.muted;
    showOsd(audioSink.audio.muted ? "󰖁" : "",
      audioSink.audio.muted ? "Muted" : volume + "%",
      volume, !audioSink.audio.muted);
  }

  function toggleMicrophoneMute() {
    if (!audioSource || !audioSource.audio) return;
    audioSource.audio.muted = !audioSource.audio.muted;
    showOsd(audioSource.audio.muted ? "󰍭" : "",
      audioSource.audio.muted ? "Microphone muted" : "Microphone enabled",
      microphoneVolume, !audioSource.audio.muted);
  }

  function splitNmcli(line) {
    const fields = [];
    let field = "";
    let escaped = false;
    for (let i = 0; i < line.length; ++i) {
      const character = line[i];
      if (escaped) {
        field += character;
        escaped = false;
      } else if (character === "\\") {
        escaped = true;
      } else if (character === ":") {
        fields.push(field);
        field = "";
      } else {
        field += character;
      }
    }
    fields.push(field);
    return fields;
  }

  function connectWifi(ssid, security, password) {
    const command = ["nmcli", "device", "wifi", "connect", ssid];
    if (password.length) command.push("password", password);
    networkAction.actionLabel = ssid;
    networkAction.command = command;
    networkAction.running = true;
  }

  function mediaAction(action) {
    const player = activePlayer;
    if (!player) return;
    if (action === "next" && player.canGoNext) player.next();
    else if (action === "previous" && player.canGoPrevious) player.previous();
    else if (action === "playPause") {
      if (player.isPlaying && player.canPause) player.pause();
      else if (!player.isPlaying && player.canPlay) player.play();
      else if (player.canTogglePlaying) player.togglePlaying();
    }
    const icon = action === "next" ? "󰒭" : action === "previous" ? "󰒮"
      : (player.isPlaying ? "" : "");
    showOsd(icon, player.trackTitle || player.identity || "Media", 0, false);
  }

  Process {
    id: idleInhibitor
    command: [
      "systemd-inhibit",
      "--what=idle",
      "--who=Scylla Quickshell",
      "--why=Keep display awake",
      "sleep",
      "infinity"
    ]
  }

  IpcHandler {
    target: "shell"
    function toggleLauncher(): void {
      root.launcherVisible = !root.launcherVisible;
      root.powerVisible = false;
      root.quickSettingsVisible = false;
    }
    function togglePower(): void {
      root.powerVisible = !root.powerVisible;
      root.launcherVisible = false;
      root.quickSettingsVisible = false;
      root.wallpaperPickerVisible = false;
    }
    function toggleWallpaperPicker(): void {
      wallpaperPanel.toggle();
    }
    function toggleNotifications(): void {
      root.notificationsVisible = !root.notificationsVisible;
    }
    function volumeStep(delta: string): string {
      root.adjustVolume(Number(delta));
      return "ok";
    }
    function toggleMute(): string {
      root.toggleAudioMute();
      return "ok";
    }
    function brightnessStep(delta: string): string {
      const amount = Number(delta);
      brightnessSet.command = ["brightnessctl", "-m", "set",
        amount >= 0 ? "+" + amount + "%" : Math.abs(amount) + "%-"];
      brightnessSet.running = true;
      return "ok";
    }
    function media(action: string): string {
      root.mediaAction(action);
      return "ok";
    }
  }

  ListModel { id: notificationHistory }
  ListModel { id: wifiNetworks }

  NotificationServer {
    id: notificationServer
    bodySupported: true
    bodyMarkupSupported: false
    imageSupported: true
    actionsSupported: true
    persistenceSupported: true
    keepOnReload: true
    onNotification: notification => {
      notification.tracked = true;
      notificationHistory.insert(0, {
        appName: notification.appName || "",
        summary: notification.summary || "",
        body: notification.body || "",
        receivedAt: Qt.formatDateTime(new Date(), "HH:mm")
      });
      if (notificationHistory.count > 50)
        notificationHistory.remove(notificationHistory.count - 1);
      if (!root.doNotDisturb) {
        root.notificationPopupVisible = true;
        notificationPopupTimer.restart();
      }
    }
  }

  PwObjectTracker {
    objects: Pipewire.nodes.values.filter(node => node && node.audio)
  }

  Process {
    id: networkScan
    command: ["sh", "-lc",
      "LC_ALL=C nmcli -t --escape yes -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan yes"]
    stdout: StdioCollector {
      onStreamFinished: {
        wifiNetworks.clear();
        const seen = {};
        const lines = text.trim().length ? text.trim().split("\n") : [];
        for (let i = 0; i < lines.length; ++i) {
          const fields = root.splitNmcli(lines[i]);
          if (fields.length < 4 || !fields[1] || seen[fields[1]]) continue;
          seen[fields[1]] = true;
          wifiNetworks.append({
            active: fields[0] === "*",
            ssid: fields[1],
            signal: Number(fields[2]),
            security: fields.slice(3).join(":")
          });
        }
      }
    }
  }

  Process {
    id: networkAction
    property string actionLabel: ""
    onExited: (exitCode, exitStatus) => {
      if (exitCode === 0)
        root.showOsd("", "Connected to " + actionLabel, 0, false);
      else
        root.showOsd("󰤭", "Could not connect to " + actionLabel, 0, false);
      if (!networkQuery.running) networkQuery.running = true;
      if (!networkScan.running) networkScan.running = true;
    }
  }

  Process {
    id: networkQuery
    command: ["sh", "-lc",
      "LC_ALL=C nmcli -t -f WIFI general; LC_ALL=C nmcli --escape yes -t -f TYPE,STATE,CONNECTION device status"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        root.wifiEnabled = lines[0] === "enabled";
        const wifi = lines.find(line => line.startsWith("wifi:connected:"));
        const wired = lines.find(line => line.startsWith("ethernet:connected:"));
        const active = wifi || wired;
        root.networkName = active
          ? active.split(":").slice(2).join(":").replace(/\\:/g, ":") : "offline";
        root.networkState = active ? "connected" : "disconnected";
      }
    }
  }

  Process {
    id: networkMonitor
    command: ["nmcli", "monitor"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        if (line.length && !networkQuery.running) networkQuery.running = true;
      }
    }
  }

  Process {
    id: brightnessSet
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(",");
        const percent = parts.length > 3 ? Number(parts[3].replace("%", "")) : 0;
        root.showOsd("󰃠", percent + "%", percent, true);
      }
    }
  }

  Process {
    id: powerProfileQuery
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector {
      onStreamFinished: root.activePowerProfile = text.trim()
    }
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!networkQuery.running) networkQuery.running = true
  }

  Timer {
    id: osdTimer
    interval: 1200
    onTriggered: root.osdVisible = false
  }

  Timer {
    id: notificationPopupTimer
    interval: 5000
    onTriggered: root.notificationPopupVisible = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; left: true; right: true }
      implicitHeight: root.barHeight
      exclusiveZone: root.barHeight
      color: root.background

      Item {
        anchors.fill: parent

        Row {
          id: leftBar
          anchors.left: parent.left
          anchors.leftMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Repeater {
            model: 5

            Rectangle {
              required property int index
              property var workspace: {
                const wanted = index + 1;
                for (let i = 0; i < Hyprland.workspaces.values.length; ++i) {
                  if (Hyprland.workspaces.values[i].id === wanted)
                    return Hyprland.workspaces.values[i];
                }
                return null;
              }
              width: workspace && workspace.focused ? 30 : 24
              height: 26
              radius: root.cornerRadius - 4
              color: workspace && workspace.focused ? root.selectedFill
                : workspaceMouse.containsMouse ? root.hoverFill : "transparent"
              border.width: workspace && workspace.focused ? 1 : 0
              border.color: root.accent

              Text {
                anchors.centerIn: parent
                text: parent.index + 1
                color: parent.workspace && parent.workspace.focused ? root.accent : root.foreground
                font.bold: parent.workspace && parent.workspace.focused
              }

              MouseArea {
                id: workspaceMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
              }

              Behavior on width {
                NumberAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
              }
              Behavior on color {
                ColorAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
              }
            }
          }

          Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 360)
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
            color: root.muted
            elide: Text.ElideRight
          }
        }

        SystemClock {
          id: clock
          precision: SystemClock.Minutes
        }

        Rectangle {
          id: clockButton
          anchors.centerIn: parent
          implicitWidth: clockText.implicitWidth + 20
          height: 28
          radius: root.cornerRadius - 3
          color: clockMouse.containsMouse ? root.hoverFill : "transparent"

          Text {
            id: clockText
            anchors.centerIn: parent
            text: root.clockAlternate
              ? Qt.formatDateTime(clock.date, "yyyy-MM-dd  'W'ww")
              : Qt.formatDateTime(clock.date, "ddd MMM dd  HH:mm")
            color: root.foreground
            font.bold: true
          }

          MouseArea {
            id: clockMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton)
                root.clockAlternate = !root.clockAlternate;
              else {
                root.calendarVisible = !root.calendarVisible;
                root.launcherVisible = false;
                root.powerVisible = false;
                root.quickSettingsVisible = false;
                root.notificationsVisible = false;
                root.fingerprintVisible = false;
                root.helpVisible = false;
              }
            }
          }

          Behavior on color {
            ColorAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
          }
        }

        StatusItem {
          anchors.right: clockButton.left
          anchors.rightMargin: 4
          anchors.verticalCenter: parent.verticalCenter
          icon: "󰈷"
          text: ""
          iconSize: 19
          textColor: root.fingerprintVisible ? root.accent : root.foreground
          onClicked: {
            if (root.fingerprintVisible)
              fingerprintPanel.close();
            else
              fingerprintPanel.open();
          }
        }

        Row {
          id: rightBar
          anchors.right: parent.right
          anchors.rightMargin: 6
          anchors.verticalCenter: parent.verticalCenter
          spacing: 2

          Rectangle {
            visible: root.activePlayer !== null
            width: visible ? Math.min(mediaText.implicitWidth + 38, 280) : 0
            height: 28
            radius: root.cornerRadius - 3
            color: mediaMouse.containsMouse ? root.hoverFill : root.normalFill

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 6
              spacing: 6

              Text {
                text: root.activePlayer && root.activePlayer.isPlaying ? "" : ""
                color: root.accent
              }
              Text {
                id: mediaText
                Layout.fillWidth: true
                text: root.mediaLabel
                color: root.foreground
                elide: Text.ElideRight
              }
            }

            MouseArea {
              id: mediaMouse
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.LeftButton | Qt.MiddleButton
              onClicked: mouse => root.mediaAction(mouse.button === Qt.MiddleButton
                ? "next" : "playPause")
            }

            Behavior on color {
              ColorAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
            }
          }

          StatusItem {
            icon: root.networkName === "offline" ? "󰤭" : ""
            text: root.networkName === "offline" ? "" : root.networkName
            textColor: root.networkName === "offline" ? root.muted : root.foreground
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton)
                root.run("nmcli radio wifi " + (root.wifiEnabled ? "off" : "on"));
              else
                root.toggleQuickSettings("network");
            }
          }

          StatusItem {
            visible: Bluetooth.defaultAdapter !== null
            icon: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled ? "" : "󰂲"
            text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
              && root.bluetoothConnectedCount > 0 ? root.bluetoothConnectedCount : ""
            textColor: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
              ? root.foreground
              : root.muted
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton && Bluetooth.defaultAdapter)
                Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
              else
                root.toggleQuickSettings("bluetooth");
            }
          }

          StatusItem {
            icon: root.mutedAudio ? "󰖁" : ""
            text: root.volume + "%"
            textColor: root.mutedAudio ? root.muted : root.foreground
            onClicked: mouse => {
              if (mouse.button === Qt.MiddleButton)
                root.toggleAudioMute();
              else
                root.toggleQuickSettings("audio");
            }
            onWheeled: wheel => root.adjustVolume(wheel.angleDelta.y > 0 ? 3 : -3)
          }

          StatusItem {
            visible: UPower.displayDevice.ready && UPower.displayDevice.isPresent
            icon: "󰁹"
            text: root.batteryPercent + "%"
            textColor: root.batteryPercent < 16 ? root.urgent : root.foreground
            onClicked: mouse => root.toggleQuickSettings("battery")
          }

          StatusItem {
            icon: root.idleInhibited ? "󰅶" : "󰾪"
            textColor: root.idleInhibited ? root.accent : root.muted
            onClicked: mouse => {
              idleInhibitor.running = !idleInhibitor.running;
              root.showOsd(
                idleInhibitor.running ? "󰅶" : "󰾪",
                idleInhibitor.running ? "Display stays awake" : "Display sleep enabled",
                0,
                false
              );
            }
          }

          StatusItem {
            icon: root.doNotDisturb ? "󰂛" : "󰂚"
            text: root.doNotDisturb ? "" : notificationHistory.count
            textColor: root.doNotDisturb ? root.muted : root.foreground
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton)
                root.doNotDisturb = !root.doNotDisturb;
              else
                root.notificationsVisible = !root.notificationsVisible;
            }
          }

          StatusItem {
            icon: "?"
            textColor: root.helpVisible ? root.accent : root.foreground
            onClicked: {
              const opening = !root.helpVisible;
              root.closeSurfaces();
              root.helpVisible = opening;
            }
          }

          StatusItem {
            icon: ""
            onClicked: mouse => {
              root.powerVisible = !root.powerVisible;
              root.launcherVisible = false;
              root.quickSettingsVisible = false;
            }
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; right: true }
      margins { top: root.barHeight + root.edgeGap; right: root.edgeGap }
      implicitWidth: 390
      implicitHeight: Math.min(
        root.quickSettingsSection === "network" ? 570
          : root.quickSettingsSection === "bluetooth" ? 520
          : root.quickSettingsSection === "audio"
            ? quickSettingsLayout.implicitHeight + 28 : 190,
        screen.height - root.barHeight - root.edgeGap * 3)
      visible: root.quickSettingsVisible
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        id: quickSettingsFrame
        width: parent.width
        height: parent.height
        implicitHeight: quickSettingsLayout.implicitHeight + 28
        radius: root.cornerRadius
        color: "#000000"
        border.color: root.outline
        clip: true

        Flickable {
          id: quickSettingsScroller
          anchors.fill: parent
          anchors.margins: 14
          contentWidth: width
          contentHeight: quickSettingsLayout.implicitHeight
          boundsBehavior: Flickable.StopAtBounds
          clip: true
          ScrollBar.vertical: ScrollBar {}

          ColumnLayout {
            id: quickSettingsLayout
            width: quickSettingsScroller.width
            spacing: 10

            RowLayout {
              Layout.fillWidth: true

              Text {
                Layout.fillWidth: true
                text: root.quickSettingsSection === "network" ? "Wi-Fi"
                  : root.quickSettingsSection === "bluetooth" ? "Bluetooth"
                  : root.quickSettingsSection === "audio" ? "Audio"
                  : "Power"
                color: root.foreground
                font.bold: true
                font.pixelSize: 15
              }

              Text {
                text: "×"
                color: quickSettingsClose.containsMouse ? root.foreground : root.muted
                font.pixelSize: 20

                MouseArea {
                  id: quickSettingsClose
                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  onClicked: {
                    root.quickSettingsVisible = false;
                    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering)
                      Bluetooth.defaultAdapter.discovering = false;
                  }
                }
              }
            }

          Rectangle {
            Layout.fillWidth: true
            visible: root.quickSettingsSection === "network"
            implicitHeight: 58
            radius: root.cornerRadius - 2
            color: root.quickSettingsSection === "network"
              ? root.selectedFill : root.normalFill
            border.width: root.quickSettingsSection === "network" ? 1 : 0
            border.color: root.accent

            RowLayout {
              anchors.fill: parent
              anchors.margins: 11
              spacing: 11
              Text {
                text: root.wifiEnabled ? "" : "󰤭"
                color: root.wifiEnabled ? root.accent : root.muted
                font.pixelSize: 20
              }
              Column {
                Layout.fillWidth: true
                spacing: 2
                Text {
                  text: "Wi-Fi"
                  color: root.foreground
                  font.bold: true
                }
                Text {
                  text: root.wifiEnabled
                    ? (root.networkName === "offline" ? "Not connected" : root.networkName)
                    : "Disabled"
                  color: root.muted
                }
              }
              Switch {
                checked: root.wifiEnabled
                onToggled: root.run("nmcli radio wifi " + (checked ? "on" : "off"))
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            visible: root.quickSettingsSection === "network" && root.wifiEnabled
            spacing: 6

            RowLayout {
              Layout.fillWidth: true
              Text {
                Layout.fillWidth: true
                text: "Available networks"
                color: root.muted
                font.pixelSize: 12
              }
              Text {
                text: networkScan.running ? "Scanning…" : "󰑐"
                color: scanMouse.containsMouse ? root.accent : root.muted
                MouseArea {
                  id: scanMouse
                  anchors.fill: parent
                  anchors.margins: -6
                  hoverEnabled: true
                  enabled: !networkScan.running
                  onClicked: networkScan.running = true
                }
              }
            }

            Repeater {
              model: ScriptModel {
                values: wifiNetworks.count > 0
                  ? Array.from({ length: Math.min(7, wifiNetworks.count) },
                    (_, index) => wifiNetworks.get(index))
                  : []
              }

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 48
                radius: root.cornerRadius - 3
                color: modelData.active ? root.selectedFill
                  : wifiMouse.containsMouse ? root.hoverFill : root.normalFill
                border.width: modelData.active ? 1 : 0
                border.color: root.accent

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 9
                  spacing: 9
                  Text {
                    text: modelData.signal > 70 ? "󰤨"
                      : modelData.signal > 45 ? "󰤥"
                      : modelData.signal > 20 ? "󰤢" : "󰤟"
                    color: modelData.active ? root.accent : root.foreground
                    font.pixelSize: 18
                  }
                  Column {
                    Layout.fillWidth: true
                    Text {
                      width: parent.width
                      text: modelData.ssid
                      color: root.foreground
                      font.bold: modelData.active
                      elide: Text.ElideRight
                    }
                    Text {
                      text: modelData.active ? "Connected"
                        : (modelData.security.length ? modelData.security : "Open network")
                      color: root.muted
                      font.pixelSize: 11
                    }
                  }
                  Text {
                    text: modelData.security.length ? "" : ""
                    color: root.muted
                  }
                }

                MouseArea {
                  id: wifiMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: !modelData.active && !networkAction.running
                  onClicked: {
                    if (modelData.security.length) {
                      root.pendingWifiSsid = modelData.ssid;
                      root.pendingWifiSecurity = modelData.security;
                      wifiPassword.text = "";
                      wifiPassword.forceActiveFocus();
                    } else {
                      root.connectWifi(modelData.ssid, "", "");
                    }
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              visible: root.pendingWifiSsid.length > 0
              spacing: 7

              TextField {
                id: wifiPassword
                Layout.fillWidth: true
                placeholderText: "Password for " + root.pendingWifiSsid
                echoMode: TextInput.Password
                color: root.foreground
                onAccepted: wifiConnectButton.clicked()
                background: Rectangle {
                  radius: root.cornerRadius - 3
                  color: root.normalFill
                  border.color: wifiPassword.activeFocus ? root.accent : root.outline
                }
              }

              Button {
                id: wifiConnectButton
                text: "Connect"
                enabled: wifiPassword.text.length > 0 && !networkAction.running
                onClicked: {
                  root.connectWifi(root.pendingWifiSsid,
                    root.pendingWifiSecurity, wifiPassword.text);
                  root.pendingWifiSsid = "";
                  wifiPassword.text = "";
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: root.quickSettingsSection === "bluetooth"
            implicitHeight: bluetoothContent.implicitHeight + 22
            radius: root.cornerRadius - 2
            color: root.quickSettingsSection === "bluetooth"
              ? root.selectedFill : root.normalFill
            border.width: root.quickSettingsSection === "bluetooth" ? 1 : 0
            border.color: root.accent

            ColumnLayout {
              id: bluetoothContent
              anchors { left: parent.left; right: parent.right; top: parent.top }
              anchors.margins: 11
              spacing: 7

              RowLayout {
                Layout.fillWidth: true
                Text {
                  text: ""
                  color: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                    ? root.accent : root.muted
                  font.pixelSize: 20
                }
                Column {
                  Layout.fillWidth: true
                  spacing: 2
                  Text { text: "Bluetooth"; color: root.foreground; font.bold: true }
                  Text {
                    text: root.bluetoothConnectedCount > 0
                      ? root.bluetoothConnectedCount + " connected"
                      : (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                        ? "No devices connected" : "Disabled")
                    color: root.muted
                  }
                }
                Switch {
                  enabled: Bluetooth.defaultAdapter !== null
                  checked: Bluetooth.defaultAdapter
                    ? Bluetooth.defaultAdapter.enabled : false
                  onToggled: if (Bluetooth.defaultAdapter)
                    Bluetooth.defaultAdapter.enabled = checked
                }
              }

              RowLayout {
                Layout.fillWidth: true
                visible: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled
                Text {
                  Layout.fillWidth: true
                  text: "Devices"
                  color: root.muted
                  font.pixelSize: 12
                }
                Text {
                  text: Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering
                    ? "Scanning…" : "󰑐"
                  color: root.muted
                  MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: Bluetooth.defaultAdapter
                      && !Bluetooth.defaultAdapter.discovering
                    onClicked: Bluetooth.defaultAdapter.discovering = true
                  }
                }
              }

              Repeater {
                model: ScriptModel {
                  values: Bluetooth.devices.values
                    .filter(device => device && (device.name || device.deviceName))
                    .sort((a, b) => {
                      if (a.connected !== b.connected) return a.connected ? -1 : 1;
                      if (a.paired !== b.paired) return a.paired ? -1 : 1;
                      return (a.name || a.deviceName).localeCompare(b.name || b.deviceName);
                    })
                    .slice(0, 7)
                }

                Rectangle {
                  required property var modelData
                  Layout.fillWidth: true
                  implicitHeight: 48
                  radius: root.cornerRadius - 3
                  color: modelData.connected ? root.selectedFill
                    : bluetoothMouse.containsMouse ? root.hoverFill : root.normalFill
                  border.width: modelData.connected ? 1 : 0
                  border.color: root.accent

                  RowLayout {
                    anchors.fill: parent
                    anchors.margins: 9
                    spacing: 9
                    Text {
                      Layout.preferredWidth: 22
                      horizontalAlignment: Text.AlignHCenter
                      text: ""
                      color: modelData.connected ? root.accent : root.muted
                      font.pixelSize: 18
                    }
                    Column {
                      Layout.fillWidth: true
                      Text {
                        width: parent.width
                        text: modelData.name || modelData.deviceName
                        color: root.foreground
                        font.bold: modelData.connected
                        elide: Text.ElideRight
                      }
                      Text {
                        text: modelData.pairing ? "Pairing…"
                          : modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                          : modelData.connected ? "Connected"
                          : modelData.paired ? "Paired" : "Available"
                        color: root.muted
                        font.pixelSize: 11
                      }
                    }
                    Text {
                      text: modelData.batteryAvailable
                        ? Math.round(modelData.battery * 100) + "%" : ""
                      color: root.muted
                    }
                  }

                  MouseArea {
                    id: bluetoothMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                      if (modelData.connected) modelData.disconnect();
                      else if (modelData.paired) modelData.connect();
                      else modelData.pair();
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            visible: root.quickSettingsSection === "audio"
            implicitHeight: 70
            radius: root.cornerRadius - 2
            color: root.quickSettingsSection === "audio"
              ? root.selectedFill : root.normalFill
            border.width: root.quickSettingsSection === "audio" ? 1 : 0
            border.color: root.accent

            RowLayout {
              anchors.fill: parent
              anchors.margins: 11
              spacing: 10
              Text {
                text: root.mutedAudio ? "󰖁" : ""
                color: root.mutedAudio ? root.muted : root.accent
                font.pixelSize: 20
                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -7
                  onClicked: root.toggleAudioMute()
                }
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                RowLayout {
                  Layout.fillWidth: true
                  Text { Layout.fillWidth: true; text: "Volume"; color: root.foreground; font.bold: true }
                  Text { text: root.volume + "%"; color: root.muted }
                }
                Slider {
                  Layout.fillWidth: true
                  from: 0
                  to: 100
                  value: root.volume
                  onMoved: {
                    if (root.audioSink && root.audioSink.audio)
                      root.audioSink.audio.volume = value / 100;
                  }
                }
              }
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            visible: root.quickSettingsSection === "audio"
            spacing: 6

            Text {
              text: "Output device"
              color: root.muted
              font.pixelSize: 12
            }

            Repeater {
              model: ScriptModel {
                values: Pipewire.nodes.values
                  .filter(node => node && node.ready && node.audio
                    && node.isSink && !node.isStream)
                  .sort((a, b) => a.description.localeCompare(b.description))
              }

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 42
                radius: root.cornerRadius - 3
                color: modelData === root.audioSink ? root.selectedFill
                  : outputMouse.containsMouse ? root.hoverFill : root.normalFill
                border.width: modelData === root.audioSink ? 1 : 0
                border.color: root.accent

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 9
                  Text {
                    text: "󰓃"
                    color: modelData === root.audioSink ? root.accent : root.muted
                  }
                  Text {
                    Layout.fillWidth: true
                    text: modelData.description || modelData.nickname || modelData.name
                    color: root.foreground
                    elide: Text.ElideRight
                  }
                  Text {
                    text: modelData === root.audioSink ? "Default" : ""
                    color: root.muted
                    font.pixelSize: 11
                  }
                }

                MouseArea {
                  id: outputMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10
              visible: root.audioSource !== null

              Text {
                text: root.mutedMicrophone ? "󰍭" : ""
                color: root.mutedMicrophone ? root.muted : root.accent
                font.pixelSize: 18
                MouseArea {
                  anchors.fill: parent
                  anchors.margins: -6
                  onClicked: root.toggleMicrophoneMute()
                }
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                RowLayout {
                  Layout.fillWidth: true
                  Text {
                    Layout.fillWidth: true
                    text: "Microphone"
                    color: root.foreground
                    font.bold: true
                  }
                  Text { text: root.microphoneVolume + "%"; color: root.muted }
                }
                Slider {
                  Layout.fillWidth: true
                  from: 0
                  to: 100
                  value: root.microphoneVolume
                  onMoved: if (root.audioSource && root.audioSource.audio)
                    root.audioSource.audio.volume = value / 100
                }
              }
            }

            Text {
              text: "Input device"
              color: root.muted
              font.pixelSize: 12
              visible: Pipewire.nodes.values.some(node => node && node.ready
                && node.audio && !node.isSink && !node.isStream)
            }

            Repeater {
              model: ScriptModel {
                values: Pipewire.nodes.values
                  .filter(node => node && node.ready && node.audio
                    && !node.isSink && !node.isStream)
                  .sort((a, b) => a.description.localeCompare(b.description))
              }

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 42
                radius: root.cornerRadius - 3
                color: modelData === root.audioSource ? root.selectedFill
                  : inputMouse.containsMouse ? root.hoverFill : root.normalFill
                border.width: modelData === root.audioSource ? 1 : 0
                border.color: root.accent

                RowLayout {
                  anchors.fill: parent
                  anchors.margins: 9
                  Text {
                    text: ""
                    color: modelData === root.audioSource ? root.accent : root.muted
                  }
                  Text {
                    Layout.fillWidth: true
                    text: modelData.description || modelData.nickname || modelData.name
                    color: root.foreground
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: inputMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
              }
            }

            Text {
              text: "Media"
              color: root.muted
              font.pixelSize: 12
              visible: root.mediaPlayers.length > 0
            }

            Repeater {
              model: ScriptModel {
                values: root.mediaPlayers
                  .filter(player => player
                    && (player.trackTitle || player.identity))
                  .slice(0, 3)
              }

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: mediaCard.implicitHeight + 18
                radius: root.cornerRadius - 3
                color: root.normalFill
                border.width: modelData.isPlaying ? 1 : 0
                border.color: root.accent

                RowLayout {
                  id: mediaCard
                  anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                  }
                  anchors.margins: 9
                  spacing: 10

                  Rectangle {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    radius: 6
                    color: root.selectedFill
                    clip: true

                    Image {
                      id: mediaArtwork
                      anchors.fill: parent
                      source: modelData.trackArtUrl
                      fillMode: Image.PreserveAspectCrop
                      asynchronous: true
                      visible: status === Image.Ready
                    }
                    Text {
                      anchors.centerIn: parent
                      text: "󰎆"
                      color: root.accent
                      font.pixelSize: 20
                      visible: mediaArtwork.status !== Image.Ready
                    }
                  }

                  ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                      Layout.fillWidth: true
                      text: modelData.trackTitle || modelData.identity
                      color: root.foreground
                      font.bold: true
                      elide: Text.ElideRight
                    }
                    Text {
                      Layout.fillWidth: true
                      text: modelData.trackArtist || modelData.identity
                      color: root.muted
                      elide: Text.ElideRight
                      font.pixelSize: 11
                    }
                  }

                  StatusItem {
                    icon: "󰒮"
                    text: ""
                    enabled: modelData.canGoPrevious
                    onClicked: if (modelData.canGoPrevious) modelData.previous()
                  }
                  StatusItem {
                    icon: modelData.isPlaying ? "" : ""
                    text: ""
                    enabled: modelData.canTogglePlaying
                      || modelData.canPlay || modelData.canPause
                    onClicked: {
                      if (modelData.isPlaying && modelData.canPause) modelData.pause();
                      else if (!modelData.isPlaying && modelData.canPlay) modelData.play();
                      else if (modelData.canTogglePlaying) modelData.togglePlaying();
                    }
                  }
                  StatusItem {
                    icon: "󰒭"
                    text: ""
                    enabled: modelData.canGoNext
                    onClicked: if (modelData.canGoNext) modelData.next()
                  }
                }
              }
            }
          }

          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 58
            visible: root.quickSettingsSection === "battery"
              && UPower.displayDevice.ready && UPower.displayDevice.isPresent
            radius: root.cornerRadius - 2
            color: root.quickSettingsSection === "battery"
              ? root.selectedFill : root.normalFill
            border.width: root.quickSettingsSection === "battery" ? 1 : 0
            border.color: root.accent

            RowLayout {
              anchors.fill: parent
              anchors.margins: 11
              spacing: 11
              Text {
                text: "󰁹"
                color: root.batteryPercent < 16 ? root.urgent : root.accent
                font.pixelSize: 20
              }
              Column {
                Layout.fillWidth: true
                spacing: 2
                Text { text: "Battery"; color: root.foreground; font.bold: true }
                Text {
                  text: root.batteryPercent + "%"
                    + (UPower.displayDevice.state === UPowerDeviceState.Charging
                      ? " · charging" : "")
                  color: root.muted
                }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            visible: root.quickSettingsSection === "battery"
              && UPower.displayDevice.ready && UPower.displayDevice.isPresent
            spacing: 7

            Repeater {
              model: [
                { name: "power-saver", label: "Saver", icon: "󰌪" },
                { name: "balanced", label: "Balanced", icon: "󰾅" },
                { name: "performance", label: "Performance", icon: "󰓅" }
              ]

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: 42
                radius: root.cornerRadius - 3
                color: root.activePowerProfile === modelData.name
                  ? root.selectedFill
                  : profileMouse.containsMouse ? root.hoverFill : root.normalFill
                border.width: root.activePowerProfile === modelData.name ? 1 : 0
                border.color: root.accent

                Row {
                  anchors.centerIn: parent
                  spacing: 6
                  Text {
                    text: modelData.icon
                    color: root.activePowerProfile === modelData.name
                      ? root.accent : root.muted
                  }
                  Text {
                    text: modelData.label
                    color: root.foreground
                  }
                }

                MouseArea {
                  id: profileMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: {
                    root.activePowerProfile = parent.modelData.name;
                    root.run("powerprofilesctl set " + parent.modelData.name);
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

  CalendarPanel {
    shell: root
  }

  FingerprintPanel {
    id: fingerprintPanel
    shell: root
  }

  HelpPanel {
    shell: root
  }

  WallpaperPanel {
    id: wallpaperPanel
    shell: root
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; right: true }
      margins { top: root.barHeight + root.edgeGap; right: root.edgeGap }
      implicitWidth: 390
      implicitHeight: Math.min(notificationFrame.implicitHeight, screen.height - root.barHeight - 20)
      visible: root.notificationsVisible || root.notificationPopupVisible
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Overlay
      exclusionMode: ExclusionMode.Ignore

      Rectangle {
        id: notificationFrame
        width: parent.width
        height: parent.height
        implicitHeight: Math.min(notificationLayout.implicitHeight + 28, 620)
        radius: root.cornerRadius
        color: root.surface
        border.color: root.outline

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
              color: root.foreground
              font.bold: true
              font.pixelSize: 15
            }

            Rectangle {
              implicitWidth: dndLabel.implicitWidth + 16
              height: 28
              radius: root.cornerRadius - 3
              color: root.doNotDisturb ? root.selectedFill : root.normalFill
              border.width: root.doNotDisturb ? 1 : 0
              border.color: root.accent

              Text {
                id: dndLabel
                anchors.centerIn: parent
                text: root.doNotDisturb ? "DND on" : "DND off"
                color: root.doNotDisturb ? root.accent : root.muted
              }
              MouseArea {
                anchors.fill: parent
                onClicked: root.doNotDisturb = !root.doNotDisturb
              }
            }

            Rectangle {
              implicitWidth: clearLabel.implicitWidth + 16
              height: 28
              radius: root.cornerRadius - 3
              color: clearMouse.containsMouse ? root.hoverFill : root.normalFill

              Text {
                id: clearLabel
                anchors.centerIn: parent
                text: "Clear"
                color: root.muted
              }
              MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: notificationHistory.clear()
              }
            }
          }

          Text {
            Layout.fillWidth: true
            visible: notificationHistory.count === 0
            text: root.doNotDisturb
              ? "Quiet mode is on. New notifications will be saved here."
              : "All caught up."
            color: root.muted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            topPadding: 22
            bottomPadding: 22
          }

          ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 540)
            model: notificationHistory
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
              radius: root.cornerRadius - 2
              color: historyMouse.containsMouse ? root.hoverFill : root.normalFill
              border.color: root.outline

              Column {
                id: historyContent
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                anchors.margins: 11
                spacing: 5

                RowLayout {
                  width: parent.width
                  Text {
                    Layout.fillWidth: true
                    text: appName.length ? appName + " · " + summary : summary
                    color: root.foreground
                    font.bold: true
                    wrapMode: Text.Wrap
                  }
                  Text {
                    text: receivedAt
                    color: root.muted
                    font.pixelSize: 11
                  }
                }
                Text {
                  width: parent.width
                  visible: body.length > 0
                  text: body
                  textFormat: Text.PlainText
                  color: root.muted
                  wrapMode: Text.Wrap
                  maximumLineCount: 4
                  elide: Text.ElideRight
                }
              }

              MouseArea {
                id: historyMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: notificationHistory.remove(index)
              }

              Behavior on color {
                ColorAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
              }
            }
          }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; left: true; right: true }
      visible: root.osdVisible
      color: "transparent"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 68
        implicitWidth: osdRow.implicitWidth + 36
        implicitHeight: 68
        radius: root.cornerRadius
        color: root.elevated
        border.color: root.outline
        opacity: root.osdVisible ? 1 : 0

        RowLayout {
          id: osdRow
          anchors.centerIn: parent
          spacing: 16

          Text {
            text: root.osdIcon
            color: root.foreground
            font.pixelSize: 26
          }

          Rectangle {
            visible: root.osdHasProgress
            Layout.preferredWidth: 150
            Layout.preferredHeight: 7
            radius: 4
            color: root.selectedFill

            Rectangle {
              width: parent.width * root.osdValue / 100
              height: parent.height
              radius: parent.radius
              color: root.accent

              Behavior on width {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
              }
            }
          }

          Text {
            Layout.maximumWidth: 330
            text: root.osdLabel
            color: root.foreground
            font.bold: true
            elide: Text.ElideRight
          }
        }

        Behavior on opacity {
          NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }
      }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; left: true; right: true }
      focusable: root.launcherVisible || root.powerVisible
      visible: root.launcherVisible || root.powerVisible
      color: "#99000000"

      MouseArea {
        anchors.fill: parent
        onClicked: {
          root.launcherVisible = false;
          root.powerVisible = false;
        }
      }

      Rectangle {
        anchors.centerIn: parent
        width: root.launcherVisible ? 520 : 430
        height: root.launcherVisible ? 590 : 170
        radius: root.cornerRadius
        color: root.surface
        border.color: root.outline

        MouseArea { anchors.fill: parent }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 18
          spacing: 12

          TextField {
            id: search
            Layout.fillWidth: true
            visible: root.launcherVisible
            placeholderText: "Search apps and commands"
            color: root.foreground
            focus: root.launcherVisible
            font.pixelSize: 15
            background: Rectangle {
              radius: root.cornerRadius - 2
              color: search.activeFocus ? root.hoverFill : root.normalFill
              border.width: search.activeFocus ? 1 : 0
              border.color: root.accent
            }
            Keys.onPressed: event => {
              if (event.key === Qt.Key_Down) {
                applicationList.currentIndex = Math.min(
                  applicationList.count - 1, applicationList.currentIndex + 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Up) {
                applicationList.currentIndex = Math.max(0, applicationList.currentIndex - 1);
                event.accepted = true;
              } else if (event.key === Qt.Key_Escape) {
                root.closeSurfaces();
                text = "";
                event.accepted = true;
              }
            }
            onAccepted: {
              const item = applicationList.currentItem;
              if (item) {
                if (item.kind === "application") item.entry.execute();
                else root.run(item.command);
                root.launcherVisible = false;
                text = "";
              }
            }
          }

          ListView {
            id: applicationList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.launcherVisible
            clip: true
            spacing: 5
            currentIndex: 0
            model: ScriptModel {
              values: root.paletteCommands
                .filter(command => root.matchesPalette(
                  command.name, command.keywords, search.text))
                .map(command => ({
                  kind: "command",
                  name: command.name,
                  icon: command.icon,
                  command: command.command
                }))
                .concat(DesktopEntries.applications.values
                .filter(entry => root.matchesPalette(
                  entry.name, entry.comment || entry.genericName || "", search.text))
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
              height: 50
              radius: root.cornerRadius - 2
              color: ListView.isCurrentItem || entryMouse.containsMouse
                ? root.selectedFill : root.normalFill
              border.width: ListView.isCurrentItem ? 1 : 0
              border.color: root.accent

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
                  color: root.accent
                  font.pixelSize: 19
                }
                Text {
                  Layout.fillWidth: true
                  text: itemName
                  color: root.foreground
                  elide: Text.ElideRight
                }
                Text {
                  text: kind === "command" ? "Command" : "Application"
                  color: root.muted
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
                  else root.run(command);
                  root.launcherVisible = false;
                  search.text = "";
                }
              }

              Behavior on color {
                ColorAnimation { duration: root.transitionDuration; easing.type: Easing.OutCubic }
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.powerVisible
            spacing: 10

            Repeater {
              model: [
                { label: "Lock", icon: "", command: "loginctl lock-session" },
                { label: "Suspend", icon: "󰤄", command: "systemctl suspend" },
                { label: "Logout", icon: "󰍃", command: "uwsm stop" },
                { label: "Reboot", icon: "󰜉", command: "systemctl reboot" },
                { label: "Power off", icon: "", command: "systemctl poweroff" }
              ]

              Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: root.cornerRadius - 2
                color: powerMouse.containsMouse ? root.selectedFill : root.normalFill
                border.width: powerMouse.containsMouse ? 1 : 0
                border.color: root.accent

                Column {
                  anchors.centerIn: parent
                  spacing: 6
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.icon
                    color: powerMouse.containsMouse ? root.accent : root.foreground
                    font.pixelSize: 24
                  }
                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label
                    color: powerMouse.containsMouse ? root.foreground : root.muted
                  }
                }

                MouseArea {
                  id: powerMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  onClicked: root.run(modelData.command)
                }
              }
            }
          }
        }
      }
    }
  }

  Variants {
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
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }
  }
}
