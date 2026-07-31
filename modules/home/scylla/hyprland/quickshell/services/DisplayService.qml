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
  property var profiles: ({})
  property string currentProfile: ""
  property bool confirmationPending: false
  property string error: ""
  property bool busy: displayQuery.running || displayAction.running
  property var queuedAction: null

  readonly property var enabledMonitors: monitors.filter(monitor => monitor.enabled)
  readonly property bool internalDisplayPresent: internalDisplay.length > 0
    && monitors.some(monitor => monitor.name === internalDisplay)
  readonly property bool externalMonitorConnected: internalDisplayPresent
    && enabledMonitors.some(monitor => monitor.name !== internalDisplay)
  readonly property var profileNames: Object.keys(profiles).sort()

  function refresh() {
    if (!displayQuery.running) displayQuery.running = true;
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
          service.monitors = result.monitors || [];
          service.profiles = result.profiles || {};
          service.currentProfile = result.currentProfile || "";
          service.confirmationPending = result.confirmationPending === true;
          service.error = "";
        } catch (parseError) {
          service.error = "Unable to read display state";
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
}
