import QtQuick
import qs.DCommon.Common

StyledButton {
    id: root

    property string iconName: ""
    property int iconSize: Style.iconSizeMedium
    property color iconColor: Style.onSurfaceVariant
    property bool iconFilled: false
    property color backgroundColor: "transparent"
    property color stateColor: iconColor
    property bool circular: true
    property int buttonSize: Style.buttonHeightXS
    property var tooltipText: null
    property string tooltipSide: "bottom"
    property bool enableScaleAnimation: true
    property real pressScaleFactor: M3E.iconBtnPressScale
    property int shapeDuration: M3E.spatialFastMs
    property var shapeCurve: M3E.curveFastSpatial
    property int stateDuration: M3E.effectsFastMs
    property var stateCurve: M3E.curveFastEffects

    signal entered
    signal exited

    function showTooltip() {
        stateLayer.showTooltip();
    }

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    radius: Style.buttonRadius(width, height, buttonSize, pressed, circular)
    scale: (enableScaleAnimation && pressed) ? pressScaleFactor : 1.0
    color: enabled || backgroundColor.a === 0 ? backgroundColor : Style.onSurface_12
    Accessible.role: Accessible.Button
    Accessible.name: tooltipText || iconName

    Behavior on radius {
        enabled: !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DAnim {
            duration: root.shapeDuration
            easing.bezierCurve: root.shapeCurve
        }
    }

    Behavior on scale {
        enabled: root.enableScaleAnimation && !Style.reduceMotion && Style.currentAnimationSpeed !== Style.AnimationSpeed.None
        DAnim {
            duration: root.shapeDuration
            easing.bezierCurve: root.shapeCurve
        }
    }

    FocusRing {
        visible: root.visualFocus
        anchors.margins: Style.focusRingWidth / 2
        radius: Math.max(0, parent.radius - Style.focusRingWidth / 2)
    }

    DIcon {
        anchors.centerIn: parent
        name: root.iconName
        size: root.iconSize
        filled: root.iconFilled
        color: root.enabled ? root.iconColor : Style.onSurface_38
    }

    StateLayer {
        id: stateLayer
        control: root
        disabled: !root.enabled
        stateColor: root.stateColor
        transitionDuration: root.stateDuration
        transitionCurve: root.stateCurve
        onEntered: root.entered()
        onExited: root.exited()
        tooltipText: root.tooltipText
        tooltipSide: root.tooltipSide
    }
}
