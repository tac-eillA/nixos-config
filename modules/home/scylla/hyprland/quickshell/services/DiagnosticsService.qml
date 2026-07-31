import QtQuick
import Quickshell
import Quickshell.Io

Scope {
  id: service

  property var report: ({
    failedServices: { system: [], user: [] },
    batteries: [],
    thermal: [],
    generations: {},
    suspend: { result: "unknown", recent: [] },
    hyprlandErrors: []
  })
  property bool busy: collector.running
  property string error: ""
  property string updatedAt: ""

  readonly property int failedServiceCount:
    (report.failedServices.system || []).length
      + (report.failedServices.user || []).length
  readonly property int thermalWarningCount: (report.thermal || [])
    .filter(sensor => sensor.severity !== "normal").length
  readonly property int batteryWarningCount: (report.batteries || [])
    .filter(battery => battery.health !== null && battery.health < 80).length
  readonly property int configurationErrorCount: (report.hyprlandErrors || []).length
  readonly property bool rebootPending: report.generations.rebootPending === true
  readonly property bool activationPending: report.generations.activationPending === true
  readonly property int issueCount: failedServiceCount + thermalWarningCount
    + batteryWarningCount + configurationErrorCount
    + (rebootPending ? 1 : 0) + (activationPending ? 1 : 0)

  function refresh() {
    if (!collector.running) collector.running = true;
  }

  Process {
    id: collector
    command: ["scylla-diagnostics"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          service.report = JSON.parse(text);
          service.updatedAt = service.report.generatedAt || "";
          service.error = "";
        } catch (parseError) {
          service.error = "Unable to parse diagnostics";
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: if (text.trim().length) service.error = text.trim()
    }
  }

  Timer {
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: service.refresh()
  }
}
