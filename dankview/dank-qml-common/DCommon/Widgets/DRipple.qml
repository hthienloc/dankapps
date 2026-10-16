import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property color rippleColor: Style.primary
    property real cornerRadius: 0
    property real topLeftRadius: cornerRadius
    property real topRightRadius: cornerRadius
    property real bottomLeftRadius: cornerRadius
    property real bottomRightRadius: cornerRadius
    property bool enableRipple: Style.enableRippleEffects
    property int animationDuration: Style.expressiveDurations.expressiveDefaultSpatial

    property Item fxItem: null
    readonly property bool animating: fxItem?.animating ?? false

    anchors.fill: parent

    function trigger(x, y) {
        if (!enableRipple || Style.reduceMotion || Style.currentAnimationSpeed === Style.AnimationSpeed.None)
            return;
        if (!fxItem)
            fxItem = fxComponent.createObject(root);
        fxItem.trigger(x, y);
    }

    Component {
        id: fxComponent

        Item {
            id: fx
            anchors.fill: parent

            property real rippleX: 0
            property real rippleY: 0
            property real rippleMaxRadius: 0
            readonly property alias animating: rippleAnim.running

            function trigger(x, y) {
                rippleX = x;
                rippleY = y;
                const dist = (ox, oy) => ox * ox + oy * oy;
                rippleMaxRadius = Math.sqrt(Math.max(dist(x, y), dist(x, height - y), dist(width - x, y), dist(width - x, height - y)));
                rippleAnim.restart();
            }

            SequentialAnimation {
                id: rippleAnim

                PropertyAction {
                    target: rippleFx
                    property: "rippleCenterX"
                    value: fx.rippleX
                }
                PropertyAction {
                    target: rippleFx
                    property: "rippleCenterY"
                    value: fx.rippleY
                }
                PropertyAction {
                    target: rippleFx
                    property: "rippleRadius"
                    value: 0
                }
                PropertyAction {
                    target: rippleFx
                    property: "rippleOpacity"
                    value: 0.10
                }

                ParallelAnimation {
                    DAnim {
                        target: rippleFx
                        property: "rippleRadius"
                        from: 0
                        to: fx.rippleMaxRadius
                        duration: root.animationDuration
                        easing.bezierCurve: Style.expressiveCurves.standardDecel
                    }
                    SequentialAnimation {
                        PauseAnimation {
                            duration: Math.round(root.animationDuration * 0.6)
                        }
                        DAnim {
                            target: rippleFx
                            property: "rippleOpacity"
                            to: 0
                            duration: root.animationDuration
                            easing.bezierCurve: Style.expressiveCurves.standard
                        }
                    }
                }
            }

            ShaderEffect {
                id: rippleFx
                visible: rippleAnim.running

                property real rippleCenterX: 0
                property real rippleCenterY: 0
                property real rippleRadius: 0
                property real rippleOpacity: 0

                x: Math.max(0, rippleCenterX - rippleRadius)
                y: Math.max(0, rippleCenterY - rippleRadius)
                width: Math.max(0, Math.min(fx.width, rippleCenterX + rippleRadius) - x)
                height: Math.max(0, Math.min(fx.height, rippleCenterY + rippleRadius) - y)

                property real widthPx: width
                property real heightPx: height
                property vector4d cornerRadiiPx: Qt.vector4d(root.topLeftRadius, root.topRightRadius, root.bottomRightRadius, root.bottomLeftRadius)
                property real offsetX: x
                property real offsetY: y
                property real parentWidth: fx.width
                property real parentHeight: fx.height
                property vector4d rippleCol: Qt.vector4d(root.rippleColor.r, root.rippleColor.g, root.rippleColor.b, root.rippleColor.a)

                fragmentShader: Qt.resolvedUrl("../Shaders/qsb/ripple.frag.qsb")
            }
        }
    }
}
