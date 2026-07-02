// services/Audio.qml
// IMPORTANT: PwObjectTracker is required here. Pipewire nodes are created
// and destroyed dynamically as hardware/streams come and go; without
// tracking them explicitly, the sink/source objects can be garbage
// collected out from under you and volume/mute bindings silently stop
// updating. See: https://github.com/quickshell-mirror/quickshell/issues/54
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
	id: root

	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property PwNode source: Pipewire.defaultAudioSource

	// 0.0 - 1.0 (sometimes a bit over 1.0 if overdriven, clamp at the UI layer if needed)
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

	// Keeps the dynamically-created sink/source nodes alive as long as this
	// singleton exists. Without this, bindings above can silently stop
	// updating after the underlying pipewire node is recreated.
	PwObjectTracker {
		objects: [root.sink, root.source]
	}
}
