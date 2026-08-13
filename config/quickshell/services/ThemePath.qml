// services/ThemePath.qml
pragma Singleton

import Quickshell
import Quickshell.Io

FileView {
	id: themePathFile

	path: {
		const xdgConfigHome = Quickshell.env("XDG_CONFIG_HOME")
		return (xdgConfigHome?
			xdgConfigHome:
			Quickshell.env("HOME") + "/.config"
		) + "/quickshell-theme-path"
	}

	watchChanges: true
	onFileChanged: reload()

	property string themePath: text().trim()
}
