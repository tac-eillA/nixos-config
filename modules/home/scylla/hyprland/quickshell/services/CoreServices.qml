pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Notifications
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
  id: services

  signal osdRequested(string icon, string label, int value, bool hasProgress)

  property alias notificationHistory: notificationHistory
  property alias wifiNetworks: wifiNetworks
  property alias wiredDevices: wiredDevices
  property alias vpnConnections: vpnConnections
  property alias idleInhibited: idleInhibitor.running
  property alias networkScanRunning: networkScan.running
  readonly property bool networkActionRunning: networkAction.running || wifiAction.running
  property alias tailscaleActionRunning: tailscaleAction.running
  property alias powerProfileQueryRunning: powerProfileQuery.running

  property bool doNotDisturb: false
  property bool notificationPopupVisible: false
  property string networkName: "offline"
  property string networkState: "disconnected"
  property string networkTransport: "offline"
  property string wifiNetworkName: "offline"
  property bool wifiEnabled: false
  property string tailscaleState: "Unknown"
  property string tailscaleHost: ""
  property string tailscaleIp: ""
  property string tailscaleTailnet: ""
  property var tailscalePeers: []
  property string activePowerProfile: ""

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

  function refreshNetwork() {
    if (!networkQuery.running) networkQuery.running = true;
    if (!vpnQuery.running) vpnQuery.running = true;
  }

  function scanNetworks() {
    if (!networkScan.running) networkScan.running = true;
  }

  function connectWifi(ssid, password) {
    const command = ["nmcli", "device", "wifi", "connect", ssid];
    if (password.length) command.push("password", password);
    runNetworkAction(command, ssid, "wifi-connect");
  }

  function setWifiEnabled(enabled) {
    if (networkActionRunning) return;
    wifiAction.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
    wifiAction.running = true;
  }

  function connectWired(interfaceName) {
    runNetworkAction(["nmcli", "device", "connect", interfaceName],
      interfaceName, "wired-connect");
  }

  function disconnectWired(interfaceName) {
    runNetworkAction(["nmcli", "device", "disconnect", interfaceName],
      interfaceName, "wired-disconnect");
  }

  function connectVpn(uuid, label) {
    runNetworkAction(["nmcli", "connection", "up", "uuid", uuid],
      label, "vpn-connect");
  }

  function disconnectVpn(uuid, label) {
    runNetworkAction(["nmcli", "connection", "down", "uuid", uuid],
      label, "vpn-disconnect");
  }

  function runNetworkAction(command, label, kind) {
    if (networkActionRunning) return;
    networkAction.actionLabel = label;
    networkAction.actionKind = kind;
    networkAction.command = command;
    networkAction.running = true;
  }

  function refreshTailscale() {
    if (!tailscaleQuery.running) tailscaleQuery.running = true;
  }

  function setTailscaleEnabled(enabled) {
    if (tailscaleAction.running) return;
    tailscaleAction.command = ["tailscale", enabled ? "up" : "down"];
    tailscaleAction.running = true;
  }

  function setExitNode(ip) {
    if (tailscaleAction.running) return;
    tailscaleAction.command = ip.length
      ? ["tailscale", "set", "--exit-node", ip]
      : ["tailscale", "set", "--exit-node="];
    tailscaleAction.running = true;
  }

  function refreshPowerProfile() {
    if (!powerProfileQuery.running) powerProfileQuery.running = true;
  }

  function setPowerProfile(profile) {
    activePowerProfile = profile;
    powerProfileAction.command = ["powerprofilesctl", "set", profile];
    powerProfileAction.running = true;
  }

  function adjustVolume(delta) {
    if (!audioSink || !audioSink.audio) return;
    audioSink.audio.volume = Math.max(0,
      Math.min(1, audioSink.audio.volume + delta / 100));
    osdRequested(audioSink.audio.muted ? "󰖁" : "",
      Math.round(audioSink.audio.volume * 100) + "%",
      Math.round(audioSink.audio.volume * 100), true);
  }

  function toggleAudioMute() {
    if (!audioSink || !audioSink.audio) return;
    audioSink.audio.muted = !audioSink.audio.muted;
    osdRequested(audioSink.audio.muted ? "󰖁" : "",
      audioSink.audio.muted ? "Muted" : volume + "%",
      volume, !audioSink.audio.muted);
  }

  function toggleMicrophoneMute() {
    if (!audioSource || !audioSource.audio) return;
    audioSource.audio.muted = !audioSource.audio.muted;
    osdRequested(audioSource.audio.muted ? "󰍭" : "",
      audioSource.audio.muted ? "Microphone muted" : "Microphone enabled",
      microphoneVolume, !audioSource.audio.muted);
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
    osdRequested(icon, player.trackTitle || player.identity || "Media", 0, false);
  }

  function brightnessStep(delta) {
    const amount = Number(delta);
    brightnessSet.command = ["brightnessctl", "-m", "set",
      amount >= 0 ? "+" + amount + "%" : Math.abs(amount) + "%-"];
    brightnessSet.running = true;
  }

  function setIdleInhibited(enabled, quiet) {
    idleInhibitor.running = enabled;
    if (quiet !== true) {
      osdRequested(enabled ? "󰅶" : "󰾪",
        enabled ? "Display stays awake" : "Display sleep enabled", 0, false);
    }
  }

  function setBluetoothDiscovery(enabled) {
    if (Bluetooth.defaultAdapter)
      Bluetooth.defaultAdapter.discovering = enabled && Bluetooth.defaultAdapter.enabled;
  }

  function setBluetoothEnabled(enabled) {
    if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = enabled;
  }

  ListModel { id: notificationHistory }
  ListModel { id: wifiNetworks }
  ListModel { id: wiredDevices }
  ListModel { id: vpnConnections }

  NotificationServer {
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
      if (!services.doNotDisturb) {
        services.notificationPopupVisible = true;
        notificationPopupTimer.restart();
      }
    }
  }

  PwObjectTracker {
    objects: Pipewire.nodes.values.filter(node => node && node.audio)
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
          const fields = services.splitNmcli(lines[i]);
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
    property string actionKind: "wifi-connect"
    onExited: (exitCode, exitStatus) => {
      const successful = exitCode === 0;
      const disconnecting = actionKind.endsWith("-disconnect");
      const vpn = actionKind.startsWith("vpn-");
      const wired = actionKind.startsWith("wired-");
      const icon = vpn ? (successful ? "󰌆" : "󰌇")
        : wired ? (successful ? "󰈀" : "󰈂")
        : (successful ? "" : "󰤭");
      let message;
      if (actionKind === "wifi-connect")
        message = successful ? "Connected to " + actionLabel
          : "Could not connect to " + actionLabel;
      else if (vpn)
        message = successful
          ? actionLabel + (disconnecting ? " disconnected" : " connected")
          : "Could not " + (disconnecting ? "disconnect " : "connect ") + actionLabel;
      else
        message = successful
          ? "Wired " + actionLabel + (disconnecting ? " disconnected" : " connected")
          : "Could not " + (disconnecting ? "disconnect " : "connect ") + actionLabel;
      services.osdRequested(icon, message, 0, false);
      services.refreshNetwork();
      if (actionKind.startsWith("wifi-")) services.scanNetworks();
    }
  }

  Process {
    id: wifiAction
    onExited: {
      services.refreshNetwork();
      services.scanNetworks();
    }
  }

  Process {
    id: networkQuery
    command: ["sh", "-lc",
      "LC_ALL=C nmcli -t -f WIFI general; LC_ALL=C nmcli --escape yes -t -f TYPE,DEVICE,STATE,CONNECTION device status"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().length ? text.trim().split("\n") : [];
        let activeWifi = null;
        let activeEthernet = null;
        services.wifiEnabled = lines.length > 0 && lines[0] === "enabled";
        services.wifiNetworkName = "offline";
        services.wiredDevices.clear();

        for (let i = 1; i < lines.length; ++i) {
          const fields = services.splitNmcli(lines[i]);
          if (fields.length < 4 || !fields[1] || fields[1] === "--") continue;
          const type = fields[0];
          const interfaceName = fields[1];
          const state = fields[2] || "unknown";
          const active = state.startsWith("connected");
          const connectionName = fields[3] && fields[3] !== "--" ? fields[3] : "";
          const device = { interfaceName, connectionName, state, active };

          if (type === "ethernet") {
            services.wiredDevices.append(device);
            if (active && !activeEthernet) activeEthernet = device;
          } else if (type === "wifi" && active && !activeWifi) {
            activeWifi = device;
            services.wifiNetworkName = connectionName || "offline";
          }
        }

        const active = activeEthernet || activeWifi;
        services.networkName = active
          ? (active.connectionName || active.interfaceName) : "offline";
        services.networkTransport = active
          ? (active === activeEthernet ? "ethernet" : "wifi") : "offline";
        services.networkState = active ? "connected" : "disconnected";
      }
    }
  }

  Process {
    id: vpnQuery
    command: ["sh", "-lc",
      "LC_ALL=C nmcli --escape yes -t -f NAME,UUID,TYPE connection show; printf '%s\\n' '__SCYLLA_ACTIVE_PROFILES__'; LC_ALL=C nmcli --escape yes -t -f UUID connection show --active"]
    stdout: StdioCollector {
      onStreamFinished: {
        const marker = "__SCYLLA_ACTIVE_PROFILES__";
        const lines = text.split("\n");
        const markerIndex = lines.indexOf(marker);
        const profileLines = markerIndex >= 0 ? lines.slice(0, markerIndex) : lines;
        const activeLines = markerIndex >= 0 ? lines.slice(markerIndex + 1) : [];
        const activeUuids = {};
        const profiles = [];

        for (let i = 0; i < activeLines.length; ++i) {
          const uuid = activeLines[i].trim();
          if (uuid.length) activeUuids[uuid] = true;
        }

        for (let i = 0; i < profileLines.length; ++i) {
          if (!profileLines[i].trim().length) continue;
          const fields = services.splitNmcli(profileLines[i]);
          if (fields.length < 3 || !fields[0] || !fields[1]) continue;
          if (fields[2] !== "vpn" && fields[2] !== "wireguard") continue;
          profiles.push({
            name: fields[0],
            uuid: fields[1],
            type: fields[2] === "wireguard" ? "WireGuard" : "VPN",
            active: activeUuids[fields[1]] === true
          });
        }

        profiles.sort((a, b) => {
          if (a.active !== b.active) return a.active ? -1 : 1;
          return a.name.localeCompare(b.name);
        });
        vpnConnections.clear();
        for (let i = 0; i < profiles.length; ++i)
          vpnConnections.append(profiles[i]);
      }
    }
  }

  Process {
    command: ["nmcli", "monitor"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        if (line.length) services.refreshNetwork();
      }
    }
  }

  Process {
    id: tailscaleQuery
    command: ["tailscale", "status", "--json"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const status = JSON.parse(text);
          services.tailscaleState = status.BackendState || "Unknown";
          services.tailscaleHost = status.Self
            ? (status.Self.HostName || status.Self.DNSName || "") : "";
          services.tailscaleIp = status.TailscaleIPs && status.TailscaleIPs.length
            ? status.TailscaleIPs[0] : "";
          services.tailscaleTailnet = status.CurrentTailnet
            ? (status.CurrentTailnet.Name || status.CurrentTailnet.MagicDNSSuffix || "") : "";
          const peers = [];
          const peerMap = status.Peer || {};
          for (const key in peerMap) {
            const peer = peerMap[key];
            if (!peer || !peer.Online) continue;
            peers.push({
              name: peer.HostName || peer.DNSName || "Unknown device",
              ip: peer.TailscaleIPs && peer.TailscaleIPs.length
                ? peer.TailscaleIPs[0] : "",
              active: peer.Active === true,
              exitNode: peer.ExitNode === true
            });
          }
          peers.sort((a, b) => {
            if (a.active !== b.active) return a.active ? -1 : 1;
            return a.name.localeCompare(b.name);
          });
          services.tailscalePeers = peers;
        } catch (error) {
          services.tailscaleState = "Unavailable";
          services.tailscaleHost = "";
          services.tailscaleIp = "";
          services.tailscaleTailnet = "";
          services.tailscalePeers = [];
        }
      }
    }
  }

  Process {
    id: tailscaleAction
    onExited: exitCode => {
      services.osdRequested(exitCode === 0 ? "󰌷" : "󰌸",
        exitCode === 0 ? "Tailscale updated" : "Tailscale action failed", 0, false);
      services.refreshTailscale();
    }
  }

  Process {
    id: brightnessSet
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(",");
        const percent = parts.length > 3 ? Number(parts[3].replace("%", "")) : 0;
        services.osdRequested("󰃠", percent + "%", percent, true);
      }
    }
  }

  Process {
    id: powerProfileQuery
    command: ["powerprofilesctl", "get"]
    stdout: StdioCollector {
      onStreamFinished: services.activePowerProfile = text.trim()
    }
  }

  Process {
    id: powerProfileAction
    onExited: services.refreshPowerProfile()
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      services.refreshNetwork();
      services.refreshTailscale();
    }
  }

  Timer {
    id: notificationPopupTimer
    interval: 5000
    onTriggered: services.notificationPopupVisible = false
  }
}
