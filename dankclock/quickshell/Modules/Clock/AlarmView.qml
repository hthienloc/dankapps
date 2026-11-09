pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

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
        contentWidth: width
        contentHeight: contentCol.height + ClockMetrics.pagePaddingV + Theme.spacingXL * 4

        Column {
            id: contentCol
            topPadding: Theme.spacingL
            width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ClockMetrics.cardGap

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
                            name: "notifications_active"
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
                        model: ClockService.alarms

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
                            readonly property bool deleteAfterGoesOff: {
                                void ClockService.alarmRevision;
                                return Boolean(alarmObj.deleteAfterGoesOff);
                            }

                            width: gridContainer.cardWidth
                            height: cardCol.implicitHeight + Theme.spacingL * 2
                            clip: true
                            radius: timeTapArea.pressed ? Theme.cornerRadiusM : ((cardHovered || isExpanded) ? Theme.cornerRadiusXL : Theme.cornerRadiusL)
                            color: {
                                if (isEnabled)
                                    return (cardHovered || isExpanded) ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh;
                                return (cardHovered || isExpanded) ? Theme.surfaceContainer : Theme.surfaceContainerLow;
                            }
                            border.width: (ClockService.alarmEditMode || isExpanded) ? Theme.outlineWidthFocused : Theme.layerOutlineWidth
                            border.color: {
                                if (ClockService.alarmEditMode || isExpanded)
                                    return Theme.withAlpha(Theme.primary, 0.65);
                                if (cardHovered)
                                    return isEnabled ? Theme.primary : Theme.outline;
                                return isEnabled ? Theme.outlineMedium : Theme.outlineLight;
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

                            // Background click area so clicking anywhere on the card toggles the dropdown
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ClockService.expandedAlarmIndex = alarmCard.isExpanded ? -1 : alarmCard.index;
                                }
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
                                            visible: labelMouse.containsMouse || ClockService.alarmEditMode
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

                                    // Right Meta: Skipped indicator (only when skipped) + Expand/Collapse Chevron
                                    Row {
                                        id: rightMetaRow
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 6

                                        DBadge {
                                            visible: alarmCard.isSkippedNext
                                            text: "Skipped once"
                                            color: Theme.withAlpha(Theme.error, 0.18)
                                            textColor: Theme.error
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        DActionButton {
                                            id: expandBtn
                                            buttonSize: Theme.buttonHeightXXS
                                            iconName: "expand_more"
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
                                            visible: !ClockService.alarmEditMode
                                            hideText: true
                                            checked: alarmCard.isEnabled
                                            anchors.verticalCenter: parent.verticalCenter
                                            onToggled: isChecked => ClockService.toggleAlarm(alarmCard.index, isChecked)
                                        }

                                        DIconButton {
                                            visible: ClockService.alarmEditMode
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

    // Official DCommon DFab Bar anchored to bottom-right
    ClockEditFabBar {
        editMode: ClockService.alarmEditMode
        hasItems: ClockService.alarms.length > 0
        createIcon: "add_alarm"
        createText: "New Alarm"
        createTooltip: "Create a new alarm"
        editTooltip: "Edit or delete alarms"
        doneTooltip: "Finish editing alarms"
        onCreateClicked: ClockService.openAddAlarmPicker()
        onToggleEditClicked: ClockService.alarmEditMode = !ClockService.alarmEditMode
    }
}
