// services/Theme.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

FileView {
	path: Quickshell.env("HOME") + "/.local/state/theme-switcher/active/quickshell-theme.json"
	watchChanges: true
	onFileChanged: reload()

	property alias barHeight: adapter.barHeight
	property alias barWidth: adapter.barWidth
	property alias barTextSize: adapter.barTextSize
	property alias barMargin: adapter.barMargin

	property alias barRadius: adapter.barRadius
	property alias borderWidth: adapter.borderWidth

	property alias barOpacityFocused: adapter.barOpacityFocused
	property alias barOpacityUnfocused: adapter.barOpacityUnfocused

	property alias animFocusDuration: adapter.animFocusDuration
	property alias animMorphDuration: adapter.animMorphDuration
	property alias animMoveDuration: adapter.animMoveDuration

	property color accent: adapter.accent
	property color pink: adapter.pink
	property color red: adapter.red
	property color yellow: adapter.yellow
	property color green: adapter.green
	property color blue: adapter.blue
	property color text: adapter.text
	property color subtext1: adapter.subtext1
	property color subtext0: adapter.subtext0
	property color overlay2: adapter.overlay2
	property color overlay1: adapter.overlay1
	property color overlay0: adapter.overlay0
	property color surface2: adapter.surface2
	property color surface1: adapter.surface1
	property color surface0: adapter.surface0
	property color base: adapter.base
	property color mantle: adapter.mantle
	property color crust: adapter.crust

	JsonAdapter {
		id: adapter
		property real   barHeight           : 24
		property real   barWidth            : 32
		property real   barTextSize         : 12
		property real   barMargin           : 4
		property real   barRadius           : 12
		property real   borderWidth         : 2
		property real   barOpacityFocused   : 1
		property real   barOpacityUnfocused : 1
		property real   animFocusDuration   : 300
		property real   animMorphDuration   : 350
		property real   animMoveDuration    : 350
		property string accent              : "#cba6f7"
		property string pink                : "#f5c2e7"
		property string red                 : "#f38ba8"
		property string yellow              : "#f9e2af"
		property string green               : "#a6e3a1"
		property string blue                : "#89b4fa"
		property string text                : "#cdd6f4"
		property string subtext1            : "#bac2de"
		property string subtext0            : "#a6adc8"
		property string overlay2            : "#9399b2"
		property string overlay1            : "#7f849c"
		property string overlay0            : "#6c7086"
		property string surface2            : "#585b70"
		property string surface1            : "#45475a"
		property string surface0            : "#313244"
		property string base                : "#1e1e2e"
		property string mantle              : "#181825"
		property string crust               : "#11111b"
	}
}
