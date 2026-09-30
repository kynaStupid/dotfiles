// services/NotificationService.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
	id: root

	property int popupTimeoutMs: 6000

	NotificationServer {
		id: server
		bodySupported: true
		imageSupported: true
		actionsSupported: true
		bodyMarkupSupported: true

		onNotification: notification => {
			notification.tracked = true
			root._popupIds = [ ...root._popupIds, notification.id ]
			root._popupIdsChanged()

			const timer = popupTimerComponent.createObject(root, { targetId: notification.id })
			timer.start()
		}
	}

	readonly property var allNotifications: server.trackedNotifications

	property var _popupIds: []

	function _removePopupId(id) {
		_popupIds = _popupIds.filter(i => i !== id)
	}

	Component {
		id: popupTimerComponent
		Timer {
			property int targetId
			interval: root.popupTimeoutMs
			repeat: false
			onTriggered: {
				root._removePopupId(targetId)
				destroy()
			}
		}
	}

	// --- grouping ---
	// groups: [{ appName, notifications: [Notification, ...] }]
	// order: most-recently-arrived group first; within a group, most
	// recent notification first.

	function _groupBy(list) {
		const order = []
		const byApp = {}
		for (let i = list.length - 1; i >= 0; i--) {
			const n = list[i]
			const key = n.appName || "Unknown"
			if (!byApp[key]) {
				byApp[key] = []
				order.push(key)
			}
			byApp[key].push(n)
		}
		return order.map(key => ({ appName: key, notifications: byApp[key] }))
	}

	readonly property var allGroups: _groupBy(allNotifications.values)

	readonly property var popupGroups: _groupBy(
		allNotifications.values.filter(n => _popupIds.includes(n.id))
	)

	readonly property int totalCount: allNotifications.values.length

	// --- actions ---

	function activate(notification) {
		// invoke the default action if the app declared one (conventionally
		// id "default"), else just dismiss. Looping manually rather than
		// using .find() since `actions` may be a QML list property, not
		// a plain JS array.
		let defaultAction = null
		for (let i = 0; i < notification.actions.length; i++) {
			if (notification.actions[i].identifier === "default") {
				defaultAction = notification.actions[i]
				break
			}
		}
		if (defaultAction)
			defaultAction.invoke()
		dismiss(notification)
	}

	function dismiss(notification) {
		_removePopupId(notification.id)
		notification.tracked = false
	}

	function dismissGroup(appName) {
		for (const n of allNotifications.values) {
			if ((n.appName || "Unknown") === appName)
				dismiss(n)
		}
	}

	function dismissAll() {
		for (const n of allNotifications.values)
			dismiss(n)
	}
}
