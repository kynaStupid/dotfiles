// services/Network.qml
// NOTE: this is a NEW api (Quickshell 0.3). If you're on an older Quickshell,
// this module won't exist and you'll need an nmcli-based Process fallback instead.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
	id: root

	// True if any device reports an active connection.
	readonly property bool connected: activeDevice !== null

	// "wifi" | "wired" | "none"
	readonly property string connectionType: {
		if (!activeDevice)
			return "none"
		return activeDevice.type === DeviceType.Wifi ? "wifi" : "wired"
	}

	// SSID (wifi) or connection name (wired), empty string if disconnected.
	readonly property string connectionName: activeNetwork ? activeNetwork.name : ""

	// 0-100, only meaningful when connectionType === "wifi". 0 otherwise.
	readonly property int wifiSignal: {
		if (connectionType !== "wifi" || !activeNetwork)
			return 0
		return Math.round(activeNetwork.signalStrength * 100)
	}

	readonly property bool wifiEnabled: Networking.wifiEnabled
	readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

	// First connected device, or null. Internal helper.
	readonly property var activeDevice: {
		for (const device of Networking.devices.values) {
			if (device.connected)
				return device
		}
		return null
	}

	// The connected Network on activeDevice, or null. Internal helper.
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
