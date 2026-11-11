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
    // Drag preview state: the model is only reordered on release so delegates survive the gesture.
    property int draggingIndex: -1
    property int dropTargetIndex: -1

    // Slot a city is shown in while another city is being dragged over the grid.
    function previewSlot(i) {
        const from = draggingIndex;
        const to = dropTargetIndex;
        if (from < 0 || to < 0 || i === from)
            return i;
        if (from < to && i > from && i <= to)
            return i - 1;
        if (from > to && i >= to && i < from)
            return i + 1;
        return i;
    }

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
        interactive: root.draggingIndex < 0
        contentWidth: width
        contentHeight: Math.max(height, mainPageColumn.height + ClockMetrics.pagePaddingV + Theme.spacingXL * 4)

        Column {
            id: mainPageColumn
            topPadding: Theme.spacingL
            width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ClockMetrics.cardGap

            // Row 1: Dedicated Clock Row (Centered Analog World Dial)
            Item {
                id: clockRow
                width: parent.width
                height: 340

                AnalogWorldDial {
                    width: 340
                    height: 340
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
            color: dialScrubArea.pressed
                ? Theme.surfaceContainerHighest
                : (dialScrubArea.containsMouse ? Theme.surfaceContainer : Theme.surfaceContainerLow)
            border.width: root.isScrubbing ? 2.5 : 2
            border.color: root.isScrubbing
                ? Theme.primary
                : (dialScrubArea.containsMouse ? Theme.outline : Theme.outlineVariant)

            Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }
            Behavior on border.color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }

            // Rotational Drag Scrubber on the Analog Clock Face
            MouseArea {
                id: dialScrubArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                property real lastAngleDeg: 0
                property real accumulatedDegrees: 0

                function getAngleDeg(mouse) {
                    const dx = mouse.x - width / 2;
                    const dy = mouse.y - height / 2;
                    let deg = Math.atan2(dy, dx) * 180 / Math.PI;
                    if (deg < 0)
                        deg += 360;
                    return deg;
                }

                onPressed: mouse => {
                    lastAngleDeg = getAngleDeg(mouse);
                    accumulatedDegrees = 0;
                }

                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    const currentAngle = getAngleDeg(mouse);
                    let delta = currentAngle - lastAngleDeg;

                    // Handle boundary crossing around 0/360 degrees
                    if (delta > 180)
                        delta -= 360;
                    else if (delta < -180)
                        delta += 360;

                    lastAngleDeg = currentAngle;
                    accumulatedDegrees += delta;

                    // 360 degrees on dial corresponds to 12 hours (720 minutes), so 1 deg = 2 minutes.
                    // Only apply step changes when >= 7.5 deg (15 minutes).
                    const deltaMinutes = Math.round(accumulatedDegrees * 2 / 15) * 15;
                    if (deltaMinutes !== 0) {
                        const nextOffset = Math.max(-720, Math.min(720, root.scrubMinutesOffset + deltaMinutes));
                        root.scrubMinutesOffset = nextOffset;
                        accumulatedDegrees -= deltaMinutes / 2;
                    }
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
            radius: localHover.hovered ? Theme.cornerRadiusXL : Theme.cornerRadiusL
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
                        font.pixelSize: Theme.fontSizeXLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        visible: root.localMeridiemStr !== ""
                        text: root.localMeridiemStr
                        font.pixelSize: Theme.fontSizeSmall
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
            id: cityRepeater
            model: ClockService.worldClocks.length

            // Index of the slot whose resting rect contains the grid point, or -1.
            function slotAt(px, py) {
                for (let i = 0; i < count; i++) {
                    const it = itemAt(i);
                    if (it && px >= it.x && px < it.x + it.width + gridRoot.spacing && py >= it.y && py < it.y + it.height + gridRoot.spacing)
                        return i;
                }
                return -1;
            }

            Rectangle {
                id: cityPill
                required property int index

                readonly property var modelData: ClockService.worldClocks[index] || { city: "", country: "", tz: "", offsetMin: 0 }
                readonly property color cityColor: root.getCityAccent(index)
                readonly property bool isHovered: pillHover.hovered || root.hoveredCityIndex === index
                readonly property bool isBeingDragged: root.draggingIndex === index
                readonly property var timeInfo: ClockService.getCityTimeInfo(modelData, root.effectiveNow)
                property real dragDx: 0
                property real dragDy: 0
                property real shiftX: {
                    const s = root.previewSlot(index);
                    const a = s !== index ? cityRepeater.itemAt(s) : null;
                    return a ? a.x - x : 0;
                }
                property real shiftY: {
                    const s = root.previewSlot(index);
                    const a = s !== index ? cityRepeater.itemAt(s) : null;
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
                    x: cityPill.isBeingDragged ? cityPill.dragDx : cityPill.shiftX
                    y: cityPill.isBeingDragged ? cityPill.dragDy : cityPill.shiftY
                }

                width: gridRoot.cardWidth
                height: 76
                radius: isBeingDragged ? Theme.cornerRadiusXL : (isHovered ? Theme.cornerRadiusXL : Theme.cornerRadiusL)
                scale: isBeingDragged ? 1.04 : (pillDragArea.pressed && pillDragArea.dragIntentEstablished ? 0.98 : 1.0)
                z: isBeingDragged ? 100 : 1
                color: isBeingDragged
                    ? Theme.blend(Theme.surfaceContainerHighest, cityColor, Theme.stateLayerDrag)
                    : (isHovered ? Theme.surfaceContainerHigh : Theme.surfaceContainerLow)
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


                // Drag-to-reorder across the grid (deferred commit on release)
                MouseArea {
                    id: pillDragArea
                    anchors.fill: parent
                    preventStealing: ClockService.worldClockEditMode || dragIntentEstablished
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    readonly property real dragThreshold: 6
                    property point pressGridPos: Qt.point(0, 0)
                    property bool dragIntentEstablished: false

                    function beginDrag() {
                        dragIntentEstablished = true;
                        root.draggingIndex = cityPill.index;
                        root.dropTargetIndex = cityPill.index;
                    }

                    function endDrag(commit) {
                        const from = root.draggingIndex;
                        const to = root.dropTargetIndex;
                        cityPill.dragDx = 0;
                        cityPill.dragDy = 0;
                        dragIntentEstablished = false;
                        root.draggingIndex = -1;
                        root.dropTargetIndex = -1;
                        if (commit && from >= 0 && to >= 0 && from !== to)
                            Qt.callLater(() => ClockService.moveWorldClock(from, to));
                    }

                    onPressAndHold: beginDrag()
                    onPressed: mouse => {
                        pressGridPos = mapToItem(gridRoot, mouse.x, mouse.y);
                        dragIntentEstablished = false;
                        if (ClockService.worldClockEditMode)
                            beginDrag();
                    }
                    onPositionChanged: mouse => {
                        if (!pressed)
                            return;
                        // Grid coordinates include the pill's Translate, so the delta never feeds back on itself.
                        const p = mapToItem(gridRoot, mouse.x, mouse.y);
                        const dx = p.x - pressGridPos.x;
                        const dy = p.y - pressGridPos.y;
                        if (!dragIntentEstablished) {
                            if (Math.abs(dx) <= dragThreshold && Math.abs(dy) <= dragThreshold)
                                return;
                            beginDrag();
                        }
                        cityPill.dragDx = dx;
                        cityPill.dragDy = dy;
                        const target = cityRepeater.slotAt(p.x, p.y);
                        if (target >= 0)
                            root.dropTargetIndex = target;
                    }
                    onReleased: endDrag(true)
                    onCanceled: endDrag(false)
                }

                DTooltipHost {
                    target: cityPill
                    hoverArea: pillDragArea
                    text: ClockService.worldClockEditMode ? "Drag to reorder city" : "Hold and drag to reorder city"
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
                            font.pixelSize: Theme.fontSizeXLarge
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            visible: cityPill.timeInfo.meridiem !== ""
                            text: cityPill.timeInfo.meridiem
                            font.pixelSize: Theme.fontSizeSmall
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
