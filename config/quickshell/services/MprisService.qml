// services/MprisService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
	id: root

	readonly property var players: Mpris.players

	readonly property MprisPlayer activePlayer: {
		for (const p of Mpris.players.values) {
			if (p.isPlaying)
				return p
		}
		return Mpris.players.values.length > 0?
			Mpris.players.values[0]:
			null
	}

	readonly property bool hasPlayers: Mpris.players.values.length > 0
}
