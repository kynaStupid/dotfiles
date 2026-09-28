// services/Network.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
	id: root

	readonly property bool connected: activeDevice !== null

	readonly property string connectionType: {
		if (!activeDevice)
			return "none"
		return activeDevice.type === DeviceType.Wifi ? "wifi" : "wired"
	}

	readonly property string connectionName: activeNetwork ? activeNetwork.name : ""

	readonly property int wifiSignal: {
		if (connectionType !== "wifi" || !activeNetwork)
			return 0
		return Math.round(activeNetwork.signalStrength * 100)
	}

	readonly property bool wifiEnabled: Networking.wifiEnabled
	readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

	readonly property var activeDevice: {
		for (const device of Networking.devices.values) {
			if (device.connected)
				return device
		}
		return null
	}

	readonly property var activeNetwork: {
		if (!activeDevice)
			return null
		for (const network of activeDevice.networks.values) {
			if (network.connected)
				return network
		}
		return null
	}

	function toggleWifi() {
		Networking.wifiEnabled = !Networking.wifiEnabled
	}
}
