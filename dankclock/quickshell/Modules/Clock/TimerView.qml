pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

    readonly property bool hasTimers: ClockService.timers.length > 0
    property int draggingTimerIndex: -1
    readonly property int safeActiveIdx: Math.max(0, Math.min(ClockService.activeTimerIndex, ClockService.timers.length - 1))
    readonly property var currentTimer: {
        void ClockService.timerTickRevision;
        return hasTimers ? ClockService.timers[safeActiveIdx] : null;
    }
    readonly property bool currentRunning: {
        void ClockService.timerTickRevision;
        return Boolean(currentTimer && currentTimer.running);
    }
    readonly property bool currentFinished: {
        void ClockService.timerTickRevision;
        return Boolean(currentTimer && currentTimer.finished);
    }
    readonly property double currentTotalMs: {
        void ClockService.timerTickRevision;
        return currentTimer ? currentTimer.totalMs : 0;
    }
    readonly property double currentRemainingMs: {
        void ClockService.timerTickRevision;
        return currentTimer ? currentTimer.remainingMs : 0;
    }
    readonly property real currentProgress: {
        void ClockService.timerTickRevision;
        if (!currentTimer || currentTotalMs <= 0)
            return 0;
        return Math.max(0, Math.min(1, currentRemainingMs / currentTotalMs));
    }

    readonly property var quickPresets: [
        { label: "1 min", sec: 60 },
        { label: "3 min", sec: 180 },
        { label: "5 min", sec: 300 },
        { label: "10 min", sec: 600 },
        { label: "15 min", sec: 900 },
        { label: "25 min", sec: 1500 },
        { label: "45 min", sec: 2700 }
    ]

    DFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: pageColumn.height + ClockMetrics.pagePaddingV + Theme.spacingXL * 4

        Column {
            id: pageColumn
            topPadding: Theme.spacingL
            width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ClockMetrics.cardGap

            // Primary Hero Card: Active Timer Gauge OR Custom Timer Setup
            Rectangle {
                id: heroTimerCard
                width: parent.width
                height: heroCol.implicitHeight + Theme.spacingXL * 2
                radius: Theme.cornerRadiusXL
                color: heroHover.hovered ? Theme.surfaceContainerHighest : ClockMetrics.rowColor
                border.width: Theme.layerOutlineWidth
                border.color: (root.currentRunning && !ClockService.timerSetupMode)
                    ? Theme.primary
                    : (heroHover.hovered ? Theme.outline : Theme.outlineMedium)

                Behavior on color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }
                Behavior on border.color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }

                HoverHandler {
                    id: heroHover
                }

                Column {
                    id: heroCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingXL
                    spacing: Theme.spacingL

                    // Header inside hero card
                    Item {
                        width: parent.width
                        height: 36

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DBadge {
                                visible: !ClockService.timerSetupMode && root.currentTimer !== null
                                text: root.currentFinished ? "FINISHED" : (root.currentRunning ? "RUNNING" : "PAUSED")
                                color: root.currentFinished ? Theme.errorContainer : (root.currentRunning ? Theme.primary : Theme.secondaryContainer)
                                textColor: root.currentFinished ? Theme.onErrorContainer : (root.currentRunning ? Theme.onPrimary : Theme.onSecondaryContainer)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: (ClockService.timerSetupMode || !root.hasTimers) ? "Create Custom Timer" : (root.currentTimer ? root.currentTimer.label : "Timer")
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Theme.fontWeightBold
                                color: Theme.surfaceText
                            }
                        }

                        DButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.hasTimers
                            text: ClockService.timerSetupMode ? "Back to Gauge" : "Custom Duration"
                            iconName: ClockService.timerSetupMode ? "close" : "more_time"
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.secondaryContainer
                            textColor: Theme.onSecondaryContainer
                            onClicked: ClockService.timerSetupMode = !ClockService.timerSetupMode
                        }
                    }

                    // Mode A: Custom Duration Setup using DNumberStepper
                    Column {
                        visible: ClockService.timerSetupMode || !root.hasTimers
                        width: parent.width
                        spacing: Theme.spacingL

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.spacingL

                            Rectangle {
                                width: 120
                                height: 158
                                radius: hoursHover.hovered ? Theme.cornerRadiusL : Theme.cornerRadiusM
                                color: hoursHover.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                border.width: 1
                                border.color: hoursHover.hovered ? Theme.primary : Theme.outlineVariant

                                HoverHandler { id: hoursHover }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "HOURS"
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.primary
                                    }

                                    DNumberStepper {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(ClockService.setupHours).padStart(2, "0")
                                        textSize: 32
                                        buttonSize: 32
                                        incrementEnabled: ClockService.setupHours < 23
                                        decrementEnabled: ClockService.setupHours > 0
                                        onIncrement: () => ClockService.setupHours = Math.min(23, ClockService.setupHours + 1)
                                        onDecrement: () => ClockService.setupHours = Math.max(0, ClockService.setupHours - 1)
                                    }
                                }
                            }

                            Rectangle {
                                width: 120
                                height: 158
                                radius: minsHover.hovered ? Theme.cornerRadiusL : Theme.cornerRadiusM
                                color: minsHover.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                border.width: 1
                                border.color: minsHover.hovered ? Theme.primary : Theme.outlineVariant

                                HoverHandler { id: minsHover }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "MINUTES"
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.primary
                                    }

                                    DNumberStepper {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(ClockService.setupMinutes).padStart(2, "0")
                                        textSize: 32
                                        buttonSize: 32
                                        incrementEnabled: ClockService.setupMinutes < 59
                                        decrementEnabled: ClockService.setupMinutes > 0
                                        onIncrement: () => ClockService.setupMinutes = Math.min(59, ClockService.setupMinutes + 1)
                                        onDecrement: () => ClockService.setupMinutes = Math.max(0, ClockService.setupMinutes - 1)
                                    }
                                }
                            }

                            Rectangle {
                                width: 120
                                height: 158
                                radius: secsHover.hovered ? Theme.cornerRadiusL : Theme.cornerRadiusM
                                color: secsHover.hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainer
                                border.width: 1
                                border.color: secsHover.hovered ? Theme.primary : Theme.outlineVariant

                                HoverHandler { id: secsHover }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingS

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "SECONDS"
                                        font.pixelSize: Theme.fontSizeSmall - 1
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.primary
                                    }

                                    DNumberStepper {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String(ClockService.setupSeconds).padStart(2, "0")
                                        textSize: 32
                                        buttonSize: 32
                                        incrementEnabled: ClockService.setupSeconds < 55
                                        decrementEnabled: ClockService.setupSeconds > 0
                                        onIncrement: () => ClockService.setupSeconds = Math.min(59, ClockService.setupSeconds + 5)
                                        onDecrement: () => ClockService.setupSeconds = Math.max(0, ClockService.setupSeconds - 5)
                                    }
                                }
                            }
                        }

                        DTextField {
                            id: customLabelField
                            width: Math.min(380, parent.width)
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "Timer label (e.g., Boil Eggs, Deep Work)"
                            leftIconName: "label"
                        }

                        DButton {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Start Timer"
                            iconName: "play_arrow"
                            buttonHeight: Theme.buttonHeightM
                            backgroundColor: Theme.primary
                            textColor: Theme.onPrimary
                            enabled: (ClockService.setupHours * 3600 + ClockService.setupMinutes * 60 + ClockService.setupSeconds) > 0
                            onClicked: {
                                ClockService.startCustomTimer(customLabelField.text);
                                customLabelField.text = "";
                            }
                        }
                    }

                    // Mode B: Active Ring Gauge + Controls
                    Column {
                        visible: !ClockService.timerSetupMode && root.hasTimers
                        width: parent.width
                        spacing: Theme.spacingL

                        // Proper 232x232 Ring Gauge container with Organic Blob Backdrop
                        Item {
                            width: 232
                            height: 232
                            anchors.horizontalCenter: parent.horizontalCenter

                            DOrganicBlob {
                                anchors.centerIn: parent
                                width: 196
                                height: 196
                                fillColor: Theme.withAlpha(Theme.primary, root.currentRunning ? 0.14 : 0.06)
                                lobes: 12
                                rotationDeg: -90
                                lobeAmount: 0.06
                                hillPower: 0.88
                                roundness: 0.22
                                paddingFrac: 0.02
                                segments: 144
                            }

                            DRingGauge {
                                anchors.fill: parent
                                value: root.currentProgress
                                strokeWidth: 12
                                ringColor: root.currentFinished ? Theme.error : Theme.primary
                                trackColor: Theme.surfaceContainerHighest
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                NumericText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.currentTimer ? ClockService.formatDuration(root.currentRemainingMs) : "00:00"
                                    font.pixelSize: 44
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    visible: root.currentTimer !== null
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.currentTimer ? `Total ${ClockService.formatDuration(root.currentTotalMs)}` : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        // Control Buttons Row
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.spacingM

                            DButton {
                                text: "Reset"
                                iconName: "restart_alt"
                                buttonHeight: Theme.buttonHeightM
                                backgroundColor: Theme.secondaryContainer
                                textColor: Theme.onSecondaryContainer
                                onClicked: ClockService.resetTimer(root.safeActiveIdx)
                            }

                            DButton {
                                text: root.currentRunning ? "Pause" : "Start"
                                iconName: root.currentRunning ? "pause" : "play_arrow"
                                buttonHeight: Theme.buttonHeightM
                                backgroundColor: Theme.primary
                                textColor: Theme.onPrimary
                                onClicked: ClockService.toggleTimer(root.safeActiveIdx)
                            }

                            DButton {
                                text: "+1:00"
                                iconName: "more_time"
                                buttonHeight: Theme.buttonHeightM
                                backgroundColor: Theme.secondaryContainer
                                textColor: Theme.onSecondaryContainer
                                onClicked: ClockService.addOneMinute(root.safeActiveIdx)
                            }
                        }
                    }
                }
            }

            // Quick Start Presets Section
            Column {
                width: parent.width
                spacing: 0

                ClockSectionLabel {
                    width: parent.width
                    text: "Quick Start Presets"
                }

                Flow {
                    width: parent.width
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.quickPresets

                        DButton {
                            required property var modelData
                            text: modelData.label
                            iconName: "bolt"
                            buttonHeight: Theme.buttonHeightS
                            backgroundColor: ClockMetrics.rowColor
                            textColor: Theme.surfaceText
                            onClicked: ClockService.startPresetTimer(modelData.sec, modelData.label)
                        }
                    }
                }
            }

            // Saved & Active Timers Grid (with Drag-and-Drop Reorder in Edit Mode)
            Column {
                visible: ClockService.timers.length > 0
                width: parent.width
                spacing: 0

                ClockSectionLabel {
                    width: parent.width
                    text: ClockService.timerEditMode
                        ? `All Timers (${ClockService.timers.length}) — Drag to reorder`
                        : `All Timers (${ClockService.timers.length})`
                }

                Item {
                    id: timersGridContainer
                    width: parent.width
                    height: timersGrid.implicitHeight

                    readonly property real gap: Theme.spacingM
                    readonly property int cols: width >= 620 ? 3 : (width >= 420 ? 2 : 1)
                    readonly property real cardWidth: Math.floor((width - (cols - 1) * gap) / cols)

                    Grid {
                        id: timersGrid
                        width: parent.width
                        columns: timersGridContainer.cols
                        spacing: timersGridContainer.gap

                        Repeater {
                            model: ClockService.timers.length

                            Rectangle {
                                id: timerCard
                                required property int index

                                readonly property var timerObj: {
                                    void ClockService.timerTickRevision;
                                    return ClockService.timers[index] || { id: 0, label: "Timer", totalMs: 0, remainingMs: 0, running: false, finished: false };
                                }
                                readonly property bool isCurrent: index === root.safeActiveIdx && !ClockService.timerSetupMode
                                readonly property bool itemRunning: {
                                    void ClockService.timerTickRevision;
                                    return Boolean(timerObj.running);
                                }
                                readonly property bool itemFinished: {
                                    void ClockService.timerTickRevision;
                                    return Boolean(timerObj.finished);
                                }
                                readonly property string countdownText: {
                                    void ClockService.timerTickRevision;
                                    return ClockService.formatDuration(timerObj.remainingMs);
                                }
                                readonly property bool isLongCountdown: countdownText.length > 5
                                readonly property bool isBeingDragged: root.draggingTimerIndex === index

                                width: timersGridContainer.cardWidth
                                height: 92
                                radius: timerCardHover.hovered ? 26 : 22
                                scale: isBeingDragged ? 1.03 : (timerCardMouse.pressed ? 0.98 : 1.0)
                                z: isBeingDragged ? 50 : 1
                                color: isCurrent
                                    ? (timerCardHover.hovered ? Theme.blend(Theme.secondaryContainer, Theme.primary, 0.18) : Theme.withAlpha(Theme.secondaryContainer, 0.85))
                                    : (timerCardHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow)
                                border.width: (isCurrent || itemRunning || ClockService.timerEditMode || timerCardHover.hovered) ? 1.5 : 1
                                border.color: itemRunning
                                    ? Theme.primary
                                    : (isCurrent ? Theme.primary : (timerCardHover.hovered ? Theme.outline : Theme.outlineVariant))

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
                                Behavior on border.color {
                                    enabled: Theme.animationsEnabled
                                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                                }

                                HoverHandler {
                                    id: timerCardHover
                                }

                                // Click to select on gauge; Drag to reorder when in Edit Mode
                                MouseArea {
                                    id: timerCardMouse
                                    anchors.fill: parent
                                    preventStealing: ClockService.timerEditMode && root.draggingTimerIndex >= 0
                                    cursorShape: ClockService.timerEditMode
                                        ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor)
                                        : Qt.PointingHandCursor
                                    property bool dragged: false

                                    onPressed: {
                                        dragged = false;
                                        if (ClockService.timerEditMode)
                                            root.draggingTimerIndex = timerCard.index;
                                    }
                                    onPositionChanged: mouse => {
                                        if (!pressed || !ClockService.timerEditMode || root.draggingTimerIndex < 0)
                                            return;
                                        const mapped = timerCard.mapToItem(timersGrid, mouse.x, mouse.y);
                                        const colW = timersGridContainer.cardWidth + timersGrid.spacing;
                                        const rowH = timerCard.height + timersGrid.spacing;
                                        const targetCol = Math.max(0, Math.min(timersGrid.columns - 1, Math.floor(mapped.x / colW)));
                                        const targetRow = Math.max(0, Math.floor(mapped.y / rowH));
                                        const targetIdx = Math.max(0, Math.min(ClockService.timers.length - 1, targetRow * timersGrid.columns + targetCol));
                                        if (targetIdx !== root.draggingTimerIndex) {
                                            dragged = true;
                                            ClockService.moveTimer(root.draggingTimerIndex, targetIdx);
                                            root.draggingTimerIndex = targetIdx;
                                        }
                                    }
                                    onReleased: {
                                        if (!dragged) {
                                            ClockService.activeTimerIndex = timerCard.index;
                                            ClockService.timerSetupMode = false;
                                        }
                                        root.draggingTimerIndex = -1;
                                    }
                                    onCanceled: root.draggingTimerIndex = -1
                                }

                                DTooltipHost {
                                    target: timerCard
                                    hoverArea: timerCardMouse
                                    text: ClockService.timerEditMode ? "Drag to reorder timer" : "Click to focus on gauge"
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingM
                                    spacing: Theme.spacingXS

                                    // Top Row: Icon/Drag Handle + Label + Status Dot
                                    Item {
                                        width: parent.width
                                        height: 22

                                        Row {
                                            anchors.left: parent.left
                                            anchors.right: statusBadge.left
                                            anchors.rightMargin: Theme.spacingXS
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6

                                            DIcon {
                                                name: ClockService.timerEditMode
                                                    ? "drag_indicator"
                                                    : (timerCard.itemRunning ? "timelapse" : "hourglass_empty")
                                                size: 16
                                                color: timerCard.itemRunning ? Theme.primary : Theme.surfaceVariantText
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            StyledText {
                                                text: timerCard.timerObj.label
                                                font.pixelSize: Theme.fontSizeMedium
                                                font.weight: Font.DemiBold
                                                color: Theme.surfaceText
                                                wrapMode: Text.NoWrap
                                                elide: Text.ElideRight
                                                width: Math.max(0, parent.width - 22)
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        StyledText {
                                            id: statusBadge
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: timerCard.itemFinished ? "Finished" : (timerCard.itemRunning ? "Running" : (timerCard.isCurrent ? "Active" : "Paused"))
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: timerCard.itemFinished ? Theme.error : (timerCard.itemRunning ? Theme.primary : Theme.surfaceVariantText)
                                        }
                                    }

                                    // Bottom Row: Tabular Countdown + Action Buttons
                                    Item {
                                        width: parent.width
                                        height: 36

                                        NumericText {
                                            anchors.left: parent.left
                                            anchors.right: timerCardControls.left
                                            anchors.rightMargin: Theme.spacingXS
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: timerCard.countdownText
                                            font.pixelSize: (timerCard.isLongCountdown && ClockService.timerEditMode) ? 16 : (timerCard.isLongCountdown ? 18 : 22)
                                            font.weight: Font.Bold
                                            color: timerCard.itemRunning ? Theme.primary : Theme.surfaceText
                                            horizontalAlignment: Text.AlignLeft
                                            elide: Text.ElideRight
                                        }

                                        Row {
                                            id: timerCardControls
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: ClockService.timerEditMode ? 2 : 4

                                            DIconButton {
                                                iconName: timerCard.itemRunning ? "pause" : "play_arrow"
                                                variant: timerCard.itemRunning ? "filled" : "tonal"
                                                size: "s"
                                                tooltipText: timerCard.itemRunning ? "Pause timer" : "Start timer"
                                                anchors.verticalCenter: parent.verticalCenter
                                                onClicked: ClockService.toggleTimer(timerCard.index)
                                            }

                                            DIconButton {
                                                iconName: "restart_alt"
                                                variant: "standard"
                                                size: "s"
                                                tooltipText: "Reset timer"
                                                anchors.verticalCenter: parent.verticalCenter
                                                onClicked: ClockService.resetTimer(timerCard.index)
                                            }

                                            DIconButton {
                                                visible: ClockService.timerEditMode
                                                iconName: "delete_outline"
                                                variant: "standard"
                                                size: "s"
                                                iconColor: Theme.error
                                                tooltipText: "Delete timer"
                                                anchors.verticalCenter: parent.verticalCenter
                                                onClicked: ClockService.removeTimer(timerCard.index)
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
            visible: ClockService.timerEditMode || ClockService.timers.length === 0
            iconName: "more_time"
            text: "New Timer"
            colorRole: "primary"
            tooltipText: "Create a custom duration timer"
            onClicked: ClockService.timerSetupMode = true
        }

        DFab {
            visible: ClockService.timers.length > 0
            iconName: ClockService.timerEditMode ? "check" : "edit"
            text: ClockService.timerEditMode ? "Done" : ""
            colorRole: "primary"
            tooltipText: ClockService.timerEditMode ? "Finish editing timers" : "Edit or delete timers"
            onClicked: ClockService.timerEditMode = !ClockService.timerEditMode
        }
    }
}
