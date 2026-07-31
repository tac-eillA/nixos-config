import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Scope {
  id: adaptive

  required property var shell
  required property var core
  required property var displays
  required property var settings

  signal osdRequested(string icon, string label, int value, bool hasProgress)

  property string activeProfile: ""
  property string manualProfile: ""
  property bool tabletMode: false
  property bool applying: false
  property bool idleManaged: false
  property bool idleBaseline: false
  property bool dndManaged: false
  property bool dndBaseline: false
  property bool touchManaged: false
  property bool touchBaseline: false

  readonly property bool enabled: settings.adaptive
    && settings.adaptive.enable === true
  readonly property var profiles: settings.adaptive
    ? (settings.adaptive.profiles || {}) : ({})
  readonly property var profileNames: Object.keys(profiles).sort()

  function matches(profile) {
    const match = profile.match || {};
    if (match.onBattery !== null && match.onBattery !== undefined
        && match.onBattery !== UPower.onBattery) return false;
    if (match.externalMonitor !== null && match.externalMonitor !== undefined
        && match.externalMonitor !== displays.externalMonitorConnected) return false;
    if (match.tabletMode !== null && match.tabletMode !== undefined
        && match.tabletMode !== tabletMode) return false;
    return true;
  }

  function selectedProfile() {
    if (!enabled) return "";
    if (manualProfile.length && profiles[manualProfile]) return manualProfile;
    let selected = "";
    let priority = -2147483648;
    for (const name of profileNames) {
      const profile = profiles[name];
      if (!profile || profile.manualOnly || !matches(profile)) continue;
      const candidatePriority = Number(profile.priority || 0);
      if (candidatePriority > priority) {
        selected = name;
        priority = candidatePriority;
      }
    }
    return selected;
  }

  function setManualProfile(name) {
    if (name === "auto" || name === "") manualProfile = "";
    else if (profiles[name]) manualProfile = name;
    else return false;
    evaluate();
    return true;
  }

  function evaluate() {
    policyDebounce.restart();
  }

  function manageIdle(value) {
    if (value !== null && value !== undefined) {
      if (!idleManaged) idleBaseline = core.idleInhibited;
      idleManaged = true;
      if (core.idleInhibited !== value) core.setIdleInhibited(value, true);
    } else if (idleManaged) {
      core.setIdleInhibited(idleBaseline, true);
      idleManaged = false;
    }
  }

  function manageDnd(value) {
    if (value !== null && value !== undefined) {
      if (!dndManaged) dndBaseline = core.doNotDisturb;
      dndManaged = true;
      core.doNotDisturb = value;
    } else if (dndManaged) {
      core.doNotDisturb = dndBaseline;
      dndManaged = false;
    }
  }

  function manageTouch(value) {
    if (value !== null && value !== undefined) {
      if (!touchManaged) touchBaseline = shell.touchLayout;
      touchManaged = true;
      shell.touchLayout = value;
    } else if (touchManaged) {
      shell.touchLayout = touchBaseline;
      touchManaged = false;
    }
  }

  function applySelected() {
    const name = selectedProfile();
    if (name === activeProfile) return;
    const previous = activeProfile;
    activeProfile = name;
    const profile = name.length ? profiles[name] : null;

    if (!profile) {
      manageIdle(null);
      manageDnd(null);
      manageTouch(null);
      displays.restoreInternalRefresh(true);
      return;
    }

    if (profile.displayProfile && profile.displayProfile.length
        && displays.currentProfile !== profile.displayProfile)
      displays.applyAdaptiveProfile(profile.displayProfile);

    if (profile.powerProfile && profile.powerProfile.length
        && core.activePowerProfile !== profile.powerProfile)
      core.setPowerProfile(profile.powerProfile);

    if (profile.animations !== null && profile.animations !== undefined) {
      animationAction.command = ["hyprctl", "keyword", "animations:enabled",
        profile.animations ? "1" : "0"];
      animationAction.running = true;
    }

    if (profile.maxRefreshRate !== null && profile.maxRefreshRate !== undefined)
      displays.capInternalRefresh(Number(profile.maxRefreshRate), true);
    else
      displays.restoreInternalRefresh(true);

    manageIdle(profile.idleInhibit);
    manageDnd(profile.doNotDisturb);
    manageTouch(profile.touchLayout);

    if (previous.length || manualProfile.length) {
      osdRequested(name === "presentation" ? "󰐩" : "󰌪",
        "Hardware profile: " + name, 0, false);
    }
  }

  Process { id: animationAction }

  Process {
    id: tabletModeQuery
    command: settings.tabletModePath
      ? ["sh", "-c",
        "value=$(cat -- \"$1\" 2>/dev/null || true); "
          + "[ \"$value\" = 1 ] && printf true || printf false",
        "sh", settings.tabletModePath]
      : ["printf", "false"]
    stdout: StdioCollector {
      onStreamFinished: {
        const detected = text.trim() === "true";
        if (adaptive.tabletMode !== detected) {
          adaptive.tabletMode = detected;
          adaptive.evaluate();
        }
      }
    }
  }

  Connections {
    target: UPower
    function onOnBatteryChanged() { adaptive.evaluate(); }
  }

  Connections {
    target: displays
    function onExternalMonitorConnectedChanged() { adaptive.evaluate(); }
  }

  Timer {
    id: policyDebounce
    interval: 800
    onTriggered: adaptive.applySelected()
  }

  Timer {
    interval: 10000
    running: adaptive.enabled
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      if (!tabletModeQuery.running) tabletModeQuery.running = true;
      adaptive.evaluate();
    }
  }
}
