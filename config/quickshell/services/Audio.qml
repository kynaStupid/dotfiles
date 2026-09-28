// services/Audio.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
	id: root

	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property PwNode source: Pipewire.defaultAudioSource

	readonly property real volume: sink?.audio?.volume ?? 0
	readonly property bool muted: !!sink?.audio?.muted

	readonly property real micVolume: source?.audio?.volume ?? 0
	readonly property bool micMuted: !!source?.audio?.muted

	function setVolume(vol: real): void {
		if (sink?.ready && sink?.audio) {
			sink.audio.muted = false
			sink.audio.volume = Math.max(0, Math.min(1, vol))
		}
	}

	function toggleMute(): void {
		if (sink?.ready && sink?.audio)
			sink.audio.muted = !sink.audio.muted
	}

	function toggleMicMute(): void {
		if (source?.ready && source?.audio)
			source.audio.muted = !source.audio.muted
	}

	PwObjectTracker {
		objects: [root.sink, root.source]
	}
}
