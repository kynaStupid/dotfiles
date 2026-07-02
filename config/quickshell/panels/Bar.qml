// panels/Bar.qml
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "../services"
import "../widgets"

PanelWindow {
	id: bar

	anchors.top: true
	anchors.left: true
	anchors.right: true

	implicitHeight: screen.height

	exclusionMode: ExclusionMode.Normal
	exclusiveZone: Globals.barHeight + Globals.barMargin + Globals.borderWidth*2

	color: "transparent"

	mask: Region {
		item: statusbar
		Region {
			item: taskbar
		}
	}

	Item {
		id: root

		anchors.fill: parent

		Border {
			id: border
			root: root

			geometry: ([]
				.concat(statusbar.borderGeometry)
				.concat(taskbar.borderGeometry)
			)
		}

		Rectangle {
			id: statusbar
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.topMargin: Globals.barMargin + Globals.borderWidth
			anchors.rightMargin: Globals.barMargin + Globals.borderWidth

			height: Globals.barHeight
			topRightRadius: Globals.barRadius
			bottomRightRadius: Globals.barRadius

			color: Globals.barColor
			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Globals.animFocusDuration } }

			readonly property var borderGeometry: [
				{ type: "rect", item: statusbar }
			]

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.statusbarHovered = true
				onExited: {
					Globals.statusbarHovered = false
					Globals.updateTaskbarVisible()
				}

				MouseArea {
					id: taskbarHotspot
					hoverEnabled: true
					anchors.left: parent.left
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					width: Globals.barHeight
					onEntered: Globals.taskbarVisible = true
				}
			}

			// left
			RowLayout {
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: Globals.barHeight + Globals.barMargin // clear hotspot
				spacing: Globals.barMargin

				Status.TrayWidget { anchorWindow: bar }
			}

			// center
			RowLayout {
				anchors.centerIn: parent
				anchors.leftMargin: Globals.barMargin/2 // center of screen instead of bar
				spacing: Globals.barMargin

				SystemStats.CpuWidget {}

				Simple.Clock {}

				SystemStats.MemWidget {}
			}

			// right
			RowLayout {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				anchors.rightMargin: Globals.barMargin
				spacing: Globals.barMargin

				Status.BatteryWidget {}
				Status.NetworkWidget {}
				Status.VolumeWidget {}
			}
		}

		Rectangle {
			id: taskbar
			anchors.top: statusbar.bottom
			anchors.left: parent.left

			width: Globals.taskbarVisible?
				Math.min(maxWidth, taskbarColumn.implicitWidth):
				0
			height: Globals.taskbarVisible?
				Math.min(maxHeight, taskbarColumn.implicitHeight + Globals.barMargin*2):
				0
			readonly property real maxWidth: 500
			readonly property real maxHeight: 500

			Behavior on width { NumberAnimation { duration: Globals.animMorphDuration; easing.type: Easing.OutCubic } }
			Behavior on height { NumberAnimation { duration: Globals.animMorphDuration; easing.type: Easing.OutCubic } }

			bottomRightRadius: Globals.barRadius
			color: Globals.barColor
			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Globals.animFocusDuration } }

			readonly property var borderGeometry: [
				{ type: "rect", item: taskbar },
				{ type: "invertedCorner", item: taskbarInvertedCornerLeft },
				{ type: "invertedCorner", item: taskbarInvertedCornerRight }
			]

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.taskbarHovered = true
				onExited: {
					Globals.taskbarHovered = false
					Globals.updateTaskbarVisible()
				}
			}

			Flickable {
				anchors.fill: parent
				//anchors.margins: Globals.barMargin
				contentWidth: taskbarColumn.implicitWidth
				contentHeight: taskbarColumn.implicitHeight
				clip: true
				boundsBehavior: Flickable.StopAtBounds

				Column {
					id: taskbarColumn
					anchors.fill: parent
					anchors.margins: Globals.barMargin
					spacing: Globals.barMargin

					readonly property real buttonWidth: {
						let widest = 0
						for (let i = 0; i < taskbarRepeater.count; i++) {
							const item = taskbarRepeater.itemAt(i)
							if (item)
								widest = Math.max(widest, item.contentWidth)
						}
						return widest
					}
	
					Repeater {
						id: taskbarRepeater
						model: ToplevelManager.toplevels

						delegate: Rectangle {
							required property var modelData // the Toplevel for this index

							readonly property real contentWidth:
								content.implicitWidth + Globals.barMargin * 2
			
							implicitWidth: taskbarColumn.buttonWidth
							implicitHeight: Globals.barWidth
							radius: Globals.barRadius
							color: modelData.activated? Mocha.surface0: "transparent"

							RowLayout {
								id: content
								anchors.left: parent.left
								anchors.verticalCenter: parent.verticalCenter
								spacing: Globals.barMargin

								IconImage {
									implicitSize: Globals.barWidth
									source: Quickshell.iconPath(modelData.appId)
								}

								Text {
									text: modelData.title || modelData.appId || "?"
									color: Mocha.text
									font.pixelSize: Globals.barTextSize
									elide: Text.ElideRight
								}
							}

							MouseArea {
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								acceptedButtons: Qt.LeftButton | Qt.MiddleButton
								onClicked: mouse => {
									if (mouse.button === Qt.LeftButton) {
										modelData.activate()
									} else if (mouse.button === Qt.MiddleButton) {
										modelData.close()
									}
								}
							}
						}
					}
				}
			}

			InvertedCorner {
				id: taskbarInvertedCornerLeft
				anchors.left: parent.left
				anchors.top: taskbar.bottom

				radius: Math.min(taskbar.height - Globals.barRadius, Globals.barRadius)
				color: Globals.barColor
				corner: Qt.BottomRightCorner
			}
			InvertedCorner {
				id: taskbarInvertedCornerRight
				anchors.left: taskbar.right
				anchors.top: taskbar.top

				radius: Math.min(taskbar.height - Globals.barRadius, Globals.barRadius)
				color: Globals.barColor
				corner: Qt.BottomRightCorner
			}
		}
	}
}
