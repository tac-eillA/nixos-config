import QtQuick

// Development fallback. Home Manager replaces this component with a generated
// instance containing host-specific declarative display and adaptive policy.
QtObject {
  readonly property var settings: ({
    repositoryWallpapers: "",
    internalDisplay: null,
    tabletModePath: null,
    displayProfiles: {},
    adaptive: { enable: false, profiles: {} }
  })
}
