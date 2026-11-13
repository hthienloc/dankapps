pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    required property var modelData
    required property int index
    required property int listCount
    required property bool isDoneGroup
    readonly property int remIdx: modelData?.index ?? -1
    readonly property var rem: modelData?.item ?? null
    readonly property bool isOverdue: Boolean(!isDoneGroup && rem && rem.enabled && rem.completedDateKey !== ClockService._todayDateKey() && (rem.repeat || "none") === "none" && rem.date && (rem.date < ClockService._todayDateKey() || (rem.date === ClockService._todayDateKey() && (rem.hour * 60 + rem.minute) < (ClockService.now ? ClockService.now.getHours() * 60 + ClockService.now.getMinutes() : 0))))

    signal clicked

    width: parent?.width ?? 0
    implicitHeight: rowItem.implicitHeight
    height: implicitHeight
    clip: true

    function formatTimeDisp(hour, minute) {
        const use24 = SettingsData.use24HourClock;
        const m = String(minute).padStart(2, "0");
        if (use24)
            return `${String(hour).padStart(2, "0")}:${m}`;
        const hDisp = String(hour % 12 || 12);
        const meridiem = hour >= 12 ? "PM" : "AM";
        return `${hDisp}:${m} ${meridiem}`;
    }

    readonly property real swipeThreshold: 72
    readonly property real maxDragDistance: width * 0.4
    property real dragOffset: 0
    property bool isSwiping: false

    Behavior on dragOffset {
        enabled: !root.isSwiping && Theme.animationsEnabled
        NumberAnimation {
            duration: ClockMetrics.transitionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: ClockMetrics.curveFastSpatial
        }
    }

    // Action indicator backgrounds (revealed underneath when swiping)
    // Left action background (revealed when dragging right > 0): Complete / Incomplete toggle
    Rectangle {
        id: leftActionBg
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, root.dragOffset)
        visible: root.dragOffset > 0
        color: root.isDoneGroup ? Theme.surfaceContainerHighest : Theme.primary
        topLeftRadius: root.index === 0 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
        bottomLeftRadius: root.index === root.listCount - 1 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacingL
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS
            opacity: Math.min(1.0, root.dragOffset / root.swipeThreshold)

            DIcon {
                name: root.isDoneGroup ? "undo" : "check"
                size: Theme.iconSize
                color: root.isDoneGroup ? Theme.surfaceText : Theme.onPrimary
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.isDoneGroup ? "Unmark" : "Done"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightMedium
                color: root.isDoneGroup ? Theme.surfaceText : Theme.onPrimary
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // Right action background (revealed when dragging left < 0): Delete
    Rectangle {
        id: rightActionBg
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Math.max(0, -root.dragOffset)
        visible: root.dragOffset < 0
        color: Theme.error
        topRightRadius: root.index === 0 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
        bottomRightRadius: root.index === root.listCount - 1 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingL
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS
            opacity: Math.min(1.0, -root.dragOffset / root.swipeThreshold)

            StyledText {
                text: "Delete"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightMedium
                color: Theme.onError
                anchors.verticalCenter: parent.verticalCenter
            }

            DIcon {
                name: "delete"
                size: Theme.iconSize
                color: Theme.onError
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    ClockRow {
        id: rowItem
        x: root.dragOffset
        width: parent.width
        clickable: true
        iconName: root.isDoneGroup ? "check_circle" : (root.isOverdue ? "error_outline" : "today")
        accent: root.isDoneGroup ? "green" : (root.isOverdue ? "orange" : "blue")
        title: root.rem?.title || "Reminder"
        subtitle: root.isDoneGroup ? `Completed • ${ClockService.formatReminderSchedule(root.rem)}` : (root.isOverdue ? (root.rem.date === ClockService._todayDateKey() ? "Earlier today" : `Scheduled: ${ClockService.formatReminderSchedule(root.rem)}`) : ClockService.formatReminderSchedule(root.rem))
        subtitleColor: root.isOverdue ? Theme.error : Theme.surfaceVariantText
        isFirstInGroup: root.index === 0
        isLastInGroup: root.index === root.listCount - 1
        onClicked: root.clicked()

        leading: Rectangle {
            id: checkRect
            width: 24
            height: 24
            radius: 12
            border.width: root.isDoneGroup ? 0 : 1.5
            border.color: checkHover.hovered ? Theme.primary : Theme.outlineMedium
            color: root.isDoneGroup ? (checkHover.hovered ? Theme.withAlpha(Theme.primary, 0.8) : Theme.primary) : (checkHover.hovered ? Theme.withAlpha(Theme.primary, 0.15) : "transparent")
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }
            Behavior on border.color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }

            DIcon {
                visible: root.isDoneGroup
                anchors.centerIn: parent
                name: "check"
                size: 14
                color: Theme.onPrimary
            }

            HoverHandler {
                id: checkHover
                cursorShape: Qt.PointingHandCursor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ClockService.toggleReminder(root.remIdx, !root.isDoneGroup)
            }
        }

        trailing: Row {
            spacing: Theme.spacingS
            anchors.verticalCenter: parent.verticalCenter

            DIcon {
                visible: Boolean(root.rem?.important)
                name: "star"
                size: Theme.iconSizeSmall
                color: "#FFA726"
                anchors.verticalCenter: parent.verticalCenter
            }

            NumericText {
                text: root.rem ? root.formatTimeDisp(root.rem.hour, root.rem.minute) : ""
                font.pixelSize: Theme.fontSizeMedium
                font.weight: root.isDoneGroup ? Font.Normal : Font.Bold
                color: root.isDoneGroup ? Theme.surfaceVariantText : (root.isOverdue ? Theme.error : Theme.primary)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    DragHandler {
        id: swipeHandler
        target: null
        xAxis.enabled: true
        yAxis.enabled: false

        property real startX: 0

        onActiveChanged: {
            if (active) {
                root.isSwiping = true;
                startX = root.dragOffset;
            } else {
                root.isSwiping = false;
                const offset = root.dragOffset;
                if (offset > root.swipeThreshold) {
                    // Swiped Right -> Check/Uncheck toggle
                    root.dragOffset = 0;
                    ClockService.toggleReminder(root.remIdx, !root.isDoneGroup);
                } else if (offset < -root.swipeThreshold) {
                    // Swiped Left -> Delete reminder
                    root.dragOffset = 0;
                    ClockService.removeReminder(root.remIdx);
                } else {
                    // Snap back
                    root.dragOffset = 0;
                }
            }
        }

        onTranslationChanged: {
            if (!active) return;
            const raw = startX + translation.x;
            if (raw > root.maxDragDistance) {
                root.dragOffset = root.maxDragDistance + (raw - root.maxDragDistance) * 0.2;
            } else if (raw < -root.maxDragDistance) {
                root.dragOffset = -root.maxDragDistance + (raw + root.maxDragDistance) * 0.2;
            } else {
                root.dragOffset = raw;
            }
        }
    }
}
