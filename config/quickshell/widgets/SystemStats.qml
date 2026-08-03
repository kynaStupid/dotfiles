// widgets/SystemStats.qml
import QtQuick
import "../services"

Item {
	component CpuWidget: Text {
		color: Theme.yellow
		font.pointSize: Theme.barTextSize
		text: "  " + SystemStats.cpuUsage + "%cpu"
	}

	component MemWidget: Text {
		color: Theme.blue
		font.pointSize: Theme.barTextSize
		text: " " + SystemStats.memUsage + "%ram"
	}
}
