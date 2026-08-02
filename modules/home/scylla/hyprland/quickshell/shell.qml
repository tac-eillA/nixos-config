//@ pragma ShellId scylla
//@ pragma IconTheme Adwaita

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "services"
import "surfaces"

ShellRoot {
  id: root

  RuntimeConfig { id: runtimeConfig }
  ThemeService { id: theme }
  SurfaceState { id: surfaces }
  OsdState { id: osd }

  property alias background: theme.background
  property alias surface: theme.surface
  property alias elevated: theme.elevated
  property alias foreground: theme.foreground
  property alias muted: theme.muted
  property alias accent: theme.accent
  property alias urgent: theme.urgent
  property alias normalFill: theme.normalFill
  property alias hoverFill: theme.hoverFill
  property alias selectedFill: theme.selectedFill
  property alias outline: theme.outline

  property int cornerRadius: 10
  property int edgeGap: 5
  property int barHeight: touchLayout ? 47 : 39
  property int transitionDuration: touchLayout ? 260 : 420
  property bool touchLayout: false
  property bool clockAlternate: false

  property alias launcherVisible: surfaces.launcherVisible
  property alias powerVisible: surfaces.powerVisible
  property alias wallpaperPickerVisible: surfaces.wallpaperPickerVisible
  property alias calendarVisible: surfaces.calendarVisible
  property alias fingerprintVisible: surfaces.fingerprintVisible
  property alias helpVisible: surfaces.helpVisible
  property alias quickSettingsVisible: surfaces.quickSettingsVisible
  property alias quickSettingsSection: surfaces.quickSettingsSection
  property alias notificationsVisible: surfaces.notificationsVisible
  property alias diagnosticsVisible: surfaces.diagnosticsVisible

  property alias osdVisible: osd.visible
  property alias osdIcon: osd.icon
  property alias osdLabel: osd.label
  property alias osdValue: osd.value
  property alias osdHasProgress: osd.hasProgress

  readonly property string repositoryWallpapers:
    runtimeConfig.settings.repositoryWallpapers || ""
  property string wallpaper: "file://"
    + (Quickshell.env("XDG_STATE_HOME")
      || (Quickshell.env("HOME") + "/.local/state"))
    + "/scylla-theme/wallpaper"

  property var paletteCommands: [
    { name: "Lock session", icon: "", command: "loginctl lock-session", keywords: "secure screen" },
    { name: "Suspend", icon: "󰤄", command: "systemctl suspend", keywords: "sleep" },
    { name: "Log out", icon: "󰍃", command: "uwsm stop", keywords: "exit session" },
    { name: "Reboot", icon: "󰜉", command: "systemctl reboot", keywords: "restart" },
    { name: "Power off", icon: "", command: "systemctl poweroff", keywords: "shutdown" },
    { name: "Display settings", icon: "󰍹", command: "qs -c scylla ipc call shell toggleQuickSettings display", keywords: "monitor screen" },
    { name: "System diagnostics", icon: "󰒡", command: "qs -c scylla ipc call shell toggleDiagnostics", keywords: "services thermal generation reboot" }
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
    surfaces.closeAll();
    core.setBluetoothDiscovery(false);
  }

  function openSurface(name) {
    if (name === "quickSettings") {
      openQuickSettings(quickSettingsSection);
      return;
    }
    if (name === "fingerprint") {
      fingerprintPanel.open();
      return;
    }
    if (name === "wallpaper") {
      if (!wallpaperPickerVisible) wallpaperPanel.toggle();
      return;
    }
    surfaces.openExclusive(name);
    core.setBluetoothDiscovery(false);
    if (name === "diagnostics") diagnostics.refresh();
  }

  function closeSurface(name) {
    if (name === "fingerprint") fingerprintPanel.close();
    else surfaces.close(name);
    if (name === "quickSettings") core.setBluetoothDiscovery(false);
  }

  function toggleSurface(name) {
    if (name === "quickSettings") {
      toggleQuickSettings(quickSettingsSection);
      return;
    }
    if (name === "fingerprint") {
      toggleFingerprint();
      return;
    }
    if (name === "wallpaper") {
      toggleWallpaperPicker();
      return;
    }
    surfaces.toggleExclusive(name);
    core.setBluetoothDiscovery(false);
    if (name === "diagnostics" && diagnosticsVisible) diagnostics.refresh();
  }

  function openQuickSettings(section) {
    surfaces.closeAll();
    surfaces.quickSettingsSection = section;
    surfaces.quickSettingsVisible = true;
    prepareQuickSettings(section);
  }

  function toggleQuickSettings(section) {
    surfaces.toggleQuickSettings(section);
    prepareQuickSettings(quickSettingsVisible ? section : "");
  }

  function prepareQuickSettings(section) {
    core.setBluetoothDiscovery(section === "bluetooth");
    if (section === "network") core.scanNetworks();
    else if (section === "tailscale") core.refreshTailscale();
    else if (section === "battery") core.refreshPowerProfile();
    else if (section === "display") displays.refresh();
  }

  function toggleFingerprint() {
    if (fingerprintVisible) fingerprintPanel.close();
    else fingerprintPanel.open();
  }

  function toggleWallpaperPicker() {
    wallpaperPanel.toggle();
  }

  function showOsd(icon, label, value, hasProgress) {
    osd.show(icon, label, value, hasProgress);
  }

  function reloadGeneratedTheme() {
    theme.reload();
  }

  CoreServices {
    id: core
    onOsdRequested: (icon, label, value, hasProgress) =>
      root.showOsd(icon, label, value, hasProgress)
  }

  DisplayService {
    id: displays
    internalDisplay: runtimeConfig.settings.internalDisplay || ""
    onOsdRequested: (icon, label, value, hasProgress) =>
      root.showOsd(icon, label, value, hasProgress)
  }

  DiagnosticsService { id: diagnostics }

  AdaptiveProfileService {
    id: adaptive
    shell: root
    core: core
    displays: displays
    settings: runtimeConfig.settings
    onOsdRequested: (icon, label, value, hasProgress) =>
      root.showOsd(icon, label, value, hasProgress)
  }

  ShellIpc {
    shell: root
    core: core
    displays: displays
    diagnostics: diagnostics
    adaptive: adaptive
  }

  Bar {
    shell: root
    core: core
    diagnostics: diagnostics
    adaptive: adaptive
  }
  QuickSettings {
    shell: root
    core: core
    displays: displays
    adaptive: adaptive
  }
  Notifications { shell: root; core: core }
  DiagnosticsDrawer { shell: root; diagnostics: diagnostics }
  Launcher { shell: root }
  PowerMenu { shell: root }
  Osd { shell: root }
  Wallpaper { shell: root }

  CalendarPanel { shell: root }
  FingerprintPanel { id: fingerprintPanel; shell: root }
  HelpPanel { shell: root }
  WallpaperPanel { id: wallpaperPanel; shell: root }
}
