pragma Singleton

import QtQuick
import Quickshell
import qs.Common

Singleton {
    readonly property real sidebarWidth: 310
    readonly property real compactBreakpoint: 700
    readonly property real contentMaxWidth: 720
    readonly property real paneMaxWidth: contentMaxWidth + panePadding * 2
    readonly property real pagePaddingH: 32
    readonly property real pagePaddingV: 24
    readonly property real paneMargin: Theme.spacingL
    readonly property real panePadding: Theme.spacingL
    readonly property real focusGutter: Theme.focusRingOffset + Theme.focusRingWidth
    readonly property real paneRadius: Theme.cornerRadiusL
    readonly property real rowPaddingH: 20
    readonly property real rowPaddingV: 16
    readonly property real rowContentSpacing: Theme.spacingL
    readonly property real sectionLabelTopGap: Theme.spacingS
    readonly property real sectionLabelBottomGap: Theme.spacingM
    readonly property real navIconSize: Theme.avatarSize
    readonly property real navItemMinHeight: Theme.listItemHeight
    readonly property real sidebarGroupGap: Theme.spacingS
    readonly property real buttonGroupCompactThreshold: 200
    readonly property real disabledOpacity: 0.38
    readonly property real highlightBlend: 0.2
    readonly property real activeHintAlpha: 0.8
    readonly property color windowBgColor: Theme.surfaceContainerLowest
    readonly property color paneColor: Theme.surfaceContainerLow
    readonly property color sidebarRowColor: Theme.surfaceContainerLow
    readonly property color rowColor: Theme.surfaceContainerHigh
    readonly property color selectedRowColor: Theme.secondaryContainer
    readonly property color rowHighlightColor: Theme.withAlpha(Theme.primary, highlightBlend)
    readonly property int transitionDuration: Theme.expressiveDurations.expressiveFastSpatial
    readonly property int fadeDuration: Theme.expressiveDurations.expressiveEffects
}
