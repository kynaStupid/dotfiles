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

	WlrLayershell.layer: WlrLayer.Top

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
			Behavior on bottomRightRadius { NumberAnimation { duration: Theme.animMorphDuration } }

			color: Globals.barColor
			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

			readonly property var borderGeometry: [
				{ type: "rectangle", item: statusBar }
			]

			HoverHandler {
				onHoveredChanged: {
					if (hovered)
						Globals.barEnter()
					else
						Globals.barExit()
				}
			}

			MouseArea {
				id: taskBarHotspot
				hoverEnabled: true
				anchors.left: statusBar.left
				anchors.top: statusBar.top
				anchors.bottom: statusBar.bottom
				width: Theme.barHeight
				preventStealing: false
				onEntered: Globals.expandTaskBar()
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

					MouseArea {
						id: mprisWidgetHotspot
						hoverEnabled: parent.visible
						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
						width: Theme.barHeight
						height: Theme.barHeight
						preventStealing: false
						onEntered: Globals.expandMprisWidget()
					}
				}
			}

			// center
			RowLayout {
				anchors.centerIn: parent
				anchors.leftMargin: statusBar.anchors.rightMargin
				anchors.rightMargin: statusBar.anchors.leftMargin
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

			HoverHandler {
				onHoveredChanged: {
					if (hovered)
						Globals.barEnter()
					else
						Globals.barExit()
				}
			}

			WheelHandler {
				onWheel: event => taskBarFlickable.scrollBy(event.angleDelta.y, false)
			}

			Flickable {
				id: taskBarFlickable
				anchors.fill: parent
				anchors.margins: Theme.barMargin
				clip: true

				contentWidth: width
				contentHeight: taskBarColumn.implicitHeight

				interactive: false

				flickableDirection: Flickable.VerticalFlick
				maximumFlickVelocity: 5000
				flickDeceleration: 1000
				boundsBehavior: Flickable.StopAtBounds

				readonly property real maxContentY: Math.max(0, contentHeight - height)
				property real rawOvershoot: 0
				readonly property real overshoot: {
					if (rawOvershoot === 0) return 0
					const sign = rawOvershoot < 0? -1: 1
					return sign * rubberBand(Math.abs(rawOvershoot), Theme.rubberBandDimension)
				}
				property real overshootVelocity: 0

				function rubberBand(x, d) {
					if (d <= 0) return 0
					return (x * d * Theme.rubberBandC) / (d + Theme.rubberBandC * x)
				}

				function scrollBy(deltaPixels, isActiveDrag) {
					if (rawOvershoot === 0 && overshootVelocity === 0) {
						const newY = contentY - deltaPixels
						if (newY < 0) {
							contentY = 0
							rawOvershoot = newY
							if (!isActiveDrag)
								overshootVelocity = -deltaPixels * 10
						} else if (newY > maxContentY) {
							contentY = maxContentY
							rawOvershoot = newY - maxContentY
							if (!isActiveDrag)
								overshootVelocity = -deltaPixels * 10
						} else {
							contentY = newY
						}
					} else if (isActiveDrag) {
						rawOvershoot -= deltaPixels
						overshootVelocity = 0
					} else {
						overshootVelocity -= deltaPixels * 10
					}
				}

				DragHandler {
					target: null
					xAxis.enabled: false
					yAxis.enabled: true

					property real prevTranslationY: 0

					onTranslationChanged: {
						taskBarFlickable.scrollBy(translation.y - prevTranslationY, true)
						prevTranslationY = translation.y
					}

					onActiveChanged: {
						if (active)
							prevTranslationY = translation.y
						else if (taskBarFlickable.overshoot !== 0)
							taskBarFlickable.overshootVelocity = -centroid.velocity.y
						else
							taskBarFlickable.flick(0, centroid.velocity.y)
					}
				}

				onFlickingChanged: {
					if (flicking && overshoot === 0 && (atYBeginning || atYEnd)) {
						cancelFlick()
						rawOvershoot = atYEnd? Number.MIN_VALUE: -Number.MIN_VALUE
						overshootVelocity = -verticalVelocity
					}
				}

				FrameAnimation {
					running: taskBarFlickable.rawOvershoot !== 0 || taskBarFlickable.overshootVelocity !== 0

					onTriggered: {
						const dt = frameTime
						const f = taskBarFlickable

						if (f.height <= 0) {
							f.rawOvershoot = 0
							f.overshootVelocity = 0
							return
						}

						const sign = f.rawOvershoot < 0 ? -1 : 1
						const t = Math.min(1, Math.abs(f.rawOvershoot) / f.height)
						const s = Theme.backS

						const backForce = Math.abs((s + 1) * t*t*t - s * t*t)
						const restoringAccel = -sign * backForce * Theme.springStrength * f.height

						f.overshootVelocity += restoringAccel * dt
						f.overshootVelocity *= Math.max(0, 1 - Theme.damping * dt)
						f.rawOvershoot += f.overshootVelocity * dt

						if (Math.abs(f.rawOvershoot) < 0.5 && Math.abs(f.overshootVelocity) < 5) {
							f.rawOvershoot = 0
							f.overshootVelocity = 0
						}
					}
				}

				Column {
					id: taskBarColumn
					anchors.left: parent.left
					anchors.right: parent.right
					y: -taskBarFlickable.overshoot
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
								preventStealing: false
								onClicked: mouse => {
									if (mouse.button === Qt.LeftButton) {
										modelData.activate()
									} else if (mouse.button === Qt.MiddleButton) {
										modelData.close()
									}
								}
								hoverEnabled: true
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

			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

			bottomLeftRadius: Theme.barRadius - Theme.borderWidth
			bottomRightRadius: Theme.barRadius - Theme.borderWidth
			color: Globals.barColor
		}
		InvertedCorner {
			id: mprisExpandedInvertedCornerLeft
			anchors.right: mprisExpandedRectangle.left
			anchors.top: statusBar.bottom

			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

			radius: Math.min(Theme.barRadius - Theme.borderWidth, mprisExpandedRectangle.height - Theme.barRadius)
			color: Globals.barColor
			corner: Qt.BottomLeftCorner
		}
		InvertedCorner {
			id: mprisExpandedInvertedCornerRight
			anchors.left: mprisExpandedRectangle.right
			anchors.top: statusBar.bottom

			opacity: Globals.barOpacity
			Behavior on opacity { NumberAnimation { duration: Theme.animFocusDuration } }

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
