// services/Globals.qml
pragma Singleton

import QtQuick
import "../services"

QtObject {
	property color barColor: Theme.base
	property real barOpacity: barHovered? Theme.barOpacityFocused: Theme.barOpacityUnfocused

	property color borderColor: barHovered? Theme.accent: Theme.surface0

	property int barHoverCount: 0
	property bool barHovered: barHoverCount > 0
	function barEnter() {
		barHoverCount++
	}
	function barExit() {
		barHoverCount--
		updateWidgetsVisible()
	}

	property bool taskBarVisible: false
	function expandTaskBar() {
		taskBarVisible = true
		mprisWidgetVisible = false
	}
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
