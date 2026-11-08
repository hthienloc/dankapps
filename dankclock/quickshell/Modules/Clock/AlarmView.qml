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
        contentHeight: contentCol.height + Theme.spacingXL * 4

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

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
                        radius: 24
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter

                        DIcon {
                            anchors.centerIn: parent
                            name: "notifications_active"
                            size: 24
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
            DCard {
                visible: ClockService.alarms.length === 0
                width: parent.width
                height: 220
                restRadius: Theme.cornerRadiusXL
                color: ClockMetrics.rowColor

                Column {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM

                    DIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        name: "alarm_off"
                        size: 42
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "No Alarms Configured"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Click New Alarm below to schedule a wake-up or reminder."
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
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
                            readonly property string hmText: {
                                void ClockService.alarmRevision;
                                const h24 = alarmObj.hour;
                                const m = String(alarmObj.minute).padStart(2, "0");
                                if (SettingsData.use24HourClock)
                                    return `${String(h24).padStart(2, "0")}:${m}`;
                                const h12 = h24 % 12 || 12;
                                return `${h12}:${m}`;
                            }
                            readonly property string ampmText: {
                                void ClockService.alarmRevision;
                                if (SettingsData.use24HourClock)
                                    return "";
                                return alarmObj.hour >= 12 ? "PM" : "AM";
                            }
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
                                            size: 15
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
                                            size: 13
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

                                        Rectangle {
                                            id: expandBtn
                                            width: 28
                                            height: 28
                                            radius: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: expandMouse.pressed
                                                ? Theme.withAlpha(Theme.primary, 0.25)
                                                : (expandMouse.containsMouse || alarmCard.isExpanded
                                                    ? Theme.withAlpha(Theme.surfaceText, Theme.stateLayerHover * 1.4)
                                                    : Theme.withAlpha(Theme.surfaceVariant, 0.25))

                                            DIcon {
                                                anchors.centerIn: parent
                                                name: "expand_more"
                                                size: 18
                                                color: alarmCard.isExpanded ? Theme.primary : Theme.surfaceVariantText
                                                rotation: alarmCard.isExpanded ? 180 : 0

                                                Behavior on rotation {
                                                    enabled: Theme.animationsEnabled
                                                    NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                                                }
                                            }

                                            MouseArea {
                                                id: expandMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    ClockService.expandedAlarmIndex = alarmCard.isExpanded ? -1 : alarmCard.index;
                                                }
                                            }

                                            DTooltipHost {
                                                target: expandBtn
                                                hoverArea: expandMouse
                                                text: alarmCard.isExpanded ? "Collapse options" : "Customize alarm"
                                            }
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
                                            font.pixelSize: 40
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

                                                    width: 28
                                                    height: 28
                                                    radius: dayMouse.pressed ? 8 : (isSelected ? 10 : 14)
                                                    scale: dayMouse.pressed ? 0.90 : (dayMouse.containsMouse ? 1.08 : 1.0)
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
                                                    border.width: isSelected ? 0 : (dayMouse.containsMouse ? 1 : 0)
                                                    border.color: Theme.outlineVariant

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
                                                        onClicked: {
                                                            const currentDays = alarmCard.alarmDays.slice();
                                                            const pos = currentDays.indexOf(dayCircle.modelData.key);
                                                            if (pos >= 0)
                                                                currentDays.splice(pos, 1);
                                                            else
                                                                currentDays.push(dayCircle.modelData.key);
                                                            const ordered = ClockService.weekDays.filter(d => currentDays.indexOf(d) >= 0);
                                                            ClockService.updateAlarmDays(alarmCard.index, ordered);
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        // Quick Preset Chips (Weekdays, Weekends, Every day, One-time)
                                        Flow {
                                            width: parent.width
                                            spacing: 6

                                            Repeater {
                                                model: root.repeatPresets

                                                Rectangle {
                                                    required property var modelData
                                                    readonly property bool isActivePreset: alarmCard.scheduleSummary === modelData.label

                                                    width: presetText.implicitWidth + 16
                                                    height: 24
                                                    radius: 12
                                                    color: isActivePreset
                                                        ? Theme.primary
                                                        : (presetMouse.containsMouse ? Theme.surfaceContainer : Theme.withAlpha(Theme.surfaceVariant, 0.35))

                                                    StyledText {
                                                        id: presetText
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        font.pixelSize: 11
                                                        font.weight: isActivePreset ? Font.Bold : Font.Medium
                                                        color: isActivePreset ? Theme.onPrimary : Theme.surfaceVariantText
                                                    }

                                                    MouseArea {
                                                        id: presetMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: ClockService.updateAlarmDays(alarmCard.index, modelData.days.slice())
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        color: Theme.outlineVariant
                                        opacity: 0.5
                                    }

                                    // Alarm Sound Selector + Preview
                                    Item {
                                        width: parent.width
                                        height: soundFlow.implicitHeight

                                        Flow {
                                            id: soundFlow
                                            width: parent.width
                                            spacing: 6

                                            Repeater {
                                                model: ClockService.alarmSounds

                                                Rectangle {
                                                    required property var modelData
                                                    readonly property bool isSelectedSound: alarmCard.soundId === modelData.id

                                                    width: soundRow.implicitWidth + 16
                                                    height: 28
                                                    radius: 14
                                                    color: isSelectedSound
                                                        ? Theme.secondaryContainer
                                                        : (soundMouse.containsMouse ? Theme.surfaceContainer : Theme.withAlpha(Theme.surfaceVariant, 0.3))
                                                    border.width: isSelectedSound ? 1 : 0
                                                    border.color: Theme.primary

                                                    Row {
                                                        id: soundRow
                                                        anchors.centerIn: parent
                                                        spacing: 5

                                                        DIcon {
                                                            name: modelData.icon
                                                            size: 14
                                                            color: isSelectedSound ? Theme.primary : Theme.surfaceVariantText
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }

                                                        StyledText {
                                                            text: modelData.name
                                                            font.pixelSize: 11
                                                            font.weight: isSelectedSound ? Font.Bold : Font.Medium
                                                            color: isSelectedSound ? Theme.onSecondaryContainer : Theme.surfaceText
                                                            anchors.verticalCenter: parent.verticalCenter
                                                        }
                                                    }

                                                    MouseArea {
                                                        id: soundMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: ClockService.updateAlarmSound(alarmCard.index, modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Snooze Duration Selector (5m, 10m, 15m, 30m)
                                    Item {
                                        width: parent.width
                                        height: 26

                                        StyledText {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Snooze"
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: Theme.surfaceVariantText
                                        }

                                        Row {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 5

                                            Repeater {
                                                model: ClockService.snoozeOptions

                                                Rectangle {
                                                    required property int modelData
                                                    readonly property bool isSnoozeSelected: alarmCard.snoozeMin === modelData

                                                    width: 38
                                                    height: 24
                                                    radius: 12
                                                    color: isSnoozeSelected
                                                        ? Theme.primaryContainer
                                                        : (snoozeMouse.containsMouse ? Theme.surfaceContainer : Theme.withAlpha(Theme.surfaceVariant, 0.3))

                                                    StyledText {
                                                        anchors.centerIn: parent
                                                        text: `${modelData}m`
                                                        font.pixelSize: 11
                                                        font.weight: isSnoozeSelected ? Font.Bold : Font.Medium
                                                        color: isSnoozeSelected ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                                    }

                                                    MouseArea {
                                                        id: snoozeMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: ClockService.updateAlarmSnooze(alarmCard.index, modelData)
                                                    }
                                                }
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

                                            Rectangle {
                                                visible: alarmCard.alarmDays.length === 0
                                                width: delAfterRow.implicitWidth + 16
                                                height: 28
                                                radius: 14
                                                color: alarmCard.deleteAfterGoesOff
                                                    ? Theme.primaryContainer
                                                    : Theme.withAlpha(Theme.surfaceVariant, 0.35)

                                                Row {
                                                    id: delAfterRow
                                                    anchors.centerIn: parent
                                                    spacing: 5

                                                    DIcon {
                                                        name: alarmCard.deleteAfterGoesOff ? "check_box" : "check_box_outline_blank"
                                                        size: 14
                                                        color: alarmCard.deleteAfterGoesOff ? Theme.primary : Theme.surfaceVariantText
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }

                                                    StyledText {
                                                        text: "Delete after goes off"
                                                        font.pixelSize: 11
                                                        font.weight: Font.Medium
                                                        color: alarmCard.deleteAfterGoesOff ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                                        anchors.verticalCenter: parent.verticalCenter
                                                    }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: ClockService.updateAlarmDeleteAfter(alarmCard.index, !alarmCard.deleteAfterGoesOff)
                                                }
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
    Row {
        id: fabContainer
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXL
        spacing: Theme.spacingS

        DFab {
            visible: ClockService.alarmEditMode || ClockService.alarms.length === 0
            iconName: "add_alarm"
            text: "New Alarm"
            colorRole: "primary"
            tooltipText: "Create a new alarm"
            onClicked: ClockService.openAddAlarmPicker()
        }

        DFab {
            visible: ClockService.alarms.length > 0
            iconName: ClockService.alarmEditMode ? "check" : "edit"
            text: ClockService.alarmEditMode ? "Done" : ""
            colorRole: "primary"
            tooltipText: ClockService.alarmEditMode ? "Finish editing alarms" : "Edit or delete alarms"
            onClicked: ClockService.alarmEditMode = !ClockService.alarmEditMode
        }
    }
}
