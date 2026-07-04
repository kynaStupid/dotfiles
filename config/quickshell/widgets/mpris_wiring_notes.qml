// ============================================================
// ADDITIONS TO services/Globals.qml
// ============================================================
// Add these properties alongside your existing barHovered logic:

/*
	property bool mprisHotspotHovered: false
	property bool mprisPanelHovered: false
	property bool mprisVisible: false

	// mirror your existing taskbar pattern exactly
	property bool mprisHovered: mprisHotspotHovered || mprisPanelHovered

	// update barHovered to include mpris panel
	property bool barHovered:
		statusbarHovered || taskbarHovered || mprisPanelHovered

	function updateMprisVisible() {
		if (!mprisHovered)
			mprisVisible = false
	}
*/

// In MprisCompact's hover MouseArea:
//   onEntered: Globals.mprisVisible = true
//   (already done above — the hotspot SETS visible on enter,
//    the panel's own MouseArea keeps it alive while inside)

// ============================================================
// WIRING IN panels/Bar.qml
// ============================================================
// Inside your root Item, alongside statusbar/taskbar:

/*
	// compact widget goes inside your statusbar's center RowLayout:
	MprisCompact {}

	// expanded panel sits as a sibling of statusbar/taskbar,
	// positioned wherever makes sense for your layout.
	// Example: expanding downward from wherever MprisCompact sits
	// horizontally (you'll need to set x to match):
	MprisExpanded {
		id: mprisPanel
		anchors.top: statusbar.bottom
		x: <x position of MprisCompact in the bar>
		visible: Globals.mprisVisible || height > 0
	}
*/

// ============================================================
// REGISTER MprisService in services/qmldir
// ============================================================
// Add this line:
//   singleton MprisService 1.0 MprisService.qml
