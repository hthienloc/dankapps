pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import qs.Common
import qs.DCommon.Widgets

T.Control {
    id: root

    readonly property bool isClockRow: true

    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.surfaceVariantText
    property string iconName: ""
    property string accent: ""
    property bool clickable: false
    property bool showChevron: false
    property string trailingBadge: ""
    property color trailingBadgeColor: Theme.surfaceVariantText
    property real paddingH: ClockMetrics.rowPaddingH
    property real paddingV: ClockMetrics.rowPaddingV
    property color rowColor: ClockMetrics.rowColor
    property color iconColor: Theme.primary
    property color titleColor: Theme.surfaceText
    property bool active: false

    default property alias trailing: trailingSlot.data
    property alias leading: leadingSlot.data
    property alias body: bodySlot.data

    readonly property bool hasBody: bodySlot.visibleChildren.length > 0
    readonly property bool hasText: title !== "" || subtitle !== ""
    property bool isFirstInGroup: edgeRow(true) === root
    property bool isLastInGroup: edgeRow(false) === root
    readonly property bool isRowHovered: rowHover.hovered || clickControl.hovered
    property real topRadius: clickControl.down ? Theme.cornerRadiusS : ((isFirstInGroup || isRowHovered || active) ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius)
    property real bottomRadius: clickControl.down ? Theme.cornerRadiusS : ((isLastInGroup || isRowHovered || active) ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius)
    readonly property real minHeight: subtitle !== "" ? ClockMetrics.rowMinHeightTwoLine : ClockMetrics.rowMinHeight

    Behavior on topRadius {
        enabled: Theme.animationsEnabled
        NumberAnimation {
            duration: ClockMetrics.transitionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ClockMetrics.curveFastSpatial
        }
    }

    Behavior on bottomRadius {
        enabled: Theme.animationsEnabled
        NumberAnimation {
            duration: ClockMetrics.transitionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ClockMetrics.curveFastSpatial
        }
    }

    readonly property var accentPair: accent !== "" ? Theme.accent(accent) : null
    readonly property color badgeColor: accentPair?.container ?? Theme.withAlpha(Theme.primary, Theme.tonalTintAlpha)
    readonly property color glyphColor: accentPair?.onContainer ?? root.iconColor

    signal clicked

    function edgeRow(first) {
        const siblings = parent?.visibleChildren;
        if (!siblings)
            return root;
        let last = null;
        for (let i = 0; i < siblings.length; i++) {
            const sibling = siblings[i];
            if (sibling.isClockRow !== true)
                continue;
            if (first)
                return sibling;
            last = sibling;
        }
        return last ?? root;
    }

    width: parent?.width ?? 0
    height: implicitHeight
    implicitHeight: paddingV * 2 + headerLine.height + (hasBody ? bodySlot.height + (headerLine.height > 0 ? Theme.spacingM : 0) : 0)

    HoverHandler {
        id: rowHover
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    Rectangle {
        anchors.fill: parent
        color: root.active ? ClockMetrics.selectedRowColor : (root.isRowHovered ? ClockMetrics.rowHoverColor : root.rowColor)
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius
        border.width: root.active ? Theme.outlineWidthFocused : Theme.layerOutlineWidth
        border.color: root.active ? Theme.primary : (root.isRowHovered ? Theme.outline : Theme.outlineMedium)

        Behavior on color {
            enabled: Theme.animationsEnabled
            ColorAnimation {
                duration: ClockMetrics.fadeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.expressiveCurves.expressiveEffects
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.clickable
        color: Theme.surfaceText
        opacity: !root.enabled ? 0 : (clickControl.down ? Theme.stateLayerPressed : (clickControl.hovered ? Theme.stateLayerHover : 0))
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius

        Behavior on opacity {
            enabled: Theme.animationsEnabled
            NumberAnimation {
                duration: ClockMetrics.fadeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.expressiveCurves.expressiveEffects
            }
        }
    }

    DRipple {
        id: ripple
        visible: root.clickable
        rippleColor: Theme.surfaceText
        topLeftRadius: root.topRadius
        topRightRadius: root.topRadius
        bottomLeftRadius: root.bottomRadius
        bottomRightRadius: root.bottomRadius
    }

    StyledButton {
        id: clickControl
        anchors.fill: parent
        enabled: root.clickable && root.enabled
        hoverEnabled: root.clickable
        focusPolicy: root.clickable ? Qt.StrongFocus : Qt.NoFocus
        background: null
        Accessible.ignored: !root.clickable
        Accessible.role: Accessible.Button
        Accessible.name: root.title + (root.subtitle ? ", " + root.subtitle : "")
        Accessible.onPressAction: {
            if (root.clickable && root.enabled)
                root.clicked();
        }
        onPressedChanged: {
            if (pressed && root.clickable)
                ripple.trigger(pressX, pressY);
        }
        onClicked: {
            if (root.clickable)
                root.clicked();
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: root.paddingV
        anchors.leftMargin: root.paddingH
        anchors.rightMargin: root.paddingH
        spacing: Theme.spacingM

        Item {
            id: headerLine
            visible: height > 0
            width: parent.width
            implicitHeight: Math.max(textColumn.implicitHeight, trailingArea.implicitHeight, leadingArea.visible ? leadingArea.implicitHeight : 0)
            height: Math.max(implicitHeight, (root.hasText || trailingSlot.children.length > 0 ? root.minHeight : 0) - root.paddingV * 2)

            Row {
                id: leadingArea
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingM
                visible: leadingSlot.children.length > 0 || root.iconName !== ""
                opacity: root.enabled ? 1 : ClockMetrics.disabledOpacity

                Row {
                    id: leadingSlot
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS
                    visible: children.length > 0
                }

                Rectangle {
                    width: ClockMetrics.navIconSize
                    height: ClockMetrics.navIconSize
                    radius: Theme.fullRadius(width, height)
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.badgeColor
                    visible: root.iconName !== ""

                    DIcon {
                        anchors.centerIn: parent
                        name: root.iconName
                        size: Theme.iconSizeMedium
                        color: root.glyphColor
                    }
                }
            }

            Column {
                id: textColumn
                anchors.left: leadingArea.visible ? leadingArea.right : parent.left
                anchors.leftMargin: leadingArea.visible ? Theme.spacingM : 0
                anchors.right: trailingArea.visible ? trailingArea.left : parent.right
                anchors.rightMargin: trailingArea.visible ? ClockMetrics.rowContentSpacing : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS
                opacity: root.enabled ? 1 : ClockMetrics.disabledOpacity
                visible: root.hasText

                StyledText {
                    width: parent.width
                    text: root.title
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Theme.fontWeightMedium
                    color: root.titleColor
                    wrapMode: Text.WordWrap
                    visible: root.title !== ""
                    horizontalAlignment: Text.AlignLeft
                }

                StyledText {
                    width: parent.width
                    text: root.subtitle
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.subtitleColor
                    wrapMode: Text.WordWrap
                    visible: root.subtitle !== ""
                    horizontalAlignment: Text.AlignLeft
                }
            }

            Row {
                id: trailingArea
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS
                visible: trailingSlot.children.length > 0 || root.showChevron || root.trailingBadge !== ""

                Row {
                    id: trailingSlot
                    spacing: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.trailingBadge
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.trailingBadgeColor
                    visible: root.trailingBadge !== ""
                    anchors.verticalCenter: parent.verticalCenter
                }

                DIcon {
                    name: "chevron_right"
                    size: Theme.iconSize
                    color: Theme.surfaceVariantText
                    visible: root.showChevron
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Column {
            id: bodySlot
            width: parent.width
            spacing: Theme.spacingM
        }
    }
}
