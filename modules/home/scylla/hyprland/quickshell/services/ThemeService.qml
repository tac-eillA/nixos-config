import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: theme

  property color background: "#000000"
  property color surface: "#000000"
  property color elevated: "#0a0a0a"
  property color foreground: "#ffffff"
  property color muted: "#a6a6a6"
  property color accent: "#8aadf4"
  property color urgent: "#ed8796"
  property color normalFill: "#0ac6d0f5"
  property color hoverFill: "#14c6d0f5"
  property color selectedFill: "#2ec6d0f5"
  property color outline: "#66494d64"

  function applyGenerated(data) {
    try {
      const generated = JSON.parse(data);
      accent = generated.accent || accent;
      urgent = generated.urgent || urgent;
      outline = generated.outline || outline;
    } catch (error) {
      console.warn("Unable to load generated desktop theme:", error);
    }
  }

  function reload() {
    if (!generatedTheme.running) generatedTheme.running = true;
  }

  Process {
    id: generatedTheme
    command: ["sh", "-lc",
      "state=\"${XDG_STATE_HOME:-$HOME/.local/state}/scylla-theme\"; "
      + "[ -r \"$state/theme.json\" ] && cat \"$state/theme.json\" || true"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: if (text.trim().length) theme.applyGenerated(text)
    }
  }
}
