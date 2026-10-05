// widgets/Notifications.qml
//
// Compact: bell icon + unread badge, for the statusbar.
// Expanded: the panel itself. Shows popupGroups when NOT hovering the bell
// (i.e. floating-toast behavior driven by arrival) OR allGroups when the
// center is explicitly opened (Globals.notificationCenterVisible), plus
// search + dismiss-all utility row in center mode.
//
// Per spec:
//   - click a notification's text -> activate()
//   - middle-click a notification's text -> dismiss just that one
//   - middle-click the app-name header -> dismiss the whole group
//   - swipe (drag) a notification sideways past a threshold -> dismiss it
//   - swipe the app-name header -> dismiss the whole group
//
// NOTE: this is NOT a standalone PanelWindow. It's designed to be embedded
// as a Rectangle-equivalent inside Bar.qml's existing root Item, alongside
// statusBar/taskBar, participating in the same mask/Border system as
// everything else (see wiring notes at the bottom of this file).
//
// The "emerge from the bar with water droplets" visual is NOT implemented
// here -- that's real shader/particle work, out of scope for this pass.
// What IS implemented: a slide-down-and-fade entrance, the closest
// reasonable approximation without that extra effort.

import QtQuick
import QtQuick.Layouts
import "../services"

Item {
	id: root

	component Compact: Item {
		id: compact
		property bool canVisible: true

		visible: canVisible
		implicitWidth: Theme.barHeight
		implicitHeight: Theme.barHeight

		readonly property int count: NotificationService.totalCount

		Text {
			anchors.centerIn: parent
			text: compact.count > 0? "󱅫": "󰂚"
			color: Theme.text
			font.pointSize: Theme.barTextSize
		}

		/*Rectangle {
			visible: compact.count > 0
			anchors.top: parent.top
			anchors.right: parent.right
			width: 14
			height: 14
			radius: Theme.barRadius
			color: Theme.accent

			Text {
				anchors.centerIn: parent
				text: compact.count > 9? "9+": compact.count
				color: Theme.base
				font.pointSize: Theme.barTextSize - 4
				font.bold: true
			}
		}*/
	}

	// A single notification row within a group bubble.
	component NotificationRow: Item {
		id: row
		required property var notification

		implicitHeight: rowText.implicitHeight + Theme.barMargin
		width: parent? parent.width: 0

		property real dragX: 0
		readonly property real dismissThreshold: width * 0.35

		x: dragX
		opacity: 1 - Math.min(1, Math.abs(dragX) / width) * 0.7

		Text {
			id: rowText
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.verticalCenter: parent.verticalCenter
			text: row.notification.body || row.notification.summary || ""
			color: Theme.text
			font.pointSize: Theme.barTextSize - 1
			wrapMode: Text.Wrap
			maximumLineCount: 3
			elide: Text.ElideRight
			textFormat: Text.PlainText
		}

		MouseArea {
			anchors.fill: parent
			acceptedButtons: Qt.LeftButton | Qt.MiddleButton
			drag.target: row
			drag.axis: Drag.XAxis
			drag.minimumX: -row.width
			drag.maximumX: row.width

			onClicked: mouse => {
				if (mouse.button === Qt.MiddleButton) {
					NotificationService.dismiss(row.notification)
				} else if (Math.abs(row.dragX) < 4) {
					NotificationService.activate(row.notification)
				}
			}

			onReleased: {
				if (Math.abs(row.dragX) > row.dismissThreshold) {
					NotificationService.dismiss(row.notification)
				} else {
					row.dragX = 0
				}
			}
		}
	}

	// One bubble per app: header (app name) + stacked NotificationRows.
	component GroupBubble: Rectangle {
		id: bubble
		required property var group // { appName, notifications: [...] }

		width: parent ? parent.width : 0
		implicitHeight: bubbleContent.implicitHeight + Theme.barMargin * 2
		radius: Theme.barRadius
		color: Theme.surface0

		property real dragX: 0
		x: dragX
		opacity: 1 - Math.min(1, Math.abs(dragX) / width) * 0.7

		ColumnLayout {
			id: bubbleContent
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.margins: Theme.barMargin
			anchors.verticalCenter: parent.verticalCenter
			spacing: 4

			RowLayout {
				id: header
				Layout.fillWidth: true
				spacing: Theme.barMargin

				Image {
					readonly property var firstNotif: bubble.group.notifications[0]
					visible: firstNotif && firstNotif.appIcon !== ""
					source: firstNotif ? firstNotif.appIcon : ""
					Layout.preferredWidth: 20
					Layout.preferredHeight: 20
					fillMode: Image.PreserveAspectFit
				}

				Text {
					Layout.fillWidth: true
					text: bubble.group.appName
					color: Theme.subtext0
					font.pointSize: Theme.barTextSize - 1
					font.bold: true
					elide: Text.ElideRight
				}

				Text {
					visible: bubble.group.notifications.length > 1
					text: bubble.group.notifications.length
					color: Theme.overlay0
					font.pointSize: Theme.barTextSize - 2
				}
			}

			Repeater {
				model: bubble.group.notifications
				delegate: NotificationRow {
					required property var modelData
					notification: modelData
					Layout.fillWidth: true
				}
			}
		}

		// header drag/dismiss handling, sized to just the header row so
		// it doesn't eat clicks meant for NotificationRows below it.
		MouseArea {
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.top: parent.top
			height: header.height + Theme.barMargin
			acceptedButtons: Qt.LeftButton | Qt.MiddleButton
			drag.target: bubble
			drag.axis: Drag.XAxis
			drag.minimumX: -bubble.width
			drag.maximumX: bubble.width

			onClicked: mouse => {
				if (mouse.button === Qt.MiddleButton)
					NotificationService.dismissGroup(bubble.group.appName)
			}

			onReleased: {
				if (Math.abs(bubble.dragX) > bubble.width * 0.35) {
					NotificationService.dismissGroup(bubble.group.appName)
				} else {
					bubble.dragX = 0
				}
			}
		}
	}

	component Expanded: Rectangle {
		id: expanded

		property real maxHeight: 500
		readonly property real padding: Theme.barMargin
		readonly property bool centerMode: Globals.notificationCenterVisible

		readonly property var groups: centerMode?
			NotificationService.allGroups:
			NotificationService.popupGroups

		readonly property var filteredGroups: {
			if (!centerMode || realSearchInput.text === "")
				return groups
			const q = realSearchInput.text.toLowerCase()
			return groups
				.map(g => ({
					appName: g.appName,
					notifications: g.notifications.filter(n =>
						(n.summary || "").toLowerCase().includes(q) ||
						(n.body || "").toLowerCase().includes(q) ||
						g.appName.toLowerCase().includes(q))
				}))
				.filter(g => g.notifications.length > 0)
		}

		implicitWidth: 320
		height: (Globals.notificationCenterVisible || groups.length > 0)?
			Math.min(maxHeight, column.implicitHeight + padding * 2):
			0

		Behavior on height { NumberAnimation { duration: Theme.animMorphDuration; easing.type: Easing.OutCubic } }

		color: Globals.barColor
		opacity: Globals.barOpacity
		Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

		clip: true

		Flickable {
			anchors.fill: parent
			anchors.margins: expanded.padding
			contentHeight: column.implicitHeight
			clip: true
			boundsBehavior: Flickable.StopAtBounds

			Column {
				id: column
				width: parent.width
				spacing: Theme.barMargin

				RowLayout {
					visible: expanded.centerMode
					width: parent.width
					spacing: Theme.barMargin

					Rectangle {
						Layout.fillWidth: true
						implicitHeight: 28
						radius: Theme.barRadius
						color: Theme.surface1

						Text {
							anchors.left: parent.left
							anchors.leftMargin: 8
							anchors.verticalCenter: parent.verticalCenter
							text: "󰍉"
							color: Theme.subtext0
							font.pointSize: Theme.barTextSize - 1
						}
						TextInput {
							id: realSearchInput
							anchors.left: parent.left
							anchors.right: parent.right
							anchors.leftMargin: 26
							anchors.rightMargin: 8
							anchors.verticalCenter: parent.verticalCenter
							color: Theme.text
							font.pointSize: Theme.barTextSize - 1
							clip: true
						}
					}

					Rectangle {
						implicitWidth: dismissAllText.implicitWidth + 16
						implicitHeight: 28
						radius: Theme.barRadius
						color: dismissAllArea.containsMouse ? Theme.surface2 : Theme.surface1

						Text {
							id: dismissAllText
							anchors.centerIn: parent
							text: "Dismiss all"
							color: Theme.text
							font.pointSize: Theme.barTextSize - 1
						}
						MouseArea {
							id: dismissAllArea
							anchors.fill: parent
							hoverEnabled: true
							cursorShape: Qt.PointingHandCursor
							onClicked: NotificationService.dismissAll()
						}
					}
				}

				Text {
					visible: expanded.filteredGroups.length === 0
					width: parent.width
					horizontalAlignment: Text.AlignHCenter
					text: "No notifications"
					color: Theme.subtext0
					font.pointSize: Theme.barTextSize
					topPadding: 20
				}

				Repeater {
					model: expanded.filteredGroups
					delegate: GroupBubble {
						required property var modelData
						group: modelData
						width: column.width

						opacity: 0
						y: -20
						Component.onCompleted: {
							opacity = 1
							y = 0
						}
						Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }
						Behavior on y { NumberAnimation { duration: Theme.animFocusDuration; easing.type: Easing.OutCubic } }
					}
				}
			}
		}
	}
}
