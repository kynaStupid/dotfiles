// services/Globals.qml
pragma Singleton

import QtQuick
import "../services"

QtObject {
	property real barHeight: 24
	property real barWidth: 32
	property color barColor: Mocha.base
	property real barOpacity: barHovered? 0.95: 0.85
	property real barTextSize: 12
	property real barMargin: 4
	property real barRadius: 12

	property real borderWidth: 2
	property color borderColor: barHovered? Mocha.accent: Mocha.surface0

	property real animFocusDuration: 300
	property real animMorphDuration: 350
	property real animMoveDuration: 350

	property bool statusBarHovered: false
	property bool taskBarHovered: false
	property bool taskBarVisible: false
	function expandTaskBar() {
		taskBarVisible = true
		mprisWidgetVisible = false
	}
	property bool mprisWidgetHovered: false
	property bool mprisWidgetVisible: false
	function expandMprisWidget() {
		mprisWidgetVisible = true
		taskBarVisible = false
	}

	function updateWidgetsVisible() {
		if (!barHovered) {
			taskBarVisible = false
			mprisWidgetVisible = false
		}
	}

	property bool barHovered:
		statusBarHovered || taskBarHovered || mprisWidgetHovered

	function absoluteX(item, root) {
		let x = 0
		let current = item
		while (current !== root) {
			x += current.x
			current = current.parent
		}
		return x
	}
	function absoluteY(item, root) {
		let y = 0
		let current = item
		while (current !== root) {
			y += current.y
			current = current.parent
		}
		return y
	}
}
