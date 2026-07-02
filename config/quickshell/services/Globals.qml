// services/Globals.qml
pragma Singleton

import QtQuick
import "../services"

QtObject {
	property real barHeight: 24
	property real barWidth: 32
	property color barColor: Mocha.base
	property real barOpacity: barHovered? 0.95: 0.85
	property real barTextSize: 14
	property real barMargin: 4
	property real barRadius: 12

	property real borderWidth: 2
	property color borderColor: barHovered? Mocha.accent: Mocha.surface0

	property real animFocusDuration: 300
	property real animMorphDuration: 350
	property real animMoveDuration: 350

	property bool statusbarHovered: false
	property bool taskbarHovered: false
	property bool taskbarVisible: false
	function updateTaskbarVisible() {
		if (!barHovered)
			taskbarVisible = false
	}

	property bool barHovered:
		statusbarHovered || taskbarHovered
}
