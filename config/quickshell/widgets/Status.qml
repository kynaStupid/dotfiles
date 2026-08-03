// widgets/Status.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import "../services"

Item {
	component NetworkWidget: Text {
		color: Theme.text
		font.pointSize: Theme.barTextSize
		text: {
			if (!Network.connected)
				return "󰤭 Disconnected"
			if (Network.connectionType === "wifi")
				return "󰤨 " + Network.connectionName + " (" + Network.wifiSignal + "%)"
			return "󰈀 " + Network.connectionName
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton
			//onClicked: Network.toggleWifi()
		}
	}

	component VolumeWidget: Text {
		color: Theme.green
		font.pointSize: Theme.barTextSize
		text: {
			if (Audio.muted)
				return "󰝟 Muted"
			return "󰕾 " + Math.round(Audio.volume * 100) + "%"
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			acceptedButtons: Qt.LeftButton
			onClicked: Audio.toggleMute()
			onWheel: wheel => {
				const step = 0.05
				Audio.setVolume(Audio.volume + (wheel.angleDelta.y > 0? step: -step))
			}
		}
	}

	component BatteryWidget: Text {
		visible: Battery.present
		color: Battery.percentage <= 15 && !Battery.charging? Theme.red: Theme.text
		font.pointSize: Theme.barTextSize
		text: {
			const icon = Battery.charging ? "󰂄" : "󰁹"
			let s = icon + " " + Battery.percentage + "%"
			if (Battery.timeRemainingText !== "")
				s += " (" + Battery.timeRemainingText + ")"
			return s
		}
	}

	component TrayWidget: Item {
		property var anchorWindow: null
		property bool vertical: false
		implicitWidth: vertical? Theme.barHeight: layout.implicitWidth
		implicitHeight: vertical? layout.implicitHeight: Theme.barHeight

		GridLayout {
			id: layout
			columns: vertical? 1: -1
			rows: vertical? -1: 1
			flow: vertical? GridLayout.TopToBottom: GridLayout.LeftToRight
			columnSpacing: Theme.barMargin; rowSpacing: Theme.barMargin

			Repeater {
				model: SystemTray.items
	
				delegate: Item {
					id: trayItem
					required property var modelData
	
					implicitWidth: Theme.barHeight
					implicitHeight: Theme.barHeight

					Image {
						anchors.centerIn: parent
						anchors.margins: Theme.barMargin
						width: parent.width
						height: parent.height
						source: trayItem.modelData.icon
						sourceSize: Qt.size(width, height)
						smooth: true
					}

					QsMenuAnchor {
						id: menuAnchor
						menu: trayItem.modelData.menu
						anchor.window: anchorWindow
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						acceptedButtons: Qt.LeftButton | Qt.RightButton
						onClicked: mouse => {
							if (trayItem.modelData.onlyMenu || mouse.button === Qt.RightButton) {
								if (trayItem.modelData.hasMenu)
									menuAnchor.open()
							} else {
								trayItem.modelData.activate()
							}
						}
					}
				}
			}
		}
	}
}
