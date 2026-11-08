pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

    // Distinct M3E world clock accent palette matching the reference design (green, orange, blue, purple, pink, cyan)
    readonly property var accentColors: ["#3fb950", "#f59e0b", "#2ea0f5", "#b39ddb", "#f48fb1", "#26c6da"]

    function getCityAccent(idx) {
        return accentColors[idx % accentColors.length];
    }

    property int hoveredCityIndex: -1
    property int draggingIndex: -1

    // Time Scrubber offset in minutes (-720 to +720, in 15-minute increments)
    property int scrubMinutesOffset: 0
    readonly property bool isScrubbing: scrubMinutesOffset !== 0
    readonly property var effectiveNow: isScrubbing
        ? new Date(ClockService.now.getTime() + scrubMinutesOffset * 60000)
        : ClockService.now

    readonly property string scrubDeltaLabel: {
        if (scrubMinutesOffset === 0)
            return "Live time";
        const sign = scrubMinutesOffset > 0 ? "+" : "-";
        const absMin = Math.abs(scrubMinutesOffset);
        const h = Math.floor(absMin / 60);
        const m = absMin % 60;
        if (h > 0 && m > 0)
            return `${sign}${h}h ${m}m`;
        if (h > 0)
            return `${sign}${h}h`;
        return `${sign}${m}m`;
    }

    readonly property var localTimeParts: ClockService.formatClockParts(root.effectiveNow.getHours(), root.effectiveNow.getMinutes())
    readonly property string localTimeStr: localTimeParts.timeText
    readonly property string localMeridiemStr: localTimeParts.meridiem
    readonly property string localDayName: Qt.formatDate(root.effectiveNow, "dddd")

    readonly property bool isWideLayout: width >= 660

    DFlickable {
        id: flickable
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: Math.max(height, mainPageColumn.height + Theme.spacingXL * 4)

        Column {
            id: mainPageColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacingL
            spacing: Theme.spacingL

            // Row 1: Dedicated Clock Row (Centered Analog World Dial)
            Item {
                id: clockRow
                width: parent.width
                height: 280

                AnalogWorldDial {
                    width: 280
                    height: 280
                    anchors.centerIn: parent
                }
            }

            // Row 2: Cities Grid Row below the Clock (3 per row on normal/wide window)
            Item {
                id: cardsGridContainer
                width: parent.width
                height: citiesGrid.implicitHeight

                readonly property real gap: Theme.spacingM
                readonly property int cols: width >= 600 ? 3 : (width >= 400 ? 2 : 1)
                readonly property real pillWidth: Math.floor((width - (cols - 1) * gap) / cols)

                WorldCardsGrid {
                    id: citiesGrid
                    width: parent.width
                    columns: cardsGridContainer.cols
                    spacing: cardsGridContainer.gap
                    cardWidth: cardsGridContainer.pillWidth
                }
            }

            // Lower Section: Full-width Interactive Time Zone Scrubber / Meeting Planner Card
            // Aligned flush with both the left edge of the clock dial and the right edge of the pill grid
            Rectangle {
                id: scrubberCard
                width: parent.width
                height: scrubberCol.implicitHeight + Theme.spacingL * 2
                radius: 26
                color: scrubberHover.hovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                border.width: root.isScrubbing ? 1.5 : 1
                border.color: root.isScrubbing
                    ? Theme.primary
                    : (scrubberHover.hovered ? Theme.outline : Theme.outlineVariant)

                Behavior on color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }
                Behavior on border.color {
                    enabled: Theme.animationsEnabled
                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                }

                HoverHandler {
                    id: scrubberHover
                }

                Column {
                    id: scrubberCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingL
                    spacing: Theme.spacingS

                    // Header Row: Title + Offset Pill + Step / Reset Buttons
                    Item {
                        width: parent.width
                        height: Math.max(28, scrubberLeftFlow.implicitHeight)

                        Flow {
                            id: scrubberLeftFlow
                            anchors.left: parent.left
                            anchors.right: scrubberStepRow.left
                            anchors.rightMargin: Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingS

                            Row {
                                height: 24
                                spacing: Theme.spacingS

                                DIcon {
                                    name: root.isScrubbing ? "history_toggle_off" : "schedule"
                                    size: 16
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: "Time Zone Scrubber"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                height: 24
                                spacing: Theme.spacingS

                                DBadge {
                                    text: root.scrubDeltaLabel
                                    reserveText: "+88h 88m"
                                    color: root.isScrubbing ? Theme.primary : Theme.withAlpha(Theme.surfaceVariant, 0.45)
                                    textColor: root.isScrubbing ? Theme.onPrimary : Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DButton {
                                    visible: root.isScrubbing
                                    text: "Reset"
                                    iconName: "restart_alt"
                                    buttonHeight: 24
                                    backgroundColor: Theme.primaryContainer
                                    textColor: Theme.onPrimaryContainer
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: root.scrubMinutesOffset = 0
                                }
                            }
                        }

                        Row {
                            id: scrubberStepRow
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            // Quick -1h / +1h Step Chips
                            Rectangle {
                                width: 36
                                height: 24
                                radius: 12
                                color: minusHourMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.withAlpha(Theme.surfaceVariant, 0.35)
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "-1h"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }

                                MouseArea {
                                    id: minusHourMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.scrubMinutesOffset = Math.max(-720, root.scrubMinutesOffset - 60)
                                }
                            }

                            Rectangle {
                                width: 36
                                height: 24
                                radius: 12
                                color: plusHourMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.withAlpha(Theme.surfaceVariant, 0.35)
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "+1h"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }

                                MouseArea {
                                    id: plusHourMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.scrubMinutesOffset = Math.min(720, root.scrubMinutesOffset + 60)
                                }
                            }
                        }
                    }

                    // Dedicated Hour Scale Labels Row (Separated ABOVE the track so city badges never overlap text)
                    Item {
                        width: parent.width
                        height: 16

                        Repeater {
                            model: 9

                            Item {
                                required property int index
                                readonly property int hVal: index * 3
                                x: (index / 8) * parent.width
                                height: parent.height

                                StyledText {
                                    text: `${String(parent.hVal).padStart(2, "0")}:00`
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: (parent.hVal >= 9 && parent.hVal <= 18)
                                        ? Theme.withAlpha(Theme.primary, 0.9)
                                        : Theme.withAlpha(Theme.surfaceVariantText, 0.65)
                                    x: parent.index === 0 ? 0 : (parent.index === 8 ? -width : -width / 2)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    // 24-Hour Timeline Track Bar with City Markers & Drag Scrubber
                    Item {
                        id: timelineTrack
                        width: parent.width
                        height: 36

                        readonly property real localHourFrac: {
                            const d = root.effectiveNow;
                            return (d.getHours() + d.getMinutes() / 60) / 24;
                        }

                        // Background 24-Hour Track Pill
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 28
                            radius: 14
                            color: Theme.withAlpha(Theme.surfaceVariant, 0.25)
                            clip: true

                            // Daylight / Working Hours Highlight Band (08:00 to 18:00)
                            Rectangle {
                                x: parent.width * (8 / 24)
                                width: parent.width * (10 / 24)
                                height: parent.height
                                radius: 8
                                color: Theme.withAlpha(Theme.primary, 0.16)
                            }

                            // Subtle Vertical Hour Grid Ticks inside the track
                            Repeater {
                                model: 24

                                Rectangle {
                                    required property int index
                                    visible: index > 0
                                    x: (index / 24) * parent.width
                                    width: 1
                                    height: index % 3 === 0 ? parent.height : 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.withAlpha(Theme.surfaceVariantText, index % 3 === 0 ? 0.22 : 0.1)
                                }
                            }
                        }

                        // Colored City Position Markers along the 24h axis
                        Repeater {
                            model: ClockService.worldClocks

                            Item {
                                id: trackCityMarker
                                required property var modelData
                                required property int index

                                readonly property color cColor: root.getCityAccent(index)
                                readonly property real cityHourFrac: ClockService.getCityTimeInfo(modelData, root.effectiveNow).hourFrac24

                                x: Math.max(16, Math.min(timelineTrack.width - 16, cityHourFrac * timelineTrack.width))
                                anchors.verticalCenter: parent.verticalCenter
                                z: root.hoveredCityIndex === index ? 15 : 5

                                Rectangle {
                                    width: 28
                                    height: 18
                                    radius: 9
                                    anchors.centerIn: parent
                                    color: trackCityMarker.cColor
                                    border.width: root.hoveredCityIndex === trackCityMarker.index ? 1.5 : 1
                                    border.color: root.hoveredCityIndex === trackCityMarker.index ? Theme.surfaceText : Theme.surfaceContainerLow

                                    StyledText {
                                        anchors.centerIn: parent
                                        text: ClockService.getCityCode(trackCityMarker.modelData)
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: "#141618"
                                    }
                                }
                            }
                        }

                        // Local Time Playhead Handle
                        Item {
                            id: localPlayhead
                            x: Math.max(10, Math.min(timelineTrack.width - 10, timelineTrack.localHourFrac * timelineTrack.width))
                            anchors.verticalCenter: parent.verticalCenter
                            z: 20

                            Rectangle {
                                width: 3
                                height: 34
                                radius: 1.5
                                anchors.centerIn: parent
                                color: Theme.surfaceText
                            }

                            Rectangle {
                                width: 14
                                height: 14
                                radius: 7
                                anchors.centerIn: parent
                                color: Theme.primary
                                border.width: 2
                                border.color: Theme.surfaceText
                                scale: scrubArea.pressed ? 1.25 : (scrubArea.containsMouse ? 1.12 : 1.0)

                                Behavior on scale {
                                    enabled: Theme.animationsEnabled
                                    NumberAnimation { duration: ClockMetrics.transitionDuration }
                                }
                            }
                        }

                        // Interactive Scrub MouseArea & Wheel Support
                        MouseArea {
                            id: scrubArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            property real startX: 0
                            property int startOffset: 0

                            onPressed: mouse => {
                                startX = mouse.x;
                                startOffset = root.scrubMinutesOffset;
                            }
                            onPositionChanged: mouse => {
                                if (!pressed || width <= 0)
                                    return;
                                const deltaX = mouse.x - startX;
                                const rawMin = startOffset + Math.round((deltaX / width) * 1440);
                                const snapped = Math.round(rawMin / 15) * 15;
                                root.scrubMinutesOffset = Math.max(-720, Math.min(720, snapped));
                            }
                            onDoubleClicked: root.scrubMinutesOffset = 0
                            onWheel: wheel => {
                                if (wheel.angleDelta.y === 0)
                                    return;
                                const step = wheel.angleDelta.y > 0 ? 15 : -15;
                                root.scrubMinutesOffset = Math.max(-720, Math.min(720, root.scrubMinutesOffset + step));
                                wheel.accepted = true;
                            }
                        }

                        DTooltipHost {
                            target: timelineTrack
                            hoverArea: scrubArea
                            text: "Drag or scroll to scrub across time zones (double-click to reset)"
                        }
                    }
                }
            }
        }
    }

    // Reusable Precision Analog Dial Component with 60 Minute Ticks, Numbers 1..12, and Colored City Lollipop Hands
    component AnalogWorldDial: Item {
        id: dialRoot

        readonly property real cx: width / 2
        readonly property real cy: height / 2
        readonly property real outerRadius: Math.min(width, height) / 2 - 4

        HoverHandler {
            id: dialHover
        }

        // Circular Dial Face
        Rectangle {
            anchors.centerIn: parent
            width: dialRoot.outerRadius * 2
            height: dialRoot.outerRadius * 2
            radius: dialRoot.outerRadius
            color: dialHover.hovered ? Theme.surfaceContainer : Theme.surfaceContainerLow
            border.width: 2
            border.color: root.isScrubbing
                ? Theme.primary
                : (dialHover.hovered ? Theme.outline : Theme.outlineVariant)

            Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }
            Behavior on border.color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }
        }

        // 60 Minute & Hour Perimeter Ticks
        Repeater {
            model: 60

            Item {
                required property int index
                readonly property bool isHourTick: index % 5 === 0
                anchors.fill: parent
                rotation: index * 6

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: dialRoot.cy - dialRoot.outerRadius + 8
                    width: parent.isHourTick ? 2.2 : 1.2
                    height: parent.isHourTick ? 11 : 5
                    radius: width / 2
                    color: parent.isHourTick
                        ? Theme.withAlpha(Theme.surfaceText, 0.72)
                        : Theme.withAlpha(Theme.surfaceVariantText, 0.36)
                    antialiasing: true
                }
            }
        }

        // Hour Numbers (1..12)
        Repeater {
            model: 12

            StyledText {
                required property int index
                readonly property int hourNum: index === 0 ? 12 : index
                readonly property real angleRad: (index * 30 - 90) * Math.PI / 180
                readonly property real numRadius: dialRoot.outerRadius - 32

                text: String(hourNum)
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                color: Theme.withAlpha(Theme.surfaceText, 0.85)
                x: dialRoot.cx + numRadius * Math.cos(angleRad) - width / 2
                y: dialRoot.cy + numRadius * Math.sin(angleRad) - height / 2
            }
        }

        // Layer 1 (z: 5): Colored World Clock Arm Stems (Rendered UNDER the white local hands)
        Repeater {
            model: ClockService.worldClocks

            Item {
                id: cityStemItem
                required property var modelData
                required property int index

                readonly property color handColor: root.getCityAccent(index)
                readonly property bool isHighlighted: root.hoveredCityIndex === index
                readonly property real hourAngleDeg: ClockService.getCityTimeInfo(modelData, root.effectiveNow).hourAngle12Deg
                readonly property real tipRadius: dialRoot.outerRadius * 0.56

                anchors.fill: parent
                z: isHighlighted ? 12 : (5 + index)

                Rectangle {
                    id: armStem
                    x: dialRoot.cx - width / 2
                    y: dialRoot.cy - cityStemItem.tipRadius
                    width: cityStemItem.isHighlighted ? 4.5 : 3.2
                    height: cityStemItem.tipRadius
                    radius: width / 2
                    color: cityStemItem.handColor
                    antialiasing: true

                    transform: Rotation {
                        origin.x: armStem.width / 2
                        origin.y: cityStemItem.tipRadius
                        angle: cityStemItem.hourAngleDeg
                    }
                }
            }
        }

        // Layer 2 (z: 20..22): Local Clock Hands (Hour, Minute, Second)
        Rectangle {
            id: localHourHand
            readonly property real hourAngle: (root.effectiveNow.getHours() % 12 + root.effectiveNow.getMinutes() / 60) * 30
            readonly property real len: dialRoot.outerRadius * 0.44
            x: dialRoot.cx - width / 2
            y: dialRoot.cy - len
            width: 7
            height: len
            radius: 3.5
            color: Theme.surfaceText
            antialiasing: true
            z: 20

            transform: Rotation {
                origin.x: localHourHand.width / 2
                origin.y: localHourHand.len
                angle: localHourHand.hourAngle
            }
        }

        Rectangle {
            id: localMinHand
            readonly property real minAngle: (root.effectiveNow.getMinutes() + root.effectiveNow.getSeconds() / 60) * 6
            readonly property real len: dialRoot.outerRadius * 0.68
            x: dialRoot.cx - width / 2
            y: dialRoot.cy - len
            width: 5
            height: len
            radius: 2.5
            color: Theme.surfaceText
            antialiasing: true
            z: 21

            transform: Rotation {
                origin.x: localMinHand.width / 2
                origin.y: localMinHand.len
                angle: localMinHand.minAngle
            }
        }

        Rectangle {
            id: localSecHand
            visible: SettingsData.showSeconds && !root.isScrubbing
            readonly property real secAngle: root.effectiveNow.getSeconds() * 6
            readonly property real len: dialRoot.outerRadius * 0.76
            readonly property real tail: 18
            x: dialRoot.cx - width / 2
            y: dialRoot.cy - len
            width: 1.8
            height: len + tail
            radius: 0.9
            color: Theme.withAlpha(Theme.surfaceText, 0.82)
            antialiasing: true
            z: 22

            transform: Rotation {
                origin.x: localSecHand.width / 2
                origin.y: localSecHand.len
                angle: localSecHand.secAngle
            }
        }

        // Layer 3 (z: 30+): Upright Circular City Code Badges (Rendered ABOVE the white hands so text like LON is never cut through)
        Repeater {
            model: ClockService.worldClocks

            Item {
                id: cityBadgeItem
                required property var modelData
                required property int index

                readonly property color handColor: root.getCityAccent(index)
                readonly property bool isHighlighted: root.hoveredCityIndex === index
                readonly property string codeText: ClockService.getCityCode(modelData)
                readonly property real hourAngleDeg: ClockService.getCityTimeInfo(modelData, root.effectiveNow).hourAngle12Deg
                readonly property real angleRad: (hourAngleDeg - 90) * Math.PI / 180
                readonly property real tipRadius: dialRoot.outerRadius * 0.56
                readonly property real tipX: dialRoot.cx + tipRadius * Math.cos(angleRad)
                readonly property real tipY: dialRoot.cy + tipRadius * Math.sin(angleRad)

                anchors.fill: parent
                z: isHighlighted ? 40 : (30 + index)

                Rectangle {
                    id: codeBubble
                    width: 32
                    height: 32
                    radius: 16
                    x: cityBadgeItem.tipX - width / 2
                    y: cityBadgeItem.tipY - height / 2
                    scale: cityBadgeItem.isHighlighted ? 1.12 : 1.0
                    color: cityBadgeItem.handColor
                    border.width: cityBadgeItem.isHighlighted ? 2 : 1.5
                    border.color: cityBadgeItem.isHighlighted ? Theme.surfaceText : Theme.surfaceContainerLow
                    antialiasing: true

                    Behavior on scale {
                        enabled: Theme.animationsEnabled
                        NumberAnimation { duration: ClockMetrics.transitionDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: ClockMetrics.curveFastSpatial }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: cityBadgeItem.codeText
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#141618"
                    }

                    MouseArea {
                        id: bubbleMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoveredCityIndex = cityBadgeItem.index
                        onExited: {
                            if (root.hoveredCityIndex === cityBadgeItem.index)
                                root.hoveredCityIndex = -1;
                        }
                    }

                    DTooltipHost {
                        target: codeBubble
                        hoverArea: bubbleMouse
                        text: `${cityBadgeItem.modelData.city} (${ClockService.getCityTimeInfo(cityBadgeItem.modelData, root.effectiveNow).timeText})`
                    }
                }
            }
        }

        // Layer 4 (z: 45): Center Pivot Cap with Inner Hole
        Rectangle {
            anchors.centerIn: parent
            width: 14
            height: 14
            radius: 7
            color: Theme.surfaceText
            z: 45

            Rectangle {
                anchors.centerIn: parent
                width: 5
                height: 5
                radius: 2.5
                color: Theme.surfaceContainerLow
            }
        }
    }

    // Reusable 2-Column Pill Cards Grid (Local Time Pill + Reorderable World Clock Pills + Optional Odd-Slot Add Card)
    component WorldCardsGrid: Grid {
        id: gridRoot
        property real cardWidth: 240

        // Card 0: Local Time Hero Pill (Filled Tonal Container, Single-Line Text Layout)
        Rectangle {
            id: localPill
            width: gridRoot.cardWidth
            height: 76
            radius: localHover.hovered ? 26 : 22
            color: localHover.hovered
                ? Theme.blend(Theme.secondaryContainer, Theme.primary, 0.18)
                : Theme.withAlpha(Theme.secondaryContainer, 0.85)
            border.width: root.isScrubbing ? 1.5 : 1
            border.color: (localHover.hovered || root.isScrubbing) ? Theme.primary : Theme.withAlpha(Theme.outline, 0.35)

            Behavior on radius {
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
                id: localHover
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: Theme.spacingM
                anchors.rightMargin: Theme.spacingM

                // Lollipop Pin Marker (White/Light for Local Time)
                Item {
                    id: localPin
                    width: 10
                    height: 38
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.surfaceText
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Rectangle {
                        width: 2
                        anchors.top: parent.top
                        anchors.topMargin: 8
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 1
                        color: Theme.surfaceText
                    }
                }

                // Right Digital Time
                Row {
                    id: localTimeRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    NumericText {
                        id: localHmText
                        text: root.localTimeStr
                        Accessible.role: Accessible.StaticText
                        Accessible.name: "Local time " + root.localTimeStr + (root.localMeridiemStr ? " " + root.localMeridiemStr : "")
                        font.pixelSize: 23
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        visible: root.localMeridiemStr !== ""
                        text: root.localMeridiemStr
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.primary
                        anchors.baseline: localHmText.baseline
                    }
                }

                // Single-Line Title & Day Subtitle anchored cleanly between Pin and Time
                Column {
                    anchors.left: localPin.right
                    anchors.leftMargin: Theme.spacingS + 2
                    anchors.right: localTimeRow.left
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    StyledText {
                        text: "Local time"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    StyledText {
                        text: root.isScrubbing ? `${root.localDayName}, ${root.scrubDeltaLabel}` : root.localDayName
                        font.pixelSize: Theme.fontSizeSmall
                        color: root.isScrubbing ? Theme.primary : Theme.surfaceVariantText
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }
            }
        }

        // World Clock City Pills (Single-Line Text Layout, Drag-and-Drop Reorder, Hover Sync)
        Repeater {
            model: ClockService.worldClocks.length

            Rectangle {
                id: cityPill
                required property int index

                readonly property var modelData: ClockService.worldClocks[index] || { city: "", country: "", tz: "", offsetMin: 0 }
                readonly property color cityColor: root.getCityAccent(index)
                readonly property bool isHovered: pillHover.hovered || root.hoveredCityIndex === index
                readonly property bool isBeingDragged: root.draggingIndex === index
                readonly property var timeInfo: ClockService.getCityTimeInfo(modelData, root.effectiveNow)

                width: gridRoot.cardWidth
                height: 76
                radius: isHovered ? 26 : 22
                scale: isBeingDragged ? 1.03 : (pillDragArea.pressed ? 0.98 : 1.0)
                z: isBeingDragged ? 50 : 1
                color: isHovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow
                border.width: (isHovered || ClockService.worldClockEditMode) ? 1.5 : 1
                border.color: isHovered ? cityColor : Theme.outlineVariant

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
                    id: pillHover
                    onHoveredChanged: {
                        if (hovered)
                            root.hoveredCityIndex = cityPill.index;
                        else if (root.hoveredCityIndex === cityPill.index)
                            root.hoveredCityIndex = -1;
                    }
                }

                // Drag-to-reorder across the grid
                MouseArea {
                    id: pillDragArea
                    anchors.fill: parent
                    anchors.rightMargin: removeBtn.visible ? 34 : 0
                    preventStealing: ClockService.worldClockEditMode || dragIntentEstablished
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    property point pressPos: Qt.point(0, 0)
                    property bool dragIntentEstablished: false

                    onPressAndHold: {
                        dragIntentEstablished = true;
                        root.draggingIndex = cityPill.index;
                    }
                    onPressed: mouse => {
                        pressPos = Qt.point(mouse.x, mouse.y);
                        dragIntentEstablished = ClockService.worldClockEditMode;
                        root.draggingIndex = cityPill.index;
                    }
                    onPositionChanged: mouse => {
                        if (!pressed || root.draggingIndex < 0)
                            return;
                        if (!dragIntentEstablished) {
                            const dx = Math.abs(mouse.x - pressPos.x);
                            const dy = Math.abs(mouse.y - pressPos.y);
                            if (dx > 6 && dx > dy) {
                                dragIntentEstablished = true;
                            } else {
                                return;
                            }
                        }
                        const targetWorldIdx = ClockService.calcGridDropIndex(
                            cityPill,
                            gridRoot,
                            mouse.x,
                            mouse.y,
                            gridRoot.cardWidth,
                            cityPill.height,
                            gridRoot.spacing,
                            gridRoot.columns,
                            ClockService.worldClocks.length,
                            1
                        );
                        if (targetWorldIdx >= 0 && targetWorldIdx !== root.draggingIndex) {
                            ClockService.moveWorldClock(root.draggingIndex, targetWorldIdx);
                            root.draggingIndex = targetWorldIdx;
                        }
                    }
                    onReleased: {
                        dragIntentEstablished = false;
                        root.draggingIndex = -1;
                    }
                    onCanceled: {
                        dragIntentEstablished = false;
                        root.draggingIndex = -1;
                    }
                }

                DTooltipHost {
                    target: cityPill
                    hoverArea: pillDragArea
                    text: "Drag to reorder city"
                }

                Item {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: removeBtn.visible ? Theme.spacingS : Theme.spacingM

                    // Colored Lollipop Pin Marker matching the Analog Clock Hand
                    Item {
                        id: cityPin
                        width: 10
                        height: 38
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: cityPill.cityColor
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle {
                            width: 2
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 1
                            color: cityPill.cityColor
                        }
                    }

                    // Delete / Close Button (Hidden unless in Edit Mode, uses Theme.error)
                    DIconButton {
                        id: removeBtn
                        visible: ClockService.worldClockEditMode
                        iconName: "close"
                        variant: "standard"
                        size: "s"
                        iconColor: Theme.error
                        tooltipText: "Remove city"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: ClockService.removeWorldClock(cityPill.index)
                    }

                    // Digital Time (Flush with right edge)
                    Row {
                        id: cityTimeRow
                        anchors.right: removeBtn.visible ? removeBtn.left : parent.right
                        anchors.rightMargin: removeBtn.visible ? 2 : 0
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        NumericText {
                            id: cityHmText
                            text: cityPill.timeInfo.timeText
                            font.pixelSize: 23
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            visible: cityPill.timeInfo.meridiem !== ""
                            text: cityPill.timeInfo.meridiem
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: cityPill.cityColor
                            anchors.baseline: cityHmText.baseline
                        }
                    }

                    // Superscript Day Delta Badge (-1 / +1) floating above the time so it never indents HH:MM
                    Rectangle {
                        visible: cityPill.timeInfo.dayDeltaBadge !== ""
                        width: dayBadgeText.implicitWidth + 8
                        height: 14
                        radius: 7
                        color: Theme.withAlpha(cityPill.cityColor, 0.2)
                        anchors.right: cityTimeRow.right
                        anchors.bottom: cityTimeRow.top
                        anchors.bottomMargin: -3

                        NumericText {
                            id: dayBadgeText
                            anchors.centerIn: parent
                            text: cityPill.timeInfo.dayDeltaBadge
                            reserveText: "+8"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: cityPill.cityColor
                        }
                    }

                    // Single-Line City Name & Relative Offset ("Today, -7h" / "Tomorrow, +2h")
                    Column {
                        anchors.left: cityPin.right
                        anchors.leftMargin: Theme.spacingS + 2
                        anchors.right: cityTimeRow.left
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: cityPill.modelData.city
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        StyledText {
                            text: cityPill.timeInfo.compactSubtitle
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }
            }
        }
    }

    // Official DCommon DFab Bar anchored to bottom-right
    ClockEditFabBar {
        editMode: ClockService.worldClockEditMode
        hasItems: ClockService.worldClocks.length > 0
        createIcon: "add"
        createText: ClockService.worldClockEditMode ? "Add City" : ""
        createTooltip: "Add a world clock city"
        editTooltip: "Edit or remove cities"
        doneTooltip: "Finish editing world clocks"
        onCreateClicked: ClockService.citySheetOpen = true
        onToggleEditClicked: ClockService.worldClockEditMode = !ClockService.worldClockEditMode
    }
}
