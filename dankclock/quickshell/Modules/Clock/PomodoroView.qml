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
                    ClockRingDial {
                        anchors.horizontalCenter: parent.horizontalCenter
                        dialSize: 240
                        blobSize: 204
                        progress: ClockService.pomodoroProgress
                        ringColor: root.phaseColor
                        active: ClockService.pomodoroRunning
                        activeBlobAlpha: 0.20
                        idleBlobAlpha: 0.10
                        lobeAmount: 0.075
                        centerSpacing: 6

                        DBadge {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: ClockService.pomodoroRunning ? "ACTIVE" : "READY"
                            color: ClockService.pomodoroRunning ? root.phaseColor : Theme.secondaryContainer
                            textColor: ClockService.pomodoroRunning ? "#111315" : Theme.onSecondaryContainer
                        }

                        NumericText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.timeDisplay
                            font.pixelSize: Theme.fontSizeDisplay
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

                    // Integrated Cycle Phase Selector using DButtonGroup (labelOnlySelected expands active phase)
                    DButtonGroup {
                        id: cyclePillGroup
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: "small"
                        selectionMode: "single"
                        checkEnabled: false
                        labelOnlySelected: true
                        minButtonWidth: 36
                        buttonPadding: Theme.spacingM
                        selectedColor: root.phaseColor
                        selectedContentColor: "#111315"
                        model: {
                            const count = Math.max(1, ClockService.pomodoroTargetCycles) * 2;
                            const items = [];
                            for (let i = 0; i < count; i++) {
                                const isLongBreak = i === count - 1;
                                const isFocus = i % 2 === 0;
                                const focusNum = Math.floor(i / 2) + 1;
                                const label = isLongBreak ? "Long Break" : (isFocus ? `Focus ${focusNum}` : "Break");
                                items.push({
                                    icon: isLongBreak ? "self_improvement" : (isFocus ? "psychology" : "coffee"),
                                    text: label,
                                    tooltip: label
                                });
                            }
                            return items;
                        }
                        currentIndex: root.activeCycleStepIdx
                        onSelectionChanged: (idx, sel) => {
                            if (sel && idx !== root.activeCycleStepIdx)
                                ClockService.setPomodoroStep(idx);
                        }
                    }

                    // Control Action Buttons
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: Theme.spacingM

                        // Reset Cycle Button
                        DButton {
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

                        // Skip Button
                        DButton {
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
                                size: Theme.chipIconSize
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

                        // Segmented Day / Week / Month Selector using DButtonGroup
                        DButtonGroup {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            size: "small"
                            selectionMode: "single"
                            checkEnabled: false
                            minButtonWidth: 48
                            buttonPadding: Theme.spacingM
                            selectedColor: root.phaseColor
                            selectedContentColor: "#111315"
                            model: ["Day", "Week", "Month"]
                            currentIndex: root.statsPeriod === "month" ? 2 : (root.statsPeriod === "week" ? 1 : 0)
                            onSelectionChanged: (idx, sel) => {
                                if (!sel)
                                    return;
                                const periods = ["day", "week", "month"];
                                root.statsPeriod = periods[idx];
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
                                radius: Theme.cornerRadiusL
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
                                            size: Theme.iconSizeSmall
                                            color: root.phaseColor
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 1

                                        StyledText {
                                            text: kpiCard.modelData.label
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                        }

                                        NumericText {
                                            text: kpiCard.modelData.value
                                            font.pixelSize: Theme.fontSizeMedium
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
                                    font.pixelSize: Theme.fontSizeSmall
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
                                        font.pixelSize: Theme.fontSizeSmall
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
                                        font.pixelSize: Theme.fontSizeSmall
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
        }
    }
}
