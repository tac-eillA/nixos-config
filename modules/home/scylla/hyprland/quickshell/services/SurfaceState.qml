import QtQuick

QtObject {
  id: state

  property bool launcherVisible: false
  property bool powerVisible: false
  property bool wallpaperPickerVisible: false
  property bool calendarVisible: false
  property bool fingerprintVisible: false
  property bool helpVisible: false
  property bool quickSettingsVisible: false
  property string quickSettingsSection: "network"
  property bool notificationsVisible: false
  property bool diagnosticsVisible: false

  function closeAll() {
    launcherVisible = false;
    powerVisible = false;
    wallpaperPickerVisible = false;
    calendarVisible = false;
    fingerprintVisible = false;
    helpVisible = false;
    quickSettingsVisible = false;
    notificationsVisible = false;
    diagnosticsVisible = false;
  }

  function openExclusive(surface) {
    closeAll();
    if (surface === "launcher") launcherVisible = true;
    else if (surface === "power") powerVisible = true;
    else if (surface === "wallpaper") wallpaperPickerVisible = true;
    else if (surface === "calendar") calendarVisible = true;
    else if (surface === "fingerprint") fingerprintVisible = true;
    else if (surface === "help") helpVisible = true;
    else if (surface === "notifications") notificationsVisible = true;
    else if (surface === "diagnostics") diagnosticsVisible = true;
  }

  function toggleExclusive(surface) {
    let wasVisible = false;
    if (surface === "launcher") wasVisible = launcherVisible;
    else if (surface === "power") wasVisible = powerVisible;
    else if (surface === "wallpaper") wasVisible = wallpaperPickerVisible;
    else if (surface === "calendar") wasVisible = calendarVisible;
    else if (surface === "fingerprint") wasVisible = fingerprintVisible;
    else if (surface === "help") wasVisible = helpVisible;
    else if (surface === "notifications") wasVisible = notificationsVisible;
    else if (surface === "diagnostics") wasVisible = diagnosticsVisible;
    closeAll();
    if (!wasVisible) openExclusive(surface);
  }

  function toggleQuickSettings(section) {
    const wasVisible = quickSettingsVisible && quickSettingsSection === section;
    closeAll();
    quickSettingsSection = section;
    quickSettingsVisible = !wasVisible;
  }
}
