// widgets/MprisWidget.qml
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../services"

Item {
	id: root

	component Compact: Item {
		id: compact

		property bool canVisible: true

		visible: MprisService.hasPlayers && canVisible
		implicitWidth: visible? layout.implicitWidth: 0
		implicitHeight: Globals.barHeight

		RowLayout {
			id: layout
			anchors.fill: parent
			spacing: Globals.barMargin

			// prev
			Text {
				text: "󰒮"
				color: MprisService.activePlayer?.canGoPrevious?
					Mocha.text: Mocha.surface2
				font.pointSize: Globals.barTextSize
				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: if (MprisService.activePlayer?.canGoPrevious)
						MprisService.activePlayer.previous()
				}
			}

			// play/pause
			Text {
				text: MprisService.activePlayer?.isPlaying? "󰏤": "󰐊"
				color: Mocha.text
				font.pointSize: Globals.barTextSize
				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: if (MprisService.activePlayer)
						MprisService.activePlayer.isPlaying =
							!MprisService.activePlayer.isPlaying
				}
			}

			// next
			Text {
				text: "󰒭"
				color: MprisService.activePlayer?.canGoNext?
					Mocha.text: Mocha.surface2
				font.pointSize: Globals.barTextSize
				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: if (MprisService.activePlayer?.canGoNext)
						MprisService.activePlayer.next()
				}
			}

			// title — artist, truncated
			Text {
				Layout.maximumWidth: 200
				text: {
					const p = MprisService.activePlayer
					if (!p) return ""
					const title = p.trackTitle || ""
					const artist = p.trackArtist || ""
					if (title && artist) return title + " — " + artist
					return title || artist || "Unknown"
				}
				color: Mocha.text
				font.pointSize: Globals.barTextSize
				elide: Text.ElideRight
			}
		}
	}

	component Expanded: Rectangle {
		id: expanded

		property real maxHeight: 400
		readonly property real cardHeight: 80
		readonly property real cardSpacing: Globals.barMargin
		readonly property real padding: Globals.barMargin

		implicitWidth: 300
		height: Globals.mprisWidgetVisible?
			Math.min(maxHeight,
				playerList.count * (cardHeight + cardSpacing) - cardSpacing + padding * 2
			):
			0

		Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

		color: "transparent"
		radius: Globals.barRadius
		opacity: Globals.barOpacity
		Behavior on opacity { NumberAnimation { duration: 300 } }

		clip: true

		MouseArea {
			anchors.fill: parent
			hoverEnabled: true
			onEntered: Globals.mprisWidgetHovered = true
			onExited: {
				Globals.mprisWidgetHovered = false
				Globals.updateWidgetsVisible()
			}
		}

		Flickable {
			anchors.fill: parent
			anchors.margins: expanded.padding
			contentHeight: column.implicitHeight
			clip: true
			boundsBehavior: Flickable.StopAtBounds

			Column {
				id: column
				width: parent.width
				spacing: expanded.cardSpacing

				Repeater {
					id: playerList
					model: MprisService.players
	
					delegate: Rectangle {
						id: card
						required property var modelData
						readonly property MprisPlayer player: modelData
	
						width: parent.width
						height: expanded.cardHeight
						radius: Globals.barRadius
						color: Mocha.surface0
	
						// position timer for smooth progress bar
						Timer {
							interval: 500
							running: card.player.isPlaying
							repeat: true
							onTriggered: card.player.positionChanged()
						}
	
						RowLayout {
							anchors.fill: parent
							anchors.margins: Globals.barMargin
							spacing: Globals.barMargin
	
							// album art
							Rectangle {
								width: expanded.cardHeight - Globals.barMargin * 2
								height: width
								radius: Globals.barRadius / 2
								color: Mocha.surface1
								clip: true
	
								Image {
									anchors.fill: parent
									source: card.player.trackArtUrl || ""
									fillMode: Image.PreserveAspectCrop
									smooth: true
									visible: card.player.trackArtUrl !== ""
									}
		
								// fallback icon when no art
								Text {
									anchors.centerIn: parent
									text: "󰎈"
									color: Mocha.overlay0
									font.pointSize: 24
									visible: card.player.trackArtUrl === ""
								}
							}

							// right side: title, artist, progress, controls
							ColumnLayout {
								Layout.fillWidth: true
								spacing: 2

								// title
								Text {
									Layout.fillWidth: true
									text: card.player.trackTitle || "Unknown"
									color: Mocha.text
									font.pointSize: Globals.barTextSize
									font.bold: true
									elide: Text.ElideRight
								}

								// artist
								Text {
									Layout.fillWidth: true
									text: card.player.trackArtist || ""
									color: Mocha.subtext0
									font.pointSize: Globals.barTextSize - 2
									elide: Text.ElideRight
								}

								// progress bar
								Item {
									Layout.fillWidth: true
									height: 4
									visible: card.player.lengthSupported

									Rectangle {
										anchors.fill: parent
										color: Mocha.surface2
										radius: 2
									}
									Rectangle {
										width: card.player.length > 0
											? parent.width * (card.player.position / card.player.length)
											: 0
										height: parent.height
										color: Mocha.accent
										radius: 2
									}
								}

								// controls
								RowLayout {
									spacing: Globals.barMargin
	
									Text {
										text: "󰒮"
										color: card.player.canGoPrevious
											? Mocha.text : Mocha.surface2
										font.pointSize: Globals.barTextSize
										MouseArea {
											anchors.fill: parent
											cursorShape: Qt.PointingHandCursor
											onClicked: if (card.player.canGoPrevious)
												card.player.previous()
										}
									}

									Text {
										text: card.player.isPlaying ? "󰏤" : "󰐊"
										color: Mocha.text
										font.pointSize: Globals.barTextSize + 2
											MouseArea {
											anchors.fill: parent
											cursorShape: Qt.PointingHandCursor
											onClicked: card.player.isPlaying = !card.player.isPlaying
										}
									}

									Text {
										text: "󰒭"
										color: card.player.canGoNext
											? Mocha.text : Mocha.surface2
										font.pointSize: Globals.barTextSize
										MouseArea {
											anchors.fill: parent
											cursorShape: Qt.PointingHandCursor
											onClicked: if (card.player.canGoNext)
												card.player.next()
										}
									}

									// player app name, small, right-aligned
									Item { Layout.fillWidth: true }
									Text {
										text: card.player.identity || ""
										color: Mocha.overlay0
										font.pointSize: Globals.barTextSize - 3
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
