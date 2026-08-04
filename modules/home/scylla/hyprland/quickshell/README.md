# Scylla Quickshell

`shell.qml` is the composition root. Runtime state and device integrations live
in `services/`, shared controls in `components/`, and major UI entry points in
`surfaces/`. Feature code should depend on those service facades instead of QML
IDs inside another surface.

The Network quick-settings section uses NetworkManager. It controls Wi-Fi and
Ethernet devices and shows NetworkManager VPN and WireGuard profiles. The shell
does not create, edit, import, delete, or manage profile secrets.

Home Manager replaces `RuntimeConfig.qml` with host-specific values from
`scylla.desktop.shell`. The checked-in component is only a development fallback.

## IPC

Use IPC instead of depending on the visual layout:

```console
qs -c scylla ipc call shell surface open diagnostics
qs -c scylla ipc call shell surface toggle notifications
qs -c scylla ipc call shell toggleQuickSettings display
qs -c scylla ipc call display status
qs -c scylla ipc call display applyProfile docked
qs -c scylla ipc call display confirm
qs -c scylla ipc call diagnostics status
qs -c scylla ipc call profile set presentation
qs -c scylla ipc call profile set auto
```

Vicinae is the only application launcher. `Super + Space` opens Vicinae.
The `shell` target retains the power, wallpaper, notification, audio,
brightness, and media compatibility methods. Additional targets are:

- `display`: `status`, `refresh`, `applyProfile`, `saveProfile`,
  `deleteProfile`, `set`, `confirm`, and `rollback`.
- `diagnostics`: `refresh` and `status`.
- `resources`: `refresh` and `status`.
- `profile`: `list`, `current`, `set`, and `togglePresentation`.

Interactive display changes have a 20-second confirmation window. If they are
not confirmed, `scylla-displayctl` restores the previous layout. Both the native
surface and the `wdisplays` fallback serialize through the same mutable
`~/.config/hypr/monitors.lua` backend.

The Displays panel also exposes a brightness slider for each enabled monitor.
The internal panel uses `brightnessctl`; external monitors use DDC/CI VCP 0x10
through `ddcutil`, matched to the monitor's DRM connector and EDID description.
Monitors or docks that do not expose DDC/CI brightness remain visible but show
brightness as unavailable. DDC operations are bounded and slider updates are
debounced so a slow monitor cannot block the shell indefinitely.

## Declarative profiles

Reusable policy is declared through `scylla.desktop.shell`. Host configuration
only needs to specify hardware-specific output names and layouts:

```nix
scylla.desktop.shell = {
  internalDisplay = "eDP-1";

  displayProfiles.docked = [
    {
      output = "eDP-1";
      enabled = false;
    }
    {
      output = "DP-3";
      mode = "3840x2160@120";
      position = "0x0";
      scale = 1.5;
      vrr = 2;
    }
  ];

  adaptive.profiles.docked.displayProfile = "docked";
};
```

Adaptive profiles can match battery power, external-monitor state, and an
optional tablet-mode sysfs path. They may select a display or power profile,
cap the internal refresh rate, control animations, enable touch sizing, inhibit
idle, and suppress notification popups. Manual overrides always take priority;
select `auto` to resume context-based policy.

## Keybindings

- `Super + Space`: Vicinae application launcher.
- `Super + M`: native display controls.
- `Super + Shift + M`: `wdisplays` fallback.
- `Super + D`: diagnostics drawer.
- `Super + Shift + P`: presentation mode.
