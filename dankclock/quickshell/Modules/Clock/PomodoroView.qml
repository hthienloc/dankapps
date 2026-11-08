pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

    readonly property string phaseTitle: {
        switch (ClockService.pomodoroPhase) {
        case "shortBreak": return "Short Break";
        case "longBreak": return "Long Break";
        default: return "Focus Session";
        }
    }

    readonly property string phaseSubtitle: {
        switch (ClockService.pomodoroPhase) {
        case "shortBreak": return "Step away and recharge your mind";
        case "longBreak": return "Take a deep breath and relax";
        default: return "Eliminate distractions and stay in flow";
        }
    }

    readonly property color phaseColor: {
        switch (ClockService.pomodoroPhase) {
        case "shortBreak": return "#6ec78c";
        case "longBreak": return "#6ba5e7";
        default: return Theme.primary;
        }
    }

    readonly property int currentPhaseIdx: {
        switch (ClockService.pomodoroPhase) {
        case "shortBreak": return 1;
        case "longBreak": return 2;
        default: return 0;
        }
    }

    // Active step index (0 .. pomodoroTargetCycles * 2 - 1) across the full Pomodoro cycle
    readonly property int activeCycleStepIdx: {
        const n = Math.max(1, ClockService.pomodoroTargetCycles);
        const mod = ClockService.pomodoroCyclesCompleted % n;
        if (ClockService.pomodoroPhase === "longBreak")
            return n * 2 - 1;
        if (ClockService.pomodoroPhase === "shortBreak") {
            const breakIdx = mod > 0 ? mod - 1 : 0;
            return breakIdx * 2 + 1;
        }
        return mod * 2;
    }

    readonly property string timeDisplay: {
        const totalSec = Math.ceil(ClockService.pomodoroRemainingSeconds);
        const m = Math.floor(totalSec / 60);
        const s = totalSec % 60;
        return `${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
    }

    property string statsPeriod: "week" // "day" | "week" | "month"
    property int hoveredBarIdx: -1
    readonly property var focusStats: ClockService.getPomodoroStats(statsPeriod)

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

            // Main Pomodoro Hero Card
            Rectangle {
                id: mainCard
                width: parent.width
                height: pomoCol.implicitHeight + Theme.spacingXL * 2
                radius: Theme.cornerRadiusXL
                color: cardHover.hovered ? Theme.surfaceContainerHighest : ClockMetrics.rowColor
                border.width: Theme.layerOutlineWidth
                border.color: ClockService.pomodoroRunning
                    ? root.phaseColor
                    : (cardHover.hovered ? Theme.outline : Theme.outlineMedium)

                Behavior on color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }
                Behavior on border.color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }

                HoverHandler {
                    id: cardHover
                }

                Column {
                    id: pomoCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingXL
                    spacing: Theme.spacingL

                    // Official DButtonGroup for Phase Selection
                    DButtonGroup {
                        id: phaseSelector
                        anchors.horizontalCenter: parent.horizontalCenter
                        selectionMode: "single"
                        checkEnabled: true
                        size: "small"
                        model: [
                            { icon: "psychology", text: "Focus" },
                            { icon: "coffee", text: "Short Break" },
                            { icon: "self_improvement", text: "Long Break" }
                        ]
                        currentIndex: root.currentPhaseIdx
                        onSelectionChanged: (idx, sel) => {
                            if (!sel)
                                return;
                            const phases = ["focus", "shortBreak", "longBreak"];
                            ClockService.setPomodoroPhase(phases[idx]);
                        }
                    }

                    // Dial & Timer Display with DRingGauge + DOrganicBlob
                    Item {
                        width: 240
                        height: 240
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Organic Blob Background
                        DOrganicBlob {
                            anchors.centerIn: parent
                            width: 204
                            height: 204
                            fillColor: Theme.withAlpha(root.phaseColor, ClockService.pomodoroRunning ? 0.20 : 0.10)
                            lobes: 12
                            rotationDeg: -90
                            lobeAmount: 0.075
                            hillPower: 0.88
                            roundness: 0.22
                            paddingFrac: 0.02
                            segments: 144
                        }

                        // Real Progress Arc Indicator
                        DRingGauge {
                            anchors.fill: parent
                            value: ClockService.pomodoroProgress
                            strokeWidth: 12
                            ringColor: root.phaseColor
                            trackColor: Theme.surfaceContainerHighest
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            DBadge {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: ClockService.pomodoroRunning ? "ACTIVE" : "READY"
                                color: ClockService.pomodoroRunning ? root.phaseColor : Theme.secondaryContainer
                                textColor: ClockService.pomodoroRunning ? "#111315" : Theme.onSecondaryContainer
                            }

                            NumericText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.timeDisplay
                                font.pixelSize: 46
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.phaseTitle
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightBold
                                color: root.phaseColor
                            }
                        }
                    }

                    // Integrated Cycle Phase Pill Group (Active on current Focus / Break step)
                    Rectangle {
                        id: cyclePillGroup
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: cycleStepsRow.implicitWidth + 10
                        height: 40
                        radius: 20
                        color: Theme.surfaceContainerLow
                        border.width: 1
                        border.color: Theme.outlineVariant

                        Row {
                            id: cycleStepsRow
                            anchors.centerIn: parent
                            spacing: 4

                            Repeater {
                                model: Math.max(1, ClockService.pomodoroTargetCycles) * 2

                                Rectangle {
                                    id: stepPill
                                    required property int index

                                    readonly property int totalSteps: Math.max(1, ClockService.pomodoroTargetCycles) * 2
                                    readonly property bool isLongBreak: index === totalSteps - 1
                                    readonly property bool isFocus: index % 2 === 0
                                    readonly property int focusNum: Math.floor(index / 2) + 1
                                    readonly property bool isActive: index === root.activeCycleStepIdx
                                    readonly property bool isCompleted: index < root.activeCycleStepIdx

                                    readonly property color stepAccent: isLongBreak
                                        ? "#6ba5e7"
                                        : (isFocus ? Theme.primary : "#6ec78c")
                                    readonly property string stepIcon: isLongBreak
                                        ? "self_improvement"
                                        : (isFocus ? "psychology" : "coffee")
                                    readonly property string stepLabel: isLongBreak
                                        ? "Long Break"
                                        : (isFocus ? `Focus ${focusNum}` : "Break")

                                    width: isActive ? (stepContentRow.implicitWidth + 20) : 34
                                    height: 30
                                    radius: 15
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: isActive
                                        ? stepAccent
                                        : (stepMouse.containsMouse
                                            ? Theme.surfaceContainerHighest
                                            : (isCompleted ? Theme.withAlpha(stepAccent, 0.18) : "transparent"))

                                    Behavior on width {
                                        enabled: Theme.animationsEnabled
                                        NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                                    }
                                    Behavior on color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }

                                    Row {
                                        id: stepContentRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        DIcon {
                                            visible: stepPill.isActive || !stepPill.isFocus
                                            name: stepPill.stepIcon
                                            size: 14
                                            color: stepPill.isActive
                                                ? "#111315"
                                                : (stepPill.isCompleted ? stepPill.stepAccent : Theme.surfaceVariantText)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            visible: stepPill.isActive || stepPill.isFocus
                                            text: stepPill.isActive ? stepPill.stepLabel : String(stepPill.focusNum)
                                            font.pixelSize: 11
                                            font.weight: (stepPill.isActive || stepPill.isCompleted) ? Font.Bold : Font.Medium
                                            color: stepPill.isActive
                                                ? "#111315"
                                                : (stepPill.isCompleted ? stepPill.stepAccent : Theme.surfaceVariantText)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: stepMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.setPomodoroStep(stepPill.index)
                                    }

                                    DTooltipHost {
                                        target: stepPill
                                        hoverArea: stepMouse
                                        text: stepPill.stepLabel
                                    }
                                }
                            }
                        }
                    }

                    // Control Action Buttons
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        // Reset Cycle Button (Hidden unless in Edit Mode to prevent accidental resets)
                        DButton {
                            visible: ClockService.pomodoroEditMode
                            text: "Reset"
                            iconName: "replay"
                            buttonHeight: Theme.buttonHeightM
                            backgroundColor: Theme.errorContainer
                            textColor: Theme.onErrorContainer
                            onClicked: ClockService.resetPomodoro()
                        }

                        // Large Play / Pause Button
                        DButton {
                            text: ClockService.pomodoroRunning ? "Pause Session" : "Start Session"
                            iconName: ClockService.pomodoroRunning ? "pause" : "play_arrow"
                            buttonHeight: Theme.buttonHeightM
                            backgroundColor: root.phaseColor
                            textColor: "#111315"
                            onClicked: ClockService.togglePomodoro()
                        }

                        // Skip Button (Hidden unless in Edit Mode to prevent accidental skip)
                        DButton {
                            visible: ClockService.pomodoroEditMode
                            text: "Skip"
                            iconName: "skip_next"
                            buttonHeight: Theme.buttonHeightM
                            backgroundColor: Theme.secondaryContainer
                            textColor: Theme.onSecondaryContainer
                            onClicked: ClockService.skipPomodoroPhase()
                        }
                    }
                }
            }

            // Focus Activity & Statistics Chart Card (Day / Week / Month)
            Rectangle {
                id: statsCard
                width: parent.width
                height: statsCol.implicitHeight + Theme.spacingL * 2
                radius: Theme.cornerRadiusXL
                color: statsHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                border.width: 1
                border.color: statsHover.hovered ? Theme.outline : Theme.outlineVariant

                Behavior on color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }
                Behavior on border.color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }

                HoverHandler {
                    id: statsHover
                }

                Column {
                    id: statsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingM

                    // Header Row: Title + Summary Badges + Day/Week/Month Selector
                    Item {
                        width: parent.width
                        height: 34

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            DIcon {
                                name: "bar_chart"
                                size: 18
                                color: root.phaseColor
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: "Focus Statistics"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.DemiBold
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            DBadge {
                                text: `${root.focusStats.totalFormatted} • ${root.focusStats.totalSessions} sessions`
                                reserveText: "88h 88m • 88 sessions"
                                color: Theme.withAlpha(root.phaseColor, 0.2)
                                textColor: root.phaseColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Segmented Day / Week / Month Pill Group
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: periodRow.implicitWidth + 6
                            height: 30
                            radius: 15
                            color: Theme.surfaceContainerHighest

                            Row {
                                id: periodRow
                                anchors.centerIn: parent
                                spacing: 2

                                Repeater {
                                    model: [
                                        { id: "day", label: "Day" },
                                        { id: "week", label: "Week" },
                                        { id: "month", label: "Month" }
                                    ]

                                    Rectangle {
                                        id: periodChip
                                        required property var modelData
                                        readonly property bool selected: root.statsPeriod === modelData.id

                                        width: periodLabel.implicitWidth + 20
                                        height: 24
                                        radius: 12
                                        color: selected
                                            ? root.phaseColor
                                            : (periodMouse.containsMouse ? Theme.withAlpha(Theme.surfaceVariant, 0.4) : "transparent")

                                        Behavior on color {
                                            enabled: Theme.animationsEnabled
                                            ColorAnimation { duration: ClockMetrics.fadeDuration }
                                        }

                                        StyledText {
                                            id: periodLabel
                                            anchors.centerIn: parent
                                            text: periodChip.modelData.label
                                            font.pixelSize: 11
                                            font.weight: periodChip.selected ? Font.Bold : Font.Medium
                                            color: periodChip.selected ? "#111315" : Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            id: periodMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.statsPeriod = periodChip.modelData.id
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // KPI Strip (Total, Average, Peak)
                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        Repeater {
                            model: [
                                {
                                    icon: "timer",
                                    label: root.statsPeriod === "day" ? "Today Total" : (root.statsPeriod === "week" ? "Week Total" : "30-Day Total"),
                                    value: root.focusStats.totalFormatted
                                },
                                {
                                    icon: "trending_up",
                                    label: root.statsPeriod === "day" ? "Per 3h Block" : (root.statsPeriod === "week" ? "Daily Average" : "3-Day Average"),
                                    value: root.focusStats.avgFormatted
                                },
                                {
                                    icon: "emoji_events",
                                    label: "Peak Focus",
                                    value: root.focusStats.peakLabel
                                }
                            ]

                            Rectangle {
                                id: kpiCard
                                required property var modelData
                                width: Math.floor((parent.width - Theme.spacingM * 2) / 3)
                                height: 52
                                radius: 16
                                color: Theme.withAlpha(Theme.surfaceVariant, 0.22)

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: Theme.withAlpha(root.phaseColor, 0.16)
                                        anchors.verticalCenter: parent.verticalCenter

                                        DIcon {
                                            anchors.centerIn: parent
                                            name: kpiCard.modelData.icon
                                            size: 15
                                            color: root.phaseColor
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        StyledText {
                                            text: kpiCard.modelData.label
                                            font.pixelSize: 10
                                            color: Theme.surfaceVariantText
                                        }

                                        NumericText {
                                            text: kpiCard.modelData.value
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            color: Theme.surfaceText
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Interactive Vertical Bar Chart
                    Item {
                        id: chartArea
                        width: parent.width
                        height: 156

                        readonly property real plotTop: 22
                        readonly property real plotBottom: height - 24
                        readonly property real plotHeight: plotBottom - plotTop
                        readonly property real plotRightMargin: 42
                        readonly property real plotWidth: width - plotRightMargin

                        // Horizontal Guide Lines (100%, 50%, 0%) + Y-Axis Scale Labels
                        Repeater {
                            model: [1.0, 0.5, 0.0]

                            Item {
                                id: guideItem
                                required property real modelData
                                width: chartArea.width
                                y: chartArea.plotBottom - modelData * chartArea.plotHeight

                                Rectangle {
                                    width: chartArea.plotWidth
                                    height: 1
                                    color: Theme.withAlpha(Theme.outlineVariant, guideItem.modelData === 0 ? 0.65 : 0.32)
                                }

                                NumericText {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.top
                                    text: ClockService.formatFocusMinutes(Math.round(root.focusStats.scaleMax * guideItem.modelData))
                                    font.pixelSize: 10
                                    color: Theme.surfaceVariantText
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }

                        // Columns / Bars Row
                        Row {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            width: chartArea.plotWidth
                            height: parent.height

                            Repeater {
                                model: root.focusStats.bars

                                Item {
                                    id: barSlot
                                    required property var modelData
                                    required property int index

                                    readonly property int barCount: Math.max(1, root.focusStats.bars.length)
                                    width: chartArea.plotWidth / barCount
                                    height: chartArea.height

                                    readonly property real frac: root.focusStats.scaleMax > 0
                                        ? Math.max(0, Math.min(1, modelData.minutes / root.focusStats.scaleMax))
                                        : 0
                                    readonly property real barH: modelData.minutes > 0
                                        ? Math.max(8, Math.round(frac * chartArea.plotHeight))
                                        : 4
                                    readonly property bool isHovered: barMouse.containsMouse

                                    // Floating Value Pill above bar
                                    NumericText {
                                        visible: barSlot.modelData.minutes > 0 && (barSlot.isHovered || barSlot.modelData.isCurrent)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: Math.max(0, chartArea.plotBottom - barSlot.barH - 18)
                                        text: ClockService.formatFocusMinutes(barSlot.modelData.minutes)
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: (barSlot.modelData.isCurrent || barSlot.isHovered) ? root.phaseColor : Theme.surfaceVariantText
                                    }

                                    // Vertical Bar Pill
                                    Rectangle {
                                        id: barRect
                                        width: Math.min(32, Math.max(14, Math.floor(barSlot.width * 0.48)))
                                        height: barSlot.barH
                                        radius: Math.min(8, width / 2)
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: chartArea.plotBottom - height
                                        color: barSlot.modelData.minutes === 0
                                            ? Theme.withAlpha(Theme.surfaceVariant, 0.28)
                                            : ((barSlot.modelData.isCurrent || barSlot.isHovered)
                                                ? root.phaseColor
                                                : Theme.withAlpha(root.phaseColor, 0.48))

                                        Behavior on height {
                                            enabled: Theme.animationsEnabled
                                            NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                                        }
                                        Behavior on color {
                                            enabled: Theme.animationsEnabled
                                            ColorAnimation { duration: ClockMetrics.fadeDuration }
                                        }
                                    }

                                    // X-Axis Label below bar
                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: chartArea.plotBottom + 6
                                        text: barSlot.modelData.label
                                        font.pixelSize: 11
                                        font.weight: (barSlot.modelData.isCurrent || barSlot.isHovered) ? Font.Bold : Font.Medium
                                        color: (barSlot.modelData.isCurrent || barSlot.isHovered) ? root.phaseColor : Theme.surfaceVariantText
                                    }

                                    MouseArea {
                                        id: barMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    DTooltipHost {
                                        target: barSlot
                                        hoverArea: barMouse
                                        text: `${barSlot.modelData.sublabel}: ${ClockService.formatFocusMinutes(barSlot.modelData.minutes)}`
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Inline Pomodoro Duration Settings (Visible only in Edit Mode)
            ClockGroup {
                visible: ClockService.pomodoroEditMode
                width: parent.width

                ClockRow {
                    visible: ClockService.pomodoroEditMode
                    width: parent.width
                    iconName: "tune"
                    accent: "purple"
                    title: "Focus Duration"
                    subtitle: "Minutes per focus session"
                    isFirstInGroup: true
                    isLastInGroup: false

                    DNumberStepper {
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${SettingsData.pomodoroFocusMinutes}m`
                        textSize: 16
                        buttonSize: 28
                        incrementEnabled: SettingsData.pomodoroFocusMinutes < 90
                        decrementEnabled: SettingsData.pomodoroFocusMinutes > 5
                        onIncrement: () => SettingsData.pomodoroFocusMinutes = Math.min(90, SettingsData.pomodoroFocusMinutes + 5)
                        onDecrement: () => SettingsData.pomodoroFocusMinutes = Math.max(5, SettingsData.pomodoroFocusMinutes - 5)
                    }
                }

                ClockRow {
                    visible: ClockService.pomodoroEditMode
                    width: parent.width
                    iconName: "coffee"
                    accent: "green"
                    title: "Short & Long Breaks"
                    subtitle: `Short: ${SettingsData.pomodoroShortBreakMinutes}m • Long: ${SettingsData.pomodoroLongBreakMinutes}m`
                    isFirstInGroup: false
                    isLastInGroup: true

                    Row {
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        DButton {
                            text: `Short ${SettingsData.pomodoroShortBreakMinutes}m`
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.secondaryContainer
                            textColor: Theme.onSecondaryContainer
                            onClicked: {
                                const next = SettingsData.pomodoroShortBreakMinutes >= 15 ? 3 : SettingsData.pomodoroShortBreakMinutes + 2;
                                SettingsData.pomodoroShortBreakMinutes = next;
                            }
                        }

                        DButton {
                            text: `Long ${SettingsData.pomodoroLongBreakMinutes}m`
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.secondaryContainer
                            textColor: Theme.onSecondaryContainer
                            onClicked: {
                                const next = SettingsData.pomodoroLongBreakMinutes >= 30 ? 10 : SettingsData.pomodoroLongBreakMinutes + 5;
                                SettingsData.pomodoroLongBreakMinutes = next;
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
            iconName: ClockService.pomodoroEditMode ? "check" : "edit"
            text: ClockService.pomodoroEditMode ? "Done" : ""
            colorRole: "primary"
            tooltipText: ClockService.pomodoroEditMode ? "Finish editing Pomodoro" : "Edit durations or reset/skip session"
            onClicked: ClockService.pomodoroEditMode = !ClockService.pomodoroEditMode
        }
    }
}
