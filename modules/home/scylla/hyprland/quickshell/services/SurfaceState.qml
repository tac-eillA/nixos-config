import QtQuick

QtObject {
  id: state

  property bool powerVisible: false
  property bool wallpaperPickerVisible: false
  property bool calendarVisible: false
  property bool fingerprintVisible: false
  property bool helpVisible: false
  property bool quickSettingsVisible: false
  property string quickSettingsSection: "network"
  property bool notificationsVisible: false
  property bool diagnosticsVisible: false

  readonly property var surfaceProperties: ({
    power: "powerVisible",
    wallpaper: "wallpaperPickerVisible",
    calendar: "calendarVisible",
    fingerprint: "fingerprintVisible",
    help: "helpVisible",
    quickSettings: "quickSettingsVisible",
    notifications: "notificationsVisible",
    diagnostics: "diagnosticsVisible"
  })

  function propertyFor(surface) {
    return surfaceProperties[surface] || "";
  }

  function isVisible(surface) {
    const property = propertyFor(surface);
    return property.length > 0 && state[property];
  }

  function setVisible(surface, visible) {
    const property = propertyFor(surface);
    if (property.length === 0) return false;
    state[property] = visible;
    return true;
  }

  function close(surface) {
    return setVisible(surface, false);
  }

  function closeAll() {
    for (const surface in surfaceProperties)
      setVisible(surface, false);
  }

  function openExclusive(surface) {
    closeAll();
    setVisible(surface, true);
  }

  function toggleExclusive(surface) {
    const wasVisible = isVisible(surface);
    closeAll();
    if (!wasVisible) setVisible(surface, true);
  }

  function toggleQuickSettings(section) {
    const wasVisible = quickSettingsVisible && quickSettingsSection === section;
    closeAll();
    quickSettingsSection = section;
    quickSettingsVisible = !wasVisible;
  }
}
