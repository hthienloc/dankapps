import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property string text: ""
    property string iconName: ""
    property color backgroundColor: Theme.surfaceContainerHigh
    property color textColor: Theme.surfaceText
    property real fontSize: -1
    property int fontWeight: (text.length <= 1 && text !== ".") ? Font.Medium : Font.Normal
    property real cornerRadius: Math.min(width, height) / 2
    property bool activeState: false
    property string tooltipText: ""

    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 28
    Layout.minimumHeight: 24

    readonly property real singleCharFontSize: Math.max(22, Math.min(36, Math.min(width * 0.45, height * 0.50)))
    readonly property real multiCharFontSize: text.length <= 2
        ? Math.max(16, Math.min(26, Math.min(width * 0.32, height * 0.42)))
        : Math.max(13, Math.min(22, Math.min(width * 0.24, height * 0.38)))

    readonly property real effectiveFontSize: fontSize > 0 ? fontSize : (text.length <= 1 ? singleCharFontSize : multiCharFontSize)
    readonly property real effectiveIconSize: Math.max(20, Math.min(34, Math.min(width * 0.36, height * 0.50)))

    function triggerBounce() {
        if (!Theme.reduceMotion) {
            bounceAnim.restart();
        }
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: stateLayer.pressed ? M3E.pressRadiusM : (root.activeState ? M3E.outerR : root.cornerRadius)
        color: root.activeState ? Theme.primaryContainer : root.backgroundColor
        scale: stateLayer.pressed ? M3E.iconBtnPressScale : 1.0

        Behavior on color {
            DColorAnim {
                duration: M3E.effectsFastMs
                easing.bezierCurve: M3E.curveFastEffects
            }
        }

        Behavior on radius {
            DAnim {
                duration: M3E.spatialFastMs
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }

        Behavior on scale {
            DAnim {
                duration: M3E.spatialFastMs
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }

        SequentialAnimation {
            id: bounceAnim
            NumberAnimation {
                target: bgRect
                property: "scale"
                to: 0.92
                duration: 60
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: bgRect
                property: "scale"
                to: 1.05
                duration: 120
                easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
            }
            NumberAnimation {
                target: bgRect
                property: "scale"
                to: 1.0
                duration: 90
                easing.type: Easing.OutQuad
            }
        }

        RowLayout {
            anchors.centerIn: parent
            spacing: 0

            DIcon {
                visible: root.iconName !== ""
                name: root.iconName
                size: root.effectiveIconSize
                color: root.activeState ? Theme.onPrimaryContainer : root.textColor
            }

            StyledText {
                visible: root.text !== ""
                text: root.text
                font.pixelSize: root.effectiveFontSize
                font.weight: root.fontWeight
                color: root.activeState ? Theme.onPrimaryContainer : root.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        StateLayer {
            id: stateLayer
            cornerRadius: bgRect.radius
            stateColor: root.textColor
            tooltipText: root.tooltipText
            onClicked: {
                root.triggerBounce();
                root.clicked();
            }
        }
    }
}
