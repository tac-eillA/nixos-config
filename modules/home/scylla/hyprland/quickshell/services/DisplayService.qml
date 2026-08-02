pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Scope {
  id: service

  required property string internalDisplay

  signal osdRequested(string icon, string label, int value, bool hasProgress)

  property var monitors: []
  property var brightnessEntries: []
  property var profiles: ({})
  property string currentProfile: ""
  property bool confirmationPending: false
  property string error: ""
  property bool busy: displayQuery.running || displayAction.running
    || brightnessQuery.running || brightnessAction.running
  property var queuedAction: null
  property var pendingBrightness: null

  readonly property var enabledMonitors: monitors.filter(monitor => monitor.enabled)
  readonly property bool internalDisplayPresent: internalDisplay.length > 0
    && monitors.some(monitor => monitor.name === internalDisplay)
  readonly property bool externalMonitorConnected: internalDisplayPresent
    && enabledMonitors.some(monitor => monitor.name !== internalDisplay)
  readonly property var profileNames: Object.keys(profiles).sort()

  function refresh() {
    if (!displayQuery.running) displayQuery.running = true;
  }

  function fallbackBrightness(monitor) {
    return {
      name: monitor.name,
      supported: false,
      value: 0,
      maximum: 100,
      backend: "none",
      identifier: monitor.description || monitor.name,
      reason: "Brightness control unavailable"
    };
  }

  function decorateMonitors(values) {
    const entries = {};
    for (let i = 0; i < brightnessEntries.length; ++i) {
      const entry = brightnessEntries[i];
      if (entry && entry.name) entries[entry.name] = entry;
    }
    return (values || []).map(monitor => Object.assign({}, monitor, {
      brightness: entries[monitor.name] || fallbackBrightness(monitor)
    }));
  }

  function mergeBrightness(values) {
    brightnessEntries = values || [];
    service.monitors = service.decorateMonitors(service.monitors);
  }

  function refreshBrightness() {
    if (!brightnessQuery.running && !brightnessAction.running)
      brightnessQuery.running = true;
  }

  function setBrightness(output, value) {
    const amount = Math.max(0, Math.min(100, Math.round(Number(value))));
    if (!output || isNaN(amount)) return;
    pendingBrightness = { output: output, value: amount };
    error = "";
    brightnessDebounce.restart();
  }

  function flushBrightness() {
    if (!pendingBrightness || brightnessAction.running) return;
    if (displayAction.running) {
      brightnessDebounce.restart();
      return;
    }
    const request = pendingBrightness;
    pendingBrightness = null;
    brightnessAction.command = ["scylla-displayctl", "brightness-set",
      request.output, String(request.value)];
    brightnessAction.running = true;
  }

  function runAction(command, label, quiet) {
    const action = { command: command, label: label, quiet: quiet === true };
    if (displayAction.running) {
      queuedAction = action;
      return;
    }
    displayAction.actionLabel = action.label;
    displayAction.quiet = action.quiet;
    displayAction.command = action.command;
    displayAction.running = true;
  }

  function applyProfile(name, quiet) {
    runAction(["scylla-displayctl", "apply-profile", name],
      "Applied display profile " + name, quiet);
  }

  function applyAdaptiveProfile(name) {
    runAction(["scylla-displayctl", "apply-profile-auto", name],
      "Applied adaptive display profile " + name, true);
  }

  function saveProfile(name) {
    runAction(["scylla-displayctl", "save-profile", name],
      "Saved display profile " + name, false);
  }

  function deleteProfile(name) {
    runAction(["scylla-displayctl", "delete-profile", name],
      "Deleted display profile " + name, false);
  }

  function setMonitor(name, field, value) {
    runAction(["scylla-displayctl", "set", name, field, String(value)],
      "Display settings changed", false);
  }

  function setPosition(name, x, y) {
    setMonitor(name, "position", Math.round(x) + "x" + Math.round(y));
  }

  function capInternalRefresh(maximum, quiet) {
    if (!maximum || maximum <= 0 || !internalDisplay.length) return;
    runAction(["scylla-displayctl", "cap-refresh", internalDisplay,
      String(maximum)], "Limited display refresh to " + maximum + " Hz", quiet);
  }

  function restoreInternalRefresh(quiet) {
    if (!internalDisplay.length) return;
    runAction(["scylla-displayctl", "restore-refresh", internalDisplay],
      "Restored display refresh rate", quiet);
  }

  function confirm() {
    runAction(["scylla-displayctl", "confirm"], "Display settings kept", false);
  }

  function rollback() {
    runAction(["scylla-displayctl", "rollback"], "Display settings restored", false);
  }

  Process {
    id: displayQuery
    command: ["scylla-displayctl", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const result = JSON.parse(text);
          service.monitors = service.decorateMonitors(result.monitors || []);
          service.profiles = result.profiles || {};
          service.currentProfile = result.currentProfile || "";
          service.confirmationPending = result.confirmationPending === true;
          service.error = "";
        } catch (parseError) {
          service.error = "Unable to read display state";
        }
        service.refreshBrightness();
      }
    }
  }

  Process {
    id: brightnessQuery
    command: ["scylla-displayctl", "brightness-list"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          service.mergeBrightness(JSON.parse(text));
        } catch (parseError) {
          service.error = "Unable to read display brightness";
        }
      }
    }
  }

  Process {
    id: displayAction
    property string actionLabel: ""
    property bool quiet: false
    stderr: StdioCollector {
      onStreamFinished: if (text.trim().length) service.error = text.trim()
    }
    onExited: exitCode => {
      if (!quiet) {
        service.osdRequested(exitCode === 0 ? "󰍹" : "",
          exitCode === 0 ? actionLabel : (service.error || "Display action failed"),
          0, false);
      }
      service.refresh();
      const next = service.queuedAction;
      service.queuedAction = null;
      if (next) service.runAction(next.command, next.label, next.quiet);
    }
  }

  Process {
    id: brightnessAction
    stderr: StdioCollector {
      onStreamFinished: if (text.trim().length) service.error = text.trim()
    }
    onExited: exitCode => {
      if (exitCode !== 0 && service.error.length === 0)
        service.error = "Display brightness change failed";
      service.refreshBrightness();
      if (service.pendingBrightness) brightnessDebounce.restart();
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      const name = event && event.name ? event.name.toLowerCase() : "";
      if (name.includes("monitor")) refreshDebounce.restart();
    }
  }

  Timer {
    id: refreshDebounce
    interval: 600
    onTriggered: service.refresh()
  }

  Timer {
    interval: 60000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: service.refresh()
  }

  Timer {
    id: brightnessDebounce
    interval: 180
    onTriggered: service.flushBrightness()
  }
}
