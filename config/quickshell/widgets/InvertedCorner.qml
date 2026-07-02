// widgets/InvertedCorner.qml
import QtQuick
import Qt5Compat.GraphicalEffects

Item {
	id: root

	property real radius: 12
	property color color: "black"
	property int corner: Qt.TopLeftCorner // TopLeftCorner | TopRightCorner | BottomLeftCorner | BottomRightCorner
	property point maskPos: Qt.point(
		(root.corner === Qt.TopRightCorner || root.corner === Qt.BottomRightCorner)?
			0:
			-root.radius,
		(root.corner === Qt.BottomLeftCorner || root.corner === Qt.BottomRightCorner)?
			0:
			-root.radius
	)

	implicitWidth: radius
	implicitHeight: radius
	width: radius
	height: radius

	Item {
		id: maskCircle
		width: root.width
		height: root.height
		visible: false

		Rectangle {
			width: root.radius * 2
			height: root.radius * 2
			radius: width / 2
			color: "black"

			x: maskPos.x
			y: maskPos.y
		}
	}

	Item {
		anchors.fill: parent
		layer.enabled: true
		layer.smooth: true
		layer.effect: OpacityMask {
			maskSource: maskCircle
			invert: true
		}

		Rectangle {
			anchors.fill: parent
			color: root.color
		}
	}
}
