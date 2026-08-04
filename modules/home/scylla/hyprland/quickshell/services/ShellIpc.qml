import Quickshell
import Quickshell.Io

Scope {
  required property var shell
  required property var core
  required property var displays
  required property var diagnostics
  required property var resources
  required property var adaptive

  IpcHandler {
    target: "shell"

    function togglePower(): void { shell.toggleSurface("power"); }
    function toggleWallpaperPicker(): void { shell.toggleWallpaperPicker(); }
    function toggleNotifications(): void { shell.toggleSurface("notifications"); }
    function toggleDiagnostics(): void { shell.toggleSurface("diagnostics"); }
    function toggleQuickSettings(section: string): void {
      shell.toggleQuickSettings(section);
    }

    function surface(action: string, name: string): string {
      if (action === "open") shell.openSurface(name);
      else if (action === "close") shell.closeSurface(name);
      else if (action === "toggle") shell.toggleSurface(name);
      else return "unknown action";
      return "ok";
    }

    function volumeStep(delta: string): string {
      core.adjustVolume(Number(delta));
      return "ok";
    }
    function toggleMute(): string {
      core.toggleAudioMute();
      return "ok";
    }
    function brightnessStep(delta: string): string {
      core.brightnessStep(Number(delta));
      return "ok";
    }
    function media(action: string): string {
      core.mediaAction(action);
      return "ok";
    }
  }

  IpcHandler {
    target: "display"

    function status(): string {
      return JSON.stringify({
        monitors: displays.monitors,
        profiles: displays.profileNames,
        currentProfile: displays.currentProfile,
        confirmationPending: displays.confirmationPending
      });
    }
    function refresh(): string {
      displays.refresh();
      return "ok";
    }
    function applyProfile(name: string): string {
      displays.applyProfile(name, false);
      return "ok";
    }
    function saveProfile(name: string): string {
      displays.saveProfile(name);
      return "ok";
    }
    function deleteProfile(name: string): string {
      displays.deleteProfile(name);
      return "ok";
    }
    function set(output: string, field: string, value: string): string {
      displays.setMonitor(output, field, value);
      return "ok";
    }
    function setBrightness(output: string, value: string): string {
      displays.setBrightness(output, Number(value));
      return "ok";
    }
    function confirm(): string {
      displays.confirm();
      return "ok";
    }
    function rollback(): string {
      displays.rollback();
      return "ok";
    }
  }

  IpcHandler {
    target: "diagnostics"

    function refresh(): string {
      diagnostics.refresh();
      return "ok";
    }
    function status(): string {
      return JSON.stringify(diagnostics.report);
    }
  }

  IpcHandler {
    target: "resources"

    function refresh(): string {
      resources.refresh();
      return "ok";
    }
    function status(): string {
      return JSON.stringify(resources.report);
    }
  }

  IpcHandler {
    target: "profile"

    function list(): string {
      return JSON.stringify(adaptive.profileNames);
    }
    function current(): string {
      return adaptive.activeProfile;
    }
    function set(name: string): string {
      return adaptive.setManualProfile(name) ? "ok" : "unknown profile";
    }
    function togglePresentation(): string {
      adaptive.setManualProfile(adaptive.manualProfile === "presentation"
        ? "auto" : "presentation");
      return "ok";
    }
  }
}
