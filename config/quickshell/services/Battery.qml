// services/Battery.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
	id: root

	readonly property UPowerDevice device: UPower.displayDevice
	readonly property bool ready: device?.ready ?? false

	readonly property int percentage: Math.round((device?.percentage ?? 0))

	readonly property bool isLaptopBattery: device?.isLaptopBattery ?? false
	readonly property bool present: device?.isPresent ?? false

	readonly property var state: device?.state ?? null
	readonly property bool charging: state === UPowerDeviceState.Charging

	readonly property int timeToEmpty: device?.timeToEmpty ?? 0
	readonly property int timeToFull: device?.timeToFull ?? 0

	readonly property string timeRemainingText: {
		const secs = charging ? timeToFull : timeToEmpty
		if (secs <= 0)
			return ""
		const h = Math.floor(secs / 3600)
		const m = Math.floor((secs % 3600) / 60)
		return h > 0 ? `${h}h ${m}m` : `${m}m`
	}
}
