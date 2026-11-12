pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

    // Drag preview state: the model is only reordered on release so delegates survive the gesture.
    property int draggingAlarmIndex: -1
    property int dropTargetAlarmIndex: -1

    // Slot an alarm is shown in while another alarm is being dragged over the grid.
    function previewSlot(i) {
        const from = draggingAlarmIndex;
        const to = dropTargetAlarmIndex;
        if (from < 0 || to < 0 || i === from)
            return i;
        if (from < to && i > from && i <= to)
            return i - 1;
        if (from > to && i >= to && i < from)
            return i + 1;
        return i;
    }

    readonly property var dayItems: [
        { key: "Sun", letter: "S" },
        { key: "Mon", letter: "M" },
        { key: "Tue", letter: "T" },
        { key: "Wed", letter: "W" },
        { key: "Thu", letter: "T" },
        { key: "Fri", letter: "F" },
        { key: "Sat", letter: "S" }
    ]

    readonly property var repeatPresets: [
        { label: "Weekdays", days: ["Mon", "Tue", "Wed", "Thu", "Fri"] },
        { label: "Weekends", days: ["Sat", "Sun"] },
        { label: "Every day", days: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"] },
        { label: "One-time", days: [] }
    ]

    DFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        interactive: root.draggingAlarmIndex < 0
        contentWidth: width
        contentHeight: contentCol.height + ClockMetrics.pagePaddingV + Theme.spacingXL * 4

        Column {
            id: contentCol
            topPadding: Theme.spacingL
            width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ClockMetrics.cardGap

            // Vacation Mode Banner (when Vacation Mode is Active)
            DCard {
                id: vacationBanner
                visible: ClockService.isVacationActive
                width: parent.width
                height: vacationInner.implicitHeight + pad * 2
                pad: Theme.spacingL
                tone: "tertiary"
                clickable: true
                restRadius: Theme.cornerRadiusXL
                bodyRadius: ClockMetrics.cardRadius(focusTarget.pressed, focusTarget.hovered, false)
                onClicked: ClockService.vacationSheetOpen = true

                Row {
                    id: vacationInner
                    width: parent.width
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 48
                        height: 48
                        radius: Theme.cornerRadiusXL
                        color: Theme.tertiary
                        anchors.verticalCenter: parent.verticalCenter

                        DIcon {
                            anchors.centerIn: parent
                            name: "beach_access"
                            size: Theme.iconSize
                            color: Theme.onTertiary
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        width: Math.max(0, parent.width - 48 - Theme.spacingM - (vacationActionsRow.visible ? vacationActionsRow.width + Theme.spacingM : 0))

                        Row {
                            spacing: Theme.spacingS
                            DBadge {
                                text: "VACATION MODE"
                                color: Theme.tertiary
                                textColor: Theme.onTertiary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                text: ClockService.formatVacationRange(ClockService.vacation)
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightBold
                                color: vacationBanner.contentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            text: "All alarms are silenced during your vacation"
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Theme.fontWeightBold
                            color: vacationBanner.contentColor
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Row {
                        id: vacationActionsRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DButton {
                            text: "Adjust"
                            iconName: "edit"
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.surfaceContainerHighest
                            textColor: Theme.surfaceText
                            onClicked: ClockService.vacationSheetOpen = true
                        }

                        DButton {
                            text: "Turn Off"
                            iconName: "close"
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.errorContainer
                            textColor: Theme.onErrorContainer
                            onClicked: ClockService.disableVacationMode()
                        }
                    }
                }
            }

            // Incoming Alarm Notice Banner (Android Clock M3E Expressive Hero)
            DCard {
                id: incomingCard
                visible: ClockService.nextIncomingAlarm !== null
                width: parent.width
                height: incomingInner.implicitHeight + pad * 2
                pad: Theme.spacingL
                tone: "primary"
                clickable: true
                restRadius: Theme.cornerRadiusXL
                bodyRadius: ClockMetrics.cardRadius(focusTarget.pressed, focusTarget.hovered, false)
                onClicked: {
                    const inc = ClockService.nextIncomingAlarm;
                    if (inc)
                        ClockService.openEditAlarmPicker(inc.index);
                }

                Row {
                    id: incomingInner
                    width: parent.width
                    spacing: Theme.spacingM

                    Rectangle {
                        width: 48
                        height: 48
                        radius: Theme.cornerRadiusXL
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        DIcon {
                            anchors.centerIn: parent
                            name: (ClockService.nextIncomingAlarm && ClockService.nextIncomingAlarm.alarm.soundId === "silent") ? "notifications_off" : "notifications_active"
                            size: Theme.iconSize
                            color: Theme.onPrimary
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        width: Math.max(0, parent.width - 48 - Theme.spacingM - (bannerActionsRow.visible ? bannerActionsRow.width + Theme.spacingM : 0))

                        Row {
                            spacing: Theme.spacingS
                            DBadge {
                                text: "NEXT ALARM"
                                color: Theme.primary
                                textColor: Theme.onPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                readonly property var inc: ClockService.nextIncomingAlarm
                                text: inc ? inc.relativeText : ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightBold
                                color: incomingCard.contentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            readonly property var inc: ClockService.nextIncomingAlarm
                            text: inc ? `${inc.timeText}  •  ${inc.alarm.label || "Alarm"} (${inc.dayRelation})` : ""
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Theme.fontWeightBold
                            color: incomingCard.contentColor
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Row {
                        id: bannerActionsRow
                        visible: ClockService.nextIncomingAlarm !== null
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DButton {
                            text: "Skip next"
                            iconName: "event_busy"
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.surfaceContainerHigh
                            textColor: Theme.surfaceText
                            onClicked: {
                                const inc = ClockService.nextIncomingAlarm;
                                if (inc)
                                    ClockService.skipAlarmOnce(inc.index);
                            }
                        }
                    }
                }
            }

            // Empty State
            ClockEmptyState {
                visible: ClockService.alarms.length === 0
                cardHeight: 220
                iconName: "alarm_off"
                iconSize: Theme.iconButtonSize
                title: "No Alarms Configured"
                subtitle: "Click New Alarm below to schedule a wake-up or reminder."
            }

            // Responsive Alarm Grid (Android Clock Expandable Cards with Progressive Disclosure)
            Item {
                id: gridContainer
                visible: ClockService.alarms.length > 0
                width: parent.width
                implicitHeight: alarmGrid.implicitHeight

                readonly property real minCardWidth: 320
                readonly property real gap: Theme.spacingM
                readonly property int columns: Math.max(1, Math.floor((width + gap) / (minCardWidth + gap)))
                readonly property real cardWidth: Math.floor((width - (columns - 1) * gap) / columns)

                Grid {
                    id: alarmGrid
                    width: parent.width
                    columns: gridContainer.columns
                    spacing: gridContainer.gap

                    Repeater {
                        id: alarmRepeater
                        model: ClockService.alarms

                        // Index of the slot whose resting rect contains the grid point, or -1.
                        function slotAt(px, py) {
                            for (let i = 0; i < count; i++) {
                                const it = itemAt(i);
                                if (it && px >= it.x && px < it.x + it.width + alarmGrid.spacing && py >= it.y && py < it.y + it.height + alarmGrid.spacing)
                                    return i;
                            }
                            return -1;
                        }

                        Rectangle {
                            id: alarmCard
                            required property int index

                            readonly property var alarmObj: {
                                void ClockService.alarmRevision;
                                return ClockService.alarms[index] || {
                                    hour: 7,
                                    minute: 0,
                                    label: "Alarm",
                                    enabled: false,
                                    days: [],
                                    soundId: "classic",
                                    snoozeMin: 10,
                                    volume: 100,
                                    deleteAfterGoesOff: false,
                                    skippedDateKey: ""
                                };
                            }
                            readonly property bool isEnabled: {
                                void ClockService.alarmRevision;
                                return Boolean(alarmObj.enabled);
                            }
                            readonly property bool isExpanded: ClockService.expandedAlarmIndex === index
                            readonly property bool isEditingThis: (ClockService.timePickerOpen && ClockService.editingAlarmIndex === index)
                                || (ClockService.labelDialogOpen && ClockService.editingLabelAlarmIndex === index)
                            readonly property bool cardHovered: cardHover.hovered || isEditingThis
                            readonly property var timeParts: {
                                void ClockService.alarmRevision;
                                return ClockService.formatClockParts(alarmObj.hour, alarmObj.minute);
                            }
                            readonly property string hmText: timeParts.timeText
                            readonly property string ampmText: timeParts.meridiem
                            readonly property string labelStr: {
                                void ClockService.alarmRevision;
                                return alarmObj.label || "Alarm";
                            }
                            readonly property var alarmDays: {
                                void ClockService.alarmRevision;
                                return alarmObj.days || [];
                            }
                            readonly property string scheduleSummary: {
                                void ClockService.alarmRevision;
                                return ClockService.formatAlarmSchedule(alarmDays);
                            }
                            readonly property var nextInfo: {
                                void ClockService.alarmRevision;
                                void ClockService.now;
                                return ClockService.getAlarmNextInfo(index);
                            }
                            readonly property bool isSkippedNext: {
                                void ClockService.alarmRevision;
                                void ClockService.now;
                                return ClockService.isAlarmSkippedNext(index);
                            }
                            readonly property string soundId: {
                                void ClockService.alarmRevision;
                                return alarmObj.soundId || "classic";
                            }
                            readonly property var soundInfo: {
                                void ClockService.alarmRevision;
                                return ClockService.getSoundInfo(soundId);
                            }
                            readonly property int snoozeMin: {
                                void ClockService.alarmRevision;
                                return alarmObj.snoozeMin || 10;
                            }
                            readonly property int volume: {
                                void ClockService.alarmRevision;
                                return typeof alarmObj.volume === "number" ? alarmObj.volume : 100;
                            }
                            readonly property bool deleteAfterGoesOff: {
                                void ClockService.alarmRevision;
                                return Boolean(alarmObj.deleteAfterGoesOff);
                            }
                            readonly property bool isBeingDragged: root.draggingAlarmIndex === index
                            property real dragDx: 0
                            property real dragDy: 0
                            property real shiftX: {
                                const s = root.previewSlot(index);
                                const a = s !== index ? alarmRepeater.itemAt(s) : null;
                                return a ? a.x - x : 0;
                            }
                            property real shiftY: {
                                const s = root.previewSlot(index);
                                const a = s !== index ? alarmRepeater.itemAt(s) : null;
                                return a ? a.y - y : 0;
                            }

                            Behavior on shiftX {
                                enabled: Theme.animationsEnabled
                                NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                            }
                            Behavior on shiftY {
                                enabled: Theme.animationsEnabled
                                NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                            }

                            transform: Translate {
                                x: alarmCard.isBeingDragged ? alarmCard.dragDx : alarmCard.shiftX
                                y: alarmCard.isBeingDragged ? alarmCard.dragDy : alarmCard.shiftY
                            }

                            width: gridContainer.cardWidth
                            height: cardCol.implicitHeight + Theme.spacingL * 2
                            clip: true
                            scale: isBeingDragged ? 1.04 : (alarmCardDragArea.pressed && alarmCardDragArea.dragIntentEstablished ? 0.98 : 1.0)
                            z: isBeingDragged ? 100 : 1
                            radius: timeTapArea.pressed ? Theme.cornerRadiusM : ((cardHovered || isExpanded) ? Theme.cornerRadiusXL : Theme.cornerRadiusL)
                            color: {
                                if (isBeingDragged)
                                    return Theme.blend(Theme.surfaceContainerHighest, Theme.primary, Theme.stateLayerDrag);
                                if (isEnabled)
                                    return (cardHovered || isExpanded) ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh;
                                return (cardHovered || isExpanded) ? Theme.surfaceContainer : Theme.surfaceContainerLow;
                            }
                            border.width: isExpanded ? Theme.outlineWidthFocused : Theme.layerOutlineWidth
                            border.color: {
                                if (isExpanded)
                                    return Theme.withAlpha(Theme.primary, 0.65);
                                if (cardHovered)
                                    return isEnabled ? Theme.primary : Theme.outline;
                                return isEnabled ? Theme.outlineMedium : Theme.outlineLight;
                            }

                            Behavior on scale {
                                enabled: Theme.animationsEnabled
                                NumberAnimation {
                                    duration: ClockMetrics.transitionDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: ClockMetrics.curveFastSpatial
                                }
                            }

                            Behavior on height {
                                enabled: Theme.animationsEnabled
                                NumberAnimation {
                                    duration: ClockMetrics.transitionDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: ClockMetrics.curveFastSpatial
                                }
                            }

                            Behavior on radius {
                                enabled: Theme.animationsEnabled
                                NumberAnimation {
                                    duration: ClockMetrics.transitionDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: ClockMetrics.curveFastSpatial
                                }
                            }

                            Behavior on color {
                                enabled: Theme.animationsEnabled
                                ColorAnimation {
                                    duration: ClockMetrics.fadeDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: ClockMetrics.curveEffects
                                }
                            }

                            Behavior on border.color {
                                enabled: Theme.animationsEnabled
                                ColorAnimation {
                                    duration: ClockMetrics.fadeDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: ClockMetrics.curveEffects
                                }
                            }

                            HoverHandler {
                                id: cardHover
                            }

                            // Hold-and-drag to reorder (deferred commit on release), or click to toggle expanded options
                            MouseArea {
                                id: alarmCardDragArea
                                anchors.fill: parent
                                preventStealing: dragIntentEstablished
                                cursorShape: dragIntentEstablished ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                                readonly property real dragThreshold: 10
                                property point pressGridPos: Qt.point(0, 0)
                                property bool dragIntentEstablished: false

                                function beginDrag() {
                                    dragIntentEstablished = true;
                                    root.draggingAlarmIndex = alarmCard.index;
                                    root.dropTargetAlarmIndex = alarmCard.index;
                                }

                                function endDrag(commit) {
                                    const from = root.draggingAlarmIndex;
                                    const to = root.dropTargetAlarmIndex;
                                    alarmCard.dragDx = 0;
                                    alarmCard.dragDy = 0;
                                    dragIntentEstablished = false;
                                    root.draggingAlarmIndex = -1;
                                    root.dropTargetAlarmIndex = -1;
                                    if (commit && from >= 0 && to >= 0 && from !== to)
                                        Qt.callLater(() => ClockService.moveAlarm(from, to));
                                }

                                onPressAndHold: beginDrag()

                                onPressed: mouse => {
                                    pressGridPos = mapToItem(alarmGrid, mouse.x, mouse.y);
                                    dragIntentEstablished = false;
                                }

                                onPositionChanged: mouse => {
                                    if (!pressed)
                                        return;
                                    // Grid coordinates include the card's Translate, so the delta never feeds back on itself.
                                    const p = mapToItem(alarmGrid, mouse.x, mouse.y);
                                    const dx = p.x - pressGridPos.x;
                                    const dy = p.y - pressGridPos.y;
                                    if (!dragIntentEstablished) {
                                        if (Math.abs(dx) <= dragThreshold && Math.abs(dy) <= dragThreshold)
                                            return;
                                        beginDrag();
                                    }
                                    alarmCard.dragDx = dx;
                                    alarmCard.dragDy = dy;
                                    const target = alarmRepeater.slotAt(p.x, p.y);
                                    if (target >= 0)
                                        root.dropTargetAlarmIndex = target;
                                }

                                onReleased: {
                                    const wasDrag = dragIntentEstablished;
                                    endDrag(true);
                                    if (!wasDrag)
                                        ClockService.expandedAlarmIndex = alarmCard.isExpanded ? -1 : alarmCard.index;
                                }

                                onCanceled: endDrag(false)
                            }

                            DTooltipHost {
                                target: alarmCard
                                hoverArea: alarmCardDragArea
                                text: "Hold and drag to reorder alarm • Click to customize"
                            }

                            Column {
                                id: cardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: Theme.spacingL
                                spacing: Theme.spacingXS

                                // Collapsed Row 1: Label Pill (Left) + Expand Chevron (Right)
                                Item {
                                    width: parent.width
                                    height: 28

                                    Rectangle {
                                        id: labelPill
                                        x: -Theme.spacingS
                                        width: Math.min(parent.width - rightMetaRow.width - Theme.spacingS, labelInnerRow.implicitWidth + Theme.spacingS * 2)
                                        height: 28
                                        radius: 14
                                        color: labelMouse.pressed
                                            ? Theme.withAlpha(Theme.primary, 0.22)
                                            : (labelMouse.containsMouse ? Theme.withAlpha(Theme.surfaceText, Theme.stateLayerHover) : "transparent")

                                        Behavior on color {
                                            enabled: Theme.animationsEnabled
                                            ColorAnimation { duration: ClockMetrics.fadeDuration }
                                        }
                                    }

                                    Row {
                                        id: labelInnerRow
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        DIcon {
                                            name: "label"
                                            size: Theme.iconSizeSmall
                                            color: labelMouse.containsMouse ? Theme.primary : (alarmCard.isEnabled ? Theme.surfaceVariantText : Theme.withAlpha(Theme.surfaceVariantText, 0.5))
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            id: labelText
                                            width: Math.min(alarmCard.width - rightMetaRow.width - Theme.spacingL * 2 - 44, implicitWidth)
                                            elide: Text.ElideRight
                                            text: alarmCard.labelStr
                                            font.pixelSize: Theme.fontSizeMedium
                                            font.weight: Theme.fontWeightMedium
                                            color: labelMouse.containsMouse ? Theme.surfaceText : (alarmCard.isEnabled ? Theme.surfaceVariantText : Theme.withAlpha(Theme.surfaceVariantText, 0.6))
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        DIcon {
                                            visible: labelMouse.containsMouse
                                            name: "edit"
                                            size: Theme.iconSizeSmall
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: labelMouse
                                        anchors.fill: labelPill
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            ClockService.editingLabelAlarmIndex = alarmCard.index;
                                            ClockService.labelDialogOpen = true;
                                        }
                                    }

                                    DTooltipHost {
                                        target: labelPill
                                        hoverArea: labelMouse
                                        text: "Edit alarm label"
                                    }

                                    // Right Meta: Silent indicator / Skipped indicator / Vacation indicator + Expand/Collapse Chevron
                                    Row {
                                        id: rightMetaRow
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        DIcon {
                                            visible: alarmCard.soundId === "silent"
                                            name: "notifications_off"
                                            size: 16
                                            color: alarmCard.isEnabled ? Theme.surfaceVariantText : Theme.withAlpha(Theme.surfaceVariantText, 0.5)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        DBadge {
                                            visible: ClockService.isVacationActive && alarmCard.isEnabled
                                            text: "Vacation"
                                            color: Theme.withAlpha(Theme.tertiary, 0.22)
                                            textColor: Theme.tertiary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        DBadge {
                                            visible: alarmCard.isSkippedNext && !ClockService.isVacationActive
                                            text: "Skipped once"
                                            color: Theme.withAlpha(Theme.error, 0.18)
                                            textColor: Theme.error
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        DActionButton {
                                            id: expandBtn
                                            buttonSize: Theme.buttonHeightXXS
                                            iconName: alarmCard.isExpanded ? "expand_less" : "expand_more"
                                            iconSize: Theme.chipIconSize
                                            iconColor: alarmCard.isExpanded ? Theme.primary : Theme.surfaceVariantText
                                            backgroundColor: alarmCard.isExpanded
                                                ? Theme.withAlpha(Theme.primary, 0.16)
                                                : Theme.withAlpha(Theme.surfaceVariant, 0.25)
                                            tooltipText: alarmCard.isExpanded ? "Collapse options" : "Customize alarm"
                                            anchors.verticalCenter: parent.verticalCenter
                                            onClicked: ClockService.expandedAlarmIndex = alarmCard.isExpanded ? -1 : alarmCard.index
                                        }
                                    }
                                }

                                // Collapsed Row 2: Big Time (Left) + Switch Toggle / Edit Delete (Right)
                                Item {
                                    width: parent.width
                                    height: 50

                                    Rectangle {
                                        id: timeHoverPill
                                        x: -Theme.spacingS
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: timeRow.implicitWidth + Theme.spacingS * 2
                                        height: 46
                                        radius: Theme.cornerRadiusM
                                        color: Theme.surfaceText
                                        opacity: timeTapArea.pressed ? Theme.stateLayerPressed : (timeTapArea.containsMouse ? Theme.stateLayerHover : 0)

                                        Behavior on opacity {
                                            enabled: Theme.animationsEnabled
                                            NumberAnimation { duration: ClockMetrics.fadeDuration }
                                        }
                                    }

                                    Row {
                                        id: timeRow
                                        anchors.left: parent.left
                                        anchors.verticalCenter: timeHoverPill.verticalCenter
                                        spacing: 6

                                        NumericText {
                                            id: hmLabel
                                            text: alarmCard.hmText
                                            font.pixelSize: Theme.fontSizeDisplay
                                            font.weight: Font.Bold
                                            color: alarmCard.isEnabled ? Theme.surfaceText : Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            visible: alarmCard.ampmText !== ""
                                            text: alarmCard.ampmText
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Theme.fontWeightBold
                                            color: alarmCard.isEnabled ? Theme.primary : Theme.surfaceVariantText
                                            anchors.baseline: hmLabel.baseline
                                        }
                                    }

                                    MouseArea {
                                        id: timeTapArea
                                        anchors.fill: timeHoverPill
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.openEditAlarmPicker(alarmCard.index)
                                    }

                                    DTooltipHost {
                                        target: timeHoverPill
                                        hoverArea: timeTapArea
                                        text: "Click to change alarm time"
                                    }

                                    Row {
                                        id: toggleControl
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: Theme.spacingXS

                                        DToggle {
                                            hideText: true
                                            checked: alarmCard.isEnabled
                                            anchors.verticalCenter: parent.verticalCenter
                                            onToggled: isChecked => ClockService.toggleAlarm(alarmCard.index, isChecked)
                                        }
                                    }
                                }

                                // Collapsed Row 3: Concise Schedule Summary ("Mon, Tue, Wed, Thu, Fri" or "Tomorrow" • "in 6h 20m")
                                // Clicking this summary row also toggles the expanded dropdown
                                Item {
                                    width: parent.width
                                    height: 22
                                    visible: !alarmCard.isExpanded

                                    Row {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        StyledText {
                                            text: alarmCard.scheduleSummary
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: alarmCard.isEnabled ? Theme.surfaceVariantText : Theme.withAlpha(Theme.surfaceVariantText, 0.5)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            visible: alarmCard.isEnabled && alarmCard.nextInfo !== null
                                            text: "•"
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.withAlpha(Theme.surfaceVariantText, 0.4)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            visible: alarmCard.isEnabled && alarmCard.nextInfo !== null
                                            text: alarmCard.nextInfo ? alarmCard.nextInfo.relativeText : ""
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.expandedAlarmIndex = alarmCard.index
                                    }
                                }

                                // Expanded Dropdown Drawer: All Advanced Controls (Days, Quick Presets, Sound, Snooze, Skip/Delete)
                                Column {
                                    visible: alarmCard.isExpanded
                                    width: parent.width
                                    spacing: Theme.spacingM
                                    topPadding: Theme.spacingXS

                                    // Weekday Selector Pills (S M T W T F S) inside Dropdown
                                    Column {
                                        width: parent.width
                                        spacing: 8

                                        Item {
                                            width: parent.width
                                            height: 20

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: alarmCard.scheduleSummary
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.DemiBold
                                                color: Theme.primary
                                            }

                                            StyledText {
                                                visible: alarmCard.isEnabled && alarmCard.nextInfo !== null
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: alarmCard.nextInfo ? `Rings ${alarmCard.nextInfo.relativeText}` : ""
                                                font.pixelSize: Theme.fontSizeSmall
                                                color: Theme.surfaceVariantText
                                            }
                                        }

                                        Row {
                                            width: parent.width
                                            height: 30
                                            spacing: Math.max(3, (width - root.dayItems.length * 28) / (root.dayItems.length - 1))

                                            Repeater {
                                                model: root.dayItems

                                                Rectangle {
                                                    id: dayCircle
                                                    required property var modelData
                                                    required property int index

                                                    readonly property bool isSelected: {
                                                        void ClockService.alarmRevision;
                                                        return alarmCard.alarmDays.indexOf(modelData.key) >= 0;
                                                    }

                                                    function toggleDaySelection() {
                                                        const currentDays = alarmCard.alarmDays.slice();
                                                        const pos = currentDays.indexOf(dayCircle.modelData.key);
                                                        if (pos >= 0)
                                                            currentDays.splice(pos, 1);
                                                        else
                                                            currentDays.push(dayCircle.modelData.key);
                                                        const ordered = ClockService.weekDays.filter(d => currentDays.indexOf(d) >= 0);
                                                        ClockService.updateAlarmDays(alarmCard.index, ordered);
                                                    }

                                                    width: 28
                                                    height: 28
                                                    radius: dayMouse.pressed ? 8 : (isSelected ? 10 : 14)
                                                    scale: dayMouse.pressed ? 0.90 : (dayMouse.containsMouse ? 1.08 : 1.0)
                                                    activeFocusOnTab: true
                                                    Accessible.role: Accessible.CheckBox
                                                    Accessible.name: modelData.key
                                                    Accessible.checkable: true
                                                    Accessible.checked: isSelected
                                                    Accessible.onPressAction: toggleDaySelection()
                                                    Keys.onSpacePressed: event => {
                                                        toggleDaySelection();
                                                        event.accepted = true;
                                                    }
                                                    Keys.onReturnPressed: event => {
                                                        toggleDaySelection();
                                                        event.accepted = true;
                                                    }
                                                    Keys.onEnterPressed: event => {
                                                        toggleDaySelection();
                                                        event.accepted = true;
                                                    }
                                                    color: {
                                                        if (isSelected) {
                                                            if (!alarmCard.isEnabled)
                                                                return Theme.withAlpha(Theme.primary, 0.32);
                                                            return dayMouse.containsMouse ? Theme.primary : Theme.primaryContainer;
                                                        }
                                                        return dayMouse.containsMouse
                                                            ? Theme.withAlpha(Theme.surfaceText, Theme.stateLayerHover * 1.4)
                                                            : Theme.withAlpha(Theme.surfaceVariant, 0.25);
                                                    }
                                                    border.width: activeFocus ? Theme.outlineWidthFocused : (isSelected ? 0 : (dayMouse.containsMouse ? 1 : 0))
                                                    border.color: activeFocus ? Theme.focusRingColor : Theme.outlineVariant

                                                    Behavior on radius {
                                                        enabled: Theme.animationsEnabled
                                                        NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                                                    }
                                                    Behavior on scale {
                                                        enabled: Theme.animationsEnabled
                                                        NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                                                    }
                                                    Behavior on color {
                                                        enabled: Theme.animationsEnabled
                                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                                    }

                                                    StyledText {
                                                        anchors.centerIn: parent
                                                        text: dayCircle.modelData.letter
                                                        font.pixelSize: Theme.fontSizeSmall
                                                        font.weight: dayCircle.isSelected ? Font.Bold : Font.Medium
                                                        color: {
                                                            if (dayCircle.isSelected) {
                                                                if (!alarmCard.isEnabled)
                                                                    return Theme.surfaceText;
                                                                return dayMouse.containsMouse ? Theme.onPrimary : Theme.onPrimaryContainer;
                                                            }
                                                            return alarmCard.isEnabled ? Theme.surfaceVariantText : Theme.withAlpha(Theme.surfaceVariantText, 0.45);
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: dayMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: dayCircle.toggleDaySelection()
                                                    }
                                                }
                                            }
                                        }

                                        // Quick Preset Chips (Weekdays, Weekends, Every day, One-time)
                                        DFilterChips {
                                            width: parent.width
                                            chipHeight: Theme.buttonHeightXXS
                                            chipPadding: Theme.spacingM
                                            showCounts: false
                                            model: root.repeatPresets.map(p => ({ label: p.label }))
                                            currentIndex: root.repeatPresets.findIndex(p => p.label === alarmCard.scheduleSummary)
                                            onSelectionChanged: idx => {
                                                if (idx >= 0 && idx < root.repeatPresets.length)
                                                    ClockService.updateAlarmDays(alarmCard.index, root.repeatPresets[idx].days.slice());
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Theme.outlineVariant
                                        opacity: 0.5
                                    }

                                    // Alarm Sound Selector using DFilterChips
                                    DFilterChips {
                                        width: parent.width
                                        chipHeight: Theme.buttonHeightXXS
                                        chipPadding: Theme.spacingM
                                        showCounts: false
                                        model: ClockService.alarmSounds.map(s => ({ label: s.name, icon: s.icon, value: s.id }))
                                        currentIndex: Math.max(0, ClockService.alarmSounds.findIndex(s => s.id === alarmCard.soundId))
                                        onSelectionChanged: idx => {
                                            if (idx >= 0 && idx < ClockService.alarmSounds.length)
                                                ClockService.updateAlarmSound(alarmCard.index, ClockService.alarmSounds[idx].id);
                                        }
                                    }

                                    // Snooze Duration Selector (5m, 10m, 15m, 30m) using DButtonGroup
                                    Item {
                                        width: parent.width
                                        height: snoozeGroup.height

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Snooze"
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: Theme.surfaceVariantText
                                        }

                                        DButtonGroup {
                                            id: snoozeGroup
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            size: "small"
                                            selectionMode: "single"
                                            checkEnabled: false
                                            minButtonWidth: 42
                                            buttonPadding: Theme.spacingS
                                            model: ClockService.snoozeOptions.map(m => `${m}m`)
                                            currentIndex: Math.max(0, ClockService.snoozeOptions.indexOf(alarmCard.snoozeMin))
                                            onSelectionChanged: (idx, sel) => {
                                                if (sel && idx >= 0 && idx < ClockService.snoozeOptions.length)
                                                    ClockService.updateAlarmSnooze(alarmCard.index, ClockService.snoozeOptions[idx]);
                                            }
                                        }
                                    }

                                    // Alarm Volume Slider
                                    Column {
                                        width: parent.width
                                        spacing: 4

                                        Item {
                                            width: parent.width
                                            height: 18

                                            StyledText {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "Volume"
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Medium
                                                color: Theme.surfaceVariantText
                                            }

                                            NumericText {
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: `${alarmCard.volume}%`
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Bold
                                                color: Theme.primary
                                            }
                                        }

                                        DSlider {
                                            width: parent.width
                                            size: "s"
                                            minimum: 0
                                            maximum: 100
                                            step: 5
                                            unit: "%"
                                            startIcon: alarmCard.volume === 0 ? "volume_off" : (alarmCard.volume < 50 ? "volume_down" : "volume_up")
                                            value: alarmCard.volume
                                            onSliderValueChanged: v => ClockService.updateAlarmVolume(alarmCard.index, v)
                                            onSliderDragFinished: v => ClockService.previewAlarmSound(alarmCard.soundId, v)
                                        }
                                    }

                                    // Bottom Action Row inside Dropdown: Skip Once / Delete after goes off / Duplicate / Delete
                                    Item {
                                        width: parent.width
                                        height: 30

                                        Row {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6

                                            DButton {
                                                visible: alarmCard.isEnabled && alarmCard.alarmDays.length > 0
                                                text: alarmCard.isSkippedNext ? "Restore next" : "Skip once"
                                                iconName: alarmCard.isSkippedNext ? "event_available" : "event_busy"
                                                buttonHeight: Theme.buttonHeightXS
                                                backgroundColor: alarmCard.isSkippedNext ? Theme.primaryContainer : Theme.secondaryContainer
                                                textColor: alarmCard.isSkippedNext ? Theme.onPrimaryContainer : Theme.onSecondaryContainer
                                                onClicked: ClockService.skipAlarmOnce(alarmCard.index)
                                            }

                                            DButton {
                                                visible: alarmCard.alarmDays.length === 0
                                                text: "Delete after goes off"
                                                iconName: alarmCard.deleteAfterGoesOff ? "check_box" : "check_box_outline_blank"
                                                buttonHeight: Theme.buttonHeightXS
                                                backgroundColor: alarmCard.deleteAfterGoesOff ? Theme.primaryContainer : Theme.secondaryContainer
                                                textColor: alarmCard.deleteAfterGoesOff ? Theme.onPrimaryContainer : Theme.onSecondaryContainer
                                                onClicked: ClockService.updateAlarmDeleteAfter(alarmCard.index, !alarmCard.deleteAfterGoesOff)
                                            }
                                        }

                                        Row {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 4

                                            DIconButton {
                                                iconName: "content_copy"
                                                variant: "standard"
                                                size: "s"
                                                tooltipText: "Duplicate alarm"
                                                anchors.verticalCenter: parent.verticalCenter
                                                onClicked: ClockService.duplicateAlarm(alarmCard.index)
                                            }

                                            DIconButton {
                                                iconName: "delete_outline"
                                                variant: "standard"
                                                size: "s"
                                                iconColor: Theme.error
                                                tooltipText: "Delete alarm"
                                                anchors.verticalCenter: parent.verticalCenter
                                                onClicked: ClockService.removeAlarm(alarmCard.index)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // FABs anchored to bottom-right: Vacation Mode Button + New Alarm Button
    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingS

        DFab {
            iconName: "beach_access"
            colorRole: ClockService.isVacationActive ? "tertiary" : "secondaryContainer"
            tooltipText: ClockService.isVacationActive ? "Vacation mode is active • Click to configure" : "Turn on Vacation Mode to silence all alarms"
            onClicked: ClockService.vacationSheetOpen = true
        }

        DFab {
            iconName: "add"
            colorRole: "primary"
            tooltipText: "Create a new alarm"
            onClicked: ClockService.openAddAlarmPicker()
        }
    }
}
