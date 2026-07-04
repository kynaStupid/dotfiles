// widgets/Simple.qml
import Quickshell
import Quickshell.Io
import QtQuick
import "../services"

Item {
	id: root

	component TextButton: Text {
		id: button
		property string label: ""
		property string onClickCommand: ""

		signal clicked()

		text: label
		color: Mocha.text
		font.pointSize: Globals.barTextSize

		MouseArea {
			anchors.fill: parent
			cursorShape: button.onClickCommand !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
			onClicked: {
				if (button.onClickCommand !== "")
					buttonProc.running = true
				button.clicked()
			}
		}

		Process {
			id: buttonProc
			command: ["sh", "-c", button.onClickCommand]
		}
	}

	component Launcher: Text {
		property string command: "wofi --show drun"

		text: "🔍"
		color: Mocha.text
		font.pointSize: Globals.barTextSize

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: launcherProc.running = true
		}

		Process {
			id: launcherProc
			command: ["sh", "-c", parent.command]
		}
	}

	component Clock: Text {
		// format: "{:%A %B %d %H:%M %p}" -> "Wednesday June 25 14:32 PM"
		property string format: "dddd MMMM dd hh:mm AP"

		color: Mocha.text
		font.pointSize: Globals.barTextSize
		text: Qt.formatDateTime(new Date(), format)

		Timer {
			interval: 1000
			running: true
			repeat: true
			onTriggered: parent.text = Qt.formatDateTime(new Date(), parent.format)
		}
	}
}
