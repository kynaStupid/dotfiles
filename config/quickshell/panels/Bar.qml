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
		item: statusBar
		Region { item: taskBar }
		Region { item: mprisExpanded }
	}

	Item {
		id: root

		anchors.fill: parent

		Border {
			id: border
			root: root

			geometry: ([]
				.concat(statusBar.borderGeometry)
				.concat(taskBar.borderGeometry)
			)
		}

		Rectangle {
			id: statusBar
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
				{ type: "rect", item: statusBar }
			]

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.statusBarHovered = true
				onExited: {
					Globals.statusBarHovered = false
					Globals.updateWidgetsVisible()
				}

				MouseArea {
					id: taskBarHotspot
					hoverEnabled: true
					anchors.left: parent.left
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					width: Globals.barHeight
					onEntered: Globals.expandTaskBar()
				}

				/*MouseArea {
					id: mprisWidgetHotspot
					hoverEnabled: mprisCompact.visible
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					x: Globals.absoluteX(mprisCompact, statusBar) + mprisCompact.width - width
					width: Globals.barHeight
					onEntered: Globals.expandMprisWidget()
				}*/
			}

			// left
			RowLayout {
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: Globals.barHeight + Globals.barMargin // clear hotspot
				spacing: Globals.barMargin

				Status.TrayWidget { anchorWindow: bar }

				MprisWidget.Compact {
					id: mprisCompact
					canVisible: !Globals.mprisWidgetVisible
				}
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
			id: taskBar
			anchors.top: statusBar.bottom
			anchors.left: parent.left

			width: Globals.taskBarVisible?
				Math.min(maxWidth, taskBarColumn.implicitWidth):
				0
			height: Globals.taskBarVisible?
				Math.min(maxHeight, taskBarColumn.implicitHeight + Globals.barMargin*2):
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
				{ type: "rect", item: taskBar },
				{ type: "invertedCorner", item: taskBarInvertedCornerLeft },
				{ type: "invertedCorner", item: taskBarInvertedCornerRight }
			]

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.taskBarHovered = true
				onExited: {
					Globals.taskBarHovered = false
					Globals.updateWidgetsVisible()
				}
			}

			Flickable {
				anchors.fill: parent
				//anchors.margins: Globals.barMargin
				contentWidth: taskBarColumn.implicitWidth
				contentHeight: taskBarColumn.implicitHeight
				clip: true
				boundsBehavior: Flickable.StopAtBounds

				Column {
					id: taskBarColumn
					anchors.fill: parent
					anchors.margins: Globals.barMargin
					spacing: Globals.barMargin

					readonly property real buttonWidth: {
						let widest = 0
						for (let i = 0; i < taskBarRepeater.count; i++) {
							const item = taskBarRepeater.itemAt(i)
							if (item)
								widest = Math.max(widest, item.contentWidth)
						}
						return widest
					}
	
					Repeater {
						id: taskBarRepeater
						model: ToplevelManager.toplevels

						delegate: Rectangle {
							required property var modelData // the Toplevel for this index

							readonly property real contentWidth:
								content.implicitWidth + Globals.barMargin * 2
			
							implicitWidth: taskBarColumn.buttonWidth
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
									font.pointSize: Globals.barTextSize
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
				id: taskBarInvertedCornerLeft
				anchors.left: parent.left
				anchors.top: taskBar.bottom

				radius: Math.min(taskBar.height - Globals.barRadius, Globals.barRadius)
				color: Globals.barColor
				corner: Qt.BottomRightCorner
			}
			InvertedCorner {
				id: taskBarInvertedCornerRight
				anchors.left: taskBar.right
				anchors.top: taskBar.top

				radius: Math.min(taskBar.height - Globals.barRadius, Globals.barRadius)
				color: Globals.barColor
				corner: Qt.BottomRightCorner
			}
		}

		/*MprisWidget.Expanded {
			id: mprisExpanded
			anchors.top: statusBar.top
			x: Globals.absoluteX(mprisCompact, root)

			visible: Globals.mprisWidgetVisible || height > 0

			Rectangle {
				anchors.left: parent.left
				anchors.right: parent.right
				y: statusBar.height
				height: parent.height - statusBar.height

				bottomLeftRadius: Globals.barRadius
				bottomRightRadius: Globals.barRadius
				color: Globals.barColor
			}
		}*/
	}
}
