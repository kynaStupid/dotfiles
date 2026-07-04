// services/MprisService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
	id: root

	readonly property var players: Mpris.players

	// primary player: the most recently playing one
	// or the first connected one if none played yet.
	readonly property MprisPlayer activePlayer: {
		// prefer a currently-playing player
		for (const p of Mpris.players.values) {
			if (p.isPlaying)
				return p
		}
		// fall back to first available
		return Mpris.players.values.length > 0?
			Mpris.players.values[0]:
			null
	}

	readonly property bool hasPlayers: Mpris.players.values.length > 0
}
