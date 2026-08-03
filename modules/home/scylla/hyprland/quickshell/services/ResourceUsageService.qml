import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: service

  property var report: ({
    power: {
      watts: null,
      source: "unavailable",
      label: "Power draw unavailable",
      state: "unknown",
      exact: false
    },
    system: {
      cpuPercent: null,
      memory: { usedBytes: null, totalBytes: null, usedPercent: null },
      gpus: []
    },
    applications: { energy: [], memory: [], hardware: [] }
  })
  property bool busy: collector.running
  property string error: ""
  property string updatedAt: ""

  function refresh() {
    if (!collector.running) collector.running = true;
  }

  Process {
    id: collector
    command: ["scylla-resource-usage"]

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          service.report = JSON.parse(text);
          service.updatedAt = service.report.generatedAt || "";
          service.error = "";
        } catch (parseError) {
          service.error = "Unable to parse resource usage";
        }
      }
    }

    stderr: StdioCollector {
      onStreamFinished: if (text.trim().length) service.error = text.trim()
    }

    onExited: (exitCode, exitStatus) => {
      if (exitCode !== 0 && service.error.length === 0)
        service.error = "Unable to collect resource usage";
    }
  }
}
