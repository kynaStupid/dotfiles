// services/SystemStats.qml
//
// One singleton, one timer, polling /proc for CPU + memory usage.
// Widgets bind to SystemStats.cpuUsage / SystemStats.memUsage directly —
// no per-widget Process needed, which avoids spawning N processes for N bar
// instances (relevant if you ever run this on multiple monitors).
//
// To add GPU later: same pattern, just add a `nvidiaProc` (or similar) and
// a `gpuUsage` property below, then poll it in the same Timer.onTriggered.

pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
	id: root

	readonly property int pollIntervalMs: 2000

	property int cpuUsage: 0
	property int memUsage: 0

	// --- CPU ---
	// Reads cumulative jiffies from /proc/stat and diffs against the last
	// sample to get a percentage. A single sample of /proc/stat is a
	// cumulative counter since boot, not an instantaneous rate, hence the
	// diffing logic.
	property real _lastCpuIdle: 0
	property real _lastCpuTotal: 0

	Process {
		id: cpuProc
		command: ["sh", "-c", "head -1 /proc/stat"]
		stdout: SplitParser {
			onRead: data => {
				if (!data)
					return
				// fields: cpu user nice system idle iowait irq softirq ...
				const p = data.trim().split(/\s+/)
				const idle = parseInt(p[4]) + parseInt(p[5])
				const total = p.slice(1, 8).reduce((a, b) => a + parseInt(b), 0)

				if (root._lastCpuTotal > 0) {
					const idleDelta = idle - root._lastCpuIdle
					const totalDelta = total - root._lastCpuTotal
					if (totalDelta > 0)
						root.cpuUsage = Math.round(100 * (1 - idleDelta / totalDelta))
				}
				root._lastCpuTotal = total
				root._lastCpuIdle = idle
			}
		}
	}

	// --- Memory ---
	Process {
		id: memProc
		command: ["sh", "-c", "free | grep Mem"]
		stdout: SplitParser {
			onRead: data => {
				if (!data)
					return
				// fields: Mem: total used free shared buff/cache available
				const p = data.trim().split(/\s+/)
				const total = parseInt(p[1]) || 1
				const used = parseInt(p[2]) || 0
				root.memUsage = Math.round(100 * used / total)
			}
		}
	}

	Timer {
		interval: root.pollIntervalMs
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			cpuProc.running = true
			memProc.running = true
		}
	}
}
