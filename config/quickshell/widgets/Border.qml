// widgets/Border.qml
import QtQuick
import QtQuick.Shapes
import Quickshell
import Qt5Compat.GraphicalEffects
import "../services"
import "../widgets"

Item {
	property var geometry: []
	property Item root: null

	anchors.fill: parent
	
	Item {
		id: innerUnion
		anchors.fill: parent
		visible: false

		layer.enabled: true

		Repeater {
			model: geometry

			delegate: Loader {
				property var geom: modelData

				asynchronous: true
				active: geom.item.width > 0 && geom.item.height > 0

      		  	sourceComponent: modelData.type === "rect"?
					innerRectComponent:
					innerInvertedCornerComponent
			}
		}
	}

	Item {
		id: outerUnion
		anchors.fill: parent

		layer.enabled: true
		layer.smooth: true
		layer.effect: OpacityMask {
			maskSource: innerUnion
			invert: true
		}

		Repeater {
			model: geometry

			delegate: Loader {
				property var geom: modelData

				asynchronous: true
				//active: geom.item.width > 0 && geom.item.height > 0

      		  	sourceComponent: modelData.type === "rect"?
					outerRectComponent:
					outerInvertedCornerComponent
			}
		}
	}

	Component {
		id: innerRectComponent

		Rectangle {
			x: Globals.absoluteX(parent.geom.item, root)
			y: Globals.absoluteY(parent.geom.item, root)
			width: parent.geom.item.width
			height: parent.geom.item.height

			radius: parent.geom.item.radius
			topLeftRadius: parent.geom.item.topLeftRadius
			topRightRadius: parent.geom.item.topRightRadius
			bottomLeftRadius: parent.geom.item.bottomLeftRadius
			bottomRightRadius: parent.geom.item.bottomRightRadius

			color: "black"
		}
	}

	Component {
		id: innerInvertedCornerComponent

		Item {
			readonly property var _geom: parent.geom
			readonly property real _radius: _geom.item.radius
			readonly property int _corner: _geom.item.corner

			x: Globals.absoluteX(parent.geom.item, root)
			y: Globals.absoluteY(parent.geom.item, root)
			width: _radius
			height: _radius

    		rotation: {
        		switch (_corner) {
        		case Qt.TopLeftCorner:     return 180
        		case Qt.TopRightCorner:    return 270
        		case Qt.BottomRightCorner: return 0
        		case Qt.BottomLeftCorner:  return 90
        		}
    		}
    		transformOrigin: Item.Center

			Shape {
				anchors.fill: parent
    			antialiasing: true
				rotation: 180
				transformOrigin: Item.Center

    			ShapePath {
        			fillColor: "black"
        			strokeWidth: 0

        			startX: _radius
        			startY: 0

        			PathLine { x: width; y: 0 }
        			PathLine { x: width; y: height }
        			PathLine { x: 0; y: height }
        			PathLine { x: 0; y: _radius }

        			PathAngleArc {
            			centerX: 0
            			centerY: 0
            			radiusX: _radius
            			radiusY: _radius
            			startAngle: 90
            			sweepAngle: -90
						moveToStart: false
        			}
    			}
			}

			Rectangle {
				x: _geom.item.maskPos.x + Globals.borderWidth
				y: _geom.item.maskPos.y + Globals.borderWidth
				width: (_radius - Globals.borderWidth)*2
				height: (_radius - Globals.borderWidth)*2
				radius: _radius - Globals.borderWidth

				color: "black"
			}
		}
	}

	Component {
		id: outerRectComponent

		Rectangle {
			visible: parent.geom.item.width > 0 && parent.geom.item.height > 0

			x: Globals.absoluteX(parent.geom.item, root) - Globals.borderWidth
			y: Globals.absoluteY(parent.geom.item, root) - Globals.borderWidth
			width: parent.geom.item.width + Globals.borderWidth*2
			height: parent.geom.item.height + Globals.borderWidth*2

			radius: parent.geom.item.radius === 0? 0: parent.geom.item.radius + Globals.borderWidth
			topLeftRadius: parent.geom.item.topLeftRadius === 0? 0: parent.geom.item.topLeftRadius + Globals.borderWidth
			topRightRadius: parent.geom.item.topRightRadius === 0? 0: parent.geom.item.topRightRadius + Globals.borderWidth
			bottomLeftRadius: parent.geom.item.bottomLeftRadius === 0? 0: parent.geom.item.bottomLeftRadius + Globals.borderWidth
			bottomRightRadius: parent.geom.item.bottomRightRadius === 0? 0: parent.geom.item.bottomRightRadius + Globals.borderWidth

			color: Globals.borderColor
			Behavior on color { ColorAnimation { duration: 300 } }
		}
	}

	Component {
		id: outerInvertedCornerComponent

		Rectangle {
			visible: parent.geom.item.radius > 0

			x: Globals.absoluteX(parent.geom.item, root)
			y: Globals.absoluteY(parent.geom.item, root)
			width: parent.geom.item.width
			height: parent.geom.item.height

			color: Globals.borderColor
			Behavior on color { ColorAnimation { duration: 300 } }
		}
	}
}
