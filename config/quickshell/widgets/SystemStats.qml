// widgets/SystemStats.qml
import QtQuick
import "../services"

Item {
	component CpuWidget: Text {
		color: Mocha.yellow
		font.pixelSize: Globals.barTextSize
		text: "  " + SystemStats.cpuUsage + "%cpu"
	}

	component MemWidget: Text {
		color: Mocha.blue
		font.pixelSize: Globals.barTextSize
		text: " " + SystemStats.memUsage + "%ram"
	}
}
