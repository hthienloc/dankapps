pragma Singleton

import QtQuick
import Quickshell
import qs.DCommon.Common

Singleton {
    id: root

    readonly property int spatialFastMs: Style.expressiveDurations?.expressiveFastSpatial ?? 350
    readonly property int spatialDefaultMs: Style.expressiveDurations?.expressiveDefaultSpatial ?? 500
    readonly property int spatialSlowMs: Style.expressiveDurations?.expressiveSlowSpatial ?? 650

    readonly property int effectsFastMs: Style.expressiveDurations?.expressiveFastEffects ?? 150
    readonly property int effectsDefaultMs: Style.expressiveDurations?.expressiveEffects ?? 200
    readonly property int effectsMs: Style.expressiveDurations?.expressiveEffects ?? 200
    readonly property int effectsSlowMs: Style.expressiveDurations?.expressiveSlowEffects ?? 300

    readonly property var curveFastSpatial: Style.expressiveCurves?.expressiveFastSpatial ?? [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: Style.expressiveCurves?.expressiveDefaultSpatial ?? [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var curveSlowSpatial: Style.expressiveCurves?.expressiveSlowSpatial ?? [0.39, 1.29, 0.35, 0.98, 1, 1]

    readonly property var curveFastEffects: Style.expressiveCurves?.expressiveFastEffects ?? [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var curveDefaultEffects: Style.expressiveCurves?.expressiveDefaultEffects ?? [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveEffects: Style.expressiveCurves?.expressiveEffects ?? [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveSlowEffects: Style.expressiveCurves?.expressiveSlowEffects ?? [0.34, 0.88, 0.34, 1, 1, 1]
    readonly property var curveEmphasizedDecel: Style.expressiveCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]

    readonly property real outerR: Style.cornerRadiusL
    readonly property real innerR: 6
    readonly property int groupGap: Style.spacingXXS

    readonly property real cardRadius: Style.cornerRadiusL
    readonly property real tileRadiusIdle: Style.cornerRadiusL
    readonly property real tileRadiusHover: Style.cornerRadiusXL
    readonly property real tileRadiusPress: Style.cornerRadiusS

    readonly property real pressRadiusXS: 6
    readonly property real pressRadiusS: Style.cornerRadiusS
    readonly property real pressRadiusM: Style.cornerRadiusM

    readonly property real tilePressScale: 0.96
    readonly property real rowPressScale: 0.97
    readonly property real iconBtnPressScale: 0.93

    readonly property real strokeFaint: 0.12
    readonly property real strokeDivider: 0.20
    readonly property real strokeControl: 0.25
    readonly property real strokeSurface: 0.28
    readonly property real strokeCard: 0.35
    readonly property real strokePopup: 0.40

    readonly property real scrimSubtle: 0.30
    readonly property real scrimModal: 0.45
    readonly property real scrimOverlay: 0.55
    readonly property real scrimHeavy: 0.70

    readonly property real stateHover: 0.08
    readonly property real stateFocus: 0.10
    readonly property real statePressed: 0.12
    readonly property real stateSelected: 0.15
    readonly property real stateDragged: 0.16

    function stroke(baseColor, alpha) {
        const opacity = alpha !== undefined ? alpha : strokeCard;
        if (!baseColor)
            return Qt.rgba(0, 0, 0, opacity);
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, opacity);
    }

    function topRadius(index, count, pressed, hovered, expanded, customPressR, customOuterR) {
        const pressRadius = customPressR !== undefined ? customPressR : pressRadiusS;
        const outerRadius = customOuterR !== undefined ? customOuterR : outerR;
        if (pressed)
            return pressRadius;
        if (expanded || hovered)
            return outerRadius;
        return index === 0 ? outerRadius : innerR;
    }

    function bottomRadius(index, count, pressed, hovered, expanded, customPressR, customOuterR) {
        const pressRadius = customPressR !== undefined ? customPressR : pressRadiusS;
        const outerRadius = customOuterR !== undefined ? customOuterR : outerR;
        if (pressed)
            return pressRadius;
        if (expanded || hovered)
            return outerRadius;
        return index === count - 1 ? outerRadius : innerR;
    }

    function leftRadius(index, count, pillR, pressed, hovered, active, customPressR) {
        const pressRadius = customPressR !== undefined ? customPressR : pressRadiusXS;
        if (pressed)
            return pressRadius;
        if (active || hovered)
            return pillR;
        return index === 0 ? pillR : innerR;
    }

    function rightRadius(index, count, pillR, pressed, hovered, active, customPressR) {
        const pressRadius = customPressR !== undefined ? customPressR : pressRadiusXS;
        if (pressed)
            return pressRadius;
        if (active || hovered)
            return pillR;
        return index === count - 1 ? pillR : innerR;
    }

    function tileRadius(pressed, hovered, highlighted) {
        if (pressed)
            return tileRadiusPress;
        if (hovered || highlighted)
            return tileRadiusHover;
        return tileRadiusIdle;
    }
}