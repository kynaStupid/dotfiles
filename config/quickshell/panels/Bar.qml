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

	WlrLayershell.layer: WlrLayer.Overlay

	anchors.top: true
	anchors.left: true
	anchors.right: true

	implicitHeight: screen.height

	exclusionMode: ExclusionMode.Normal
	exclusiveZone: Theme.barHeight + Theme.barMargin + Theme.borderWidth*2

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

			geometry: []
				.concat(statusBar.borderGeometry)
				.concat(taskBar.borderGeometry)
				.concat(mprisExpanded.borderGeometry)
		}

		Rectangle {
			id: statusBar
			anchors.top: parent.top
			anchors.left: parent.left
			anchors.right: parent.right
			anchors.topMargin: Theme.barMargin + Theme.borderWidth
			anchors.rightMargin: Theme.barMargin + Theme.borderWidth

			height: Theme.barHeight
			topRightRadius: Theme.barRadius - Theme.borderWidth
			bottomRightRadius: Theme.barRadius - Theme.borderWidth

			color: Globals.barColor
			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

			readonly property var borderGeometry: [
				{ type: "rectangle", item: statusBar }
			]

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.barEnter()
				onExited: Globals.barExit()

				MouseArea {
					id: taskBarHotspot
					hoverEnabled: true
					anchors.left: parent.left
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					width: Theme.barHeight
					onEntered: Globals.expandTaskBar()
				}

				MouseArea {
					id: mprisWidgetHotspot
					hoverEnabled: mprisCompact.visible
					anchors.top: parent.top
					anchors.bottom: parent.bottom
					x: Globals.absoluteX(mprisCompact, statusBar) + mprisCompact.width - width
					width: Theme.barHeight
					onEntered: Globals.expandMprisWidget()
				}
			}

			// left
			RowLayout {
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				anchors.leftMargin: Theme.barHeight + Theme.barMargin // clear hotspot
				spacing: Theme.barMargin

				Status.TrayWidget { anchorWindow: bar }

				MprisWidget.Compact {
					id: mprisCompact
					canVisible: !Globals.mprisWidgetVisible
				}
			}

			// center
			RowLayout {
				anchors.centerIn: parent
				anchors.leftMargin: Theme.barMargin/2 // center of screen instead of bar
				spacing: Theme.barMargin

				SystemStats.CpuWidget {}

				Simple.Clock {}

				SystemStats.MemWidget {}
			}

			// right
			RowLayout {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				anchors.rightMargin: Theme.barMargin
				spacing: Theme.barMargin

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
				Math.min(maxWidth, taskBarColumn.implicitWidth > 0? taskBarColumn.implicitWidth + Theme.barMargin*2: 0):
				0
			height: Globals.taskBarVisible?
				Math.min(maxHeight, taskBarColumn.implicitHeight > 0? taskBarColumn.implicitHeight + Theme.barMargin*2: 0):
				0
			readonly property real maxWidth: 500
			readonly property real maxHeight: 500

			Behavior on width { NumberAnimation { duration: Theme.animMorphDuration; easing.type: Easing.OutCubic } }
			Behavior on height { NumberAnimation { duration: Theme.animMorphDuration; easing.type: Easing.OutCubic } }

			bottomRightRadius: Theme.barRadius - Theme.borderWidth
			color: Globals.barColor
			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

			readonly property var borderGeometry: [
				{ type: "rectangle", item: taskBar },
				{ type: "invertedCorner", item: taskBarInvertedCornerLeft },
				{ type: "invertedCorner", item: taskBarInvertedCornerRight }
			]

			MouseArea {
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.barEnter()
				onExited: Globals.barExit()

				Flickable {
					anchors.fill: parent
					anchors.margins: Theme.barMargin
					//contentWidth: taskBarColumn.implicitWidth
					//contentHeight: taskBarColumn.implicitHeight
					clip: true
					boundsBehavior: Flickable.StopAtBounds

					Column {
						id: taskBarColumn
						anchors.fill: parent
						spacing: Theme.barMargin

						readonly property real buttonWidth: {
							let widest = 0
							let maxButtonWidth = taskBar.maxWidth - parent.anchors.margins*2
							for (let i = 0; i < taskBarRepeater.count; i++) {
								const item = taskBarRepeater.itemAt(i)
								if (item)
									widest = Math.max(widest, item.contentWidth)
								if (widest > maxButtonWidth)
									return maxButtonWidth
							}
							return widest
						}
	
						Repeater {
							id: taskBarRepeater
							model: ToplevelManager.toplevels

							delegate: Rectangle {
								required property var modelData // the Toplevel for this index

								readonly property real contentWidth:
									taskBarRepeaterContent.implicitWidth + Theme.barMargin * 2
			
								implicitWidth: taskBarColumn.buttonWidth - Theme.barMargin*2
								implicitHeight: Theme.barWidth
								radius: Theme.barRadius
								color: taskBarRepeaterContentMouseArea.containsMouse?
									Theme.surface1:
									modelData.activated? Theme.surface0: Qt.alpha(taskBar.color, 0)

								Behavior on color { ColorAnimation { duration: Theme.animFocusDuration } }

								RowLayout {
									id: taskBarRepeaterContent
									anchors.left: parent.left
									anchors.verticalCenter: parent.verticalCenter
									spacing: Theme.barMargin

									IconImage {
										implicitSize: Theme.barWidth
										source: Quickshell.iconPath(modelData.appId)
									}

									Text {
										Layout.fillWidth: true
										Layout.alignment: Qt.AlignVCenter

										text: modelData.title || modelData.appId || "?"
										color: Theme.text
										font.pointSize: Theme.barTextSize
										elide: Text.ElideRight
									}
								}

								MouseArea {
									id: taskBarRepeaterContentMouseArea
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
									hoverEnabled: true
									onEntered: Globals.barEnter()
									onExited: Globals.barExit()
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

				radius: Math.min(Theme.barRadius - Theme.borderWidth, taskBar.height - Theme.barRadius)
				color: Globals.barColor
				corner: Qt.BottomRightCorner
			}
			InvertedCorner {
				id: taskBarInvertedCornerRight
				anchors.left: taskBar.right
				anchors.top: taskBar.top

				radius: Math.min(Theme.barRadius - Theme.borderWidth, taskBar.height - Theme.barRadius)
				color: Globals.barColor
				corner: Qt.BottomRightCorner
			}
		}

		Rectangle {
			id: mprisExpandedRectangle
			anchors.top: statusBar.bottom
			anchors.left: mprisExpanded.left
			anchors.right: mprisExpanded.right
			height: mprisExpanded.height - statusBar.height

			bottomLeftRadius: Theme.barRadius - Theme.borderWidth
			bottomRightRadius: Theme.barRadius - Theme.borderWidth
			color: Globals.barColor
		}
		InvertedCorner {
			id: mprisExpandedInvertedCornerLeft
			anchors.right: mprisExpandedRectangle.left
			anchors.top: statusBar.bottom

			radius: Math.min(Theme.barRadius - Theme.borderWidth, mprisExpandedRectangle.height - Theme.barRadius)
			color: Globals.barColor
			corner: Qt.BottomLeftCorner
		}
		InvertedCorner {
			id: mprisExpandedInvertedCornerRight
			anchors.left: mprisExpandedRectangle.right
			anchors.top: statusBar.bottom

			radius: Math.min(Theme.barRadius - Theme.borderWidth, mprisExpandedRectangle.height - Theme.barRadius)
			color: Globals.barColor
			corner: Qt.BottomRightCorner
		}
		MprisWidget.Expanded {
			id: mprisExpanded
			anchors.top: statusBar.top
			x: Globals.absoluteX(mprisCompact, root)

			readonly property var borderGeometry: [
				{ type: "rectangle", item: mprisExpandedRectangle },
				{ type: "invertedCorner", item: mprisExpandedInvertedCornerLeft },
				{ type: "invertedCorner", item: mprisExpandedInvertedCornerRight }
			]

			visible: Globals.mprisWidgetVisible || height > 0

			MouseArea {
				z: -1
				anchors.fill: parent
				hoverEnabled: true
				onEntered: Globals.barEnter()
				onExited: Globals.barExit()
			}
		}
	}
}
