pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Common

Singleton {
    id: root

    readonly property real contentMaxWidth: 880
    readonly property real windowWidth: 960
    readonly property real windowHeight: 680
    readonly property real windowMinWidth: 560
    readonly property real windowMinHeight: 540
    readonly property real pagePaddingV: Theme.spacingXL + Theme.densityStepM
    readonly property real rowPaddingH: Theme.spacingL + Theme.spacingXS + Theme.densityStepS
    readonly property real rowPaddingV: Theme.spacingM + Theme.spacingXS + Theme.densityStepS
    readonly property real rowMinHeight: Math.max(Theme.listItemHeight + Theme.densityStepM, Theme.buttonHeightS + Theme.spacingXS)
    readonly property real rowMinHeightTwoLine: Theme.listItemTwoLineHeight + Theme.densityStepM
    readonly property real cardGap: Theme.spacingL + Theme.densityStepS
    readonly property real rowContentSpacing: Theme.spacingL
    readonly property real sectionLabelTopGap: Math.max(Theme.spacingXS, Theme.spacingS + Theme.densityStepS)
    readonly property real sectionLabelBottomGap: Theme.spacingM
    readonly property real navIconSize: Theme.avatarSize
    readonly property real disabledOpacity: 0.42
    readonly property real highlightBlend: 0.2
    readonly property color windowBgColor: Theme.surfaceContainerLowest
    readonly property color paneColor: Theme.surfaceContainerLow
    readonly property color rowColor: Theme.surfaceContainerHigh
    readonly property color rowHoverColor: Theme.surfaceContainerHighest
    readonly property color selectedRowColor: Theme.blend(rowColor, Theme.onSurface, Theme.stateLayerDrag)
    readonly property color elevatedCardColor: Theme.surfaceContainerHigh
    readonly property int transitionDuration: Theme.expressiveDurations.expressiveFastSpatial
    readonly property int fadeDuration: Theme.expressiveDurations.expressiveEffects
    readonly property var curveFastSpatial: Style.expressiveCurves?.expressiveFastSpatial ?? [0.42, 1.67, 0.21, 0.9, 1, 1]
    readonly property var curveDefaultSpatial: Style.expressiveCurves?.expressiveDefaultSpatial ?? [0.38, 1.21, 0.22, 1, 1, 1]
    readonly property var curveEffects: Style.expressiveCurves?.expressiveEffects ?? [0.34, 0.8, 0.34, 1, 1, 1]

    function cardRadius(pressed, hovered, active) {
        if (pressed)
            return Theme.cornerRadiusS;
        if (hovered || active)
            return Theme.cornerRadiusXL;
        return Theme.cornerRadiusL;
    }
}
