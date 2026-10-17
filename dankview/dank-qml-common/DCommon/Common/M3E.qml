pragma Singleton
import QtQuick
import Quickshell

/**
 * Shared Material 3 Expressive (M3E) design tokens and helpers for DankApps.
 *
 * Bridges DMS Style/Theme tokens with M3E connected group geometry, interactive
 * shape morphing, press scale physics, and spatial spring curves.
 */
Singleton {
    id: root

    // -------------------------------------------------------------------------
    // Motion Durations & Curves (with safe fallbacks)
    // -------------------------------------------------------------------------
    readonly property int spatialFastMs: Style.expressiveDurations?.expressiveFastSpatial ?? 350
    readonly property int spatialDefaultMs: Style.expressiveDurations?.expressiveDefaultSpatial ?? 500
    readonly property int spatialSlowMs: Style.expressiveDurations?.expressiveSlowSpatial ?? 650

    readonly property int effectsFastMs: Style.expressiveDurations?.expressiveFastEffects ?? 150
    readonly property int effectsMs: Style.expressiveDurations?.expressiveEffects ?? 200
    readonly property int effectsSlowMs: Style.expressiveDurations?.expressiveSlowEffects ?? 300

    readonly property var curveFastSpatial: Style.expressiveCurves?.expressiveFastSpatial ?? [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: Style.expressiveCurves?.expressiveDefaultSpatial ?? [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var curveSlowSpatial: Style.expressiveCurves?.expressiveSlowSpatial ?? [0.39, 1.29, 0.35, 0.98, 1, 1]

    readonly property var curveFastEffects: Style.expressiveCurves?.expressiveFastEffects ?? [0.31, 0.94, 0.34, 1, 1, 1]
    readonly property var curveEffects: Style.expressiveCurves?.expressiveEffects ?? [0.34, 0.8, 0.34, 1, 1, 1]
    readonly property var curveSlowEffects: Style.expressiveCurves?.expressiveSlowEffects ?? [0.34, 0.88, 0.34, 1, 1, 1]
    readonly property var curveEmphasizedDecel: Style.expressiveCurves?.emphasizedDecel ?? [0.05, 0.7, 0.1, 1, 1, 1]

    // -------------------------------------------------------------------------
    // Connected Group & Card Geometry
    // -------------------------------------------------------------------------
    readonly property real outerR: Style.cornerRadiusL
    readonly property real innerR: 6
    readonly property int groupGap: Style.spacingXXS

    readonly property real cardRadius: Style.cornerRadiusL
    readonly property real tileRadiusIdle: Style.cornerRadiusL
    readonly property real tileRadiusHover: Style.cornerRadiusXL
    readonly property real tileRadiusPress: Style.cornerRadiusS

    // -------------------------------------------------------------------------
    // Interactive Press Radii & Scales
    // -------------------------------------------------------------------------
    readonly property real pressRadiusXS: 6
    readonly property real pressRadiusS: Style.cornerRadiusS
    readonly property real pressRadiusM: Style.cornerRadiusM

    readonly property real tilePressScale: 0.96
    readonly property real rowPressScale: 0.97
    readonly property real iconBtnPressScale: 0.93

    // -------------------------------------------------------------------------
    // Shape Morphing Helpers
    // -------------------------------------------------------------------------

    /**
     * Computes top corner radius for an item in a vertical M3E connected group.
     */
    function topRadius(index, count, pressed, hovered, expanded, customPressR, customOuterR) {
        var pR = customPressR !== undefined ? customPressR : pressRadiusS;
        var oR = customOuterR !== undefined ? customOuterR : outerR;
        if (pressed) return pR;
        if (expanded || hovered) return oR;
        return index === 0 ? oR : innerR;
    }

    /**
     * Computes bottom corner radius for an item in a vertical M3E connected group.
     */
    function bottomRadius(index, count, pressed, hovered, expanded, customPressR, customOuterR) {
        var pR = customPressR !== undefined ? customPressR : pressRadiusS;
        var oR = customOuterR !== undefined ? customOuterR : outerR;
        if (pressed) return pR;
        if (expanded || hovered) return oR;
        return index === count - 1 ? oR : innerR;
    }

    /**
     * Computes left corner radius for an item in a horizontal M3E connected group.
     */
    function leftRadius(index, count, pillR, pressed, hovered, active, customPressR) {
        var pR = customPressR !== undefined ? customPressR : pressRadiusXS;
        if (pressed) return pR;
        if (active || hovered) return pillR;
        return index === 0 ? pillR : innerR;
    }

    /**
     * Computes right corner radius for an item in a horizontal M3E connected group.
     */
    function rightRadius(index, count, pillR, pressed, hovered, active, customPressR) {
        var pR = customPressR !== undefined ? customPressR : pressRadiusXS;
        if (pressed) return pR;
        if (active || hovered) return pillR;
        return index === count - 1 ? pillR : innerR;
    }

    /**
     * Computes interactive tile radius (idle -> hover pill -> press squircle).
     */
    function tileRadius(pressed, hovered, highlighted) {
        if (pressed) return tileRadiusPress;
        if (hovered || highlighted) return tileRadiusHover;
        return tileRadiusIdle;
    }
}
