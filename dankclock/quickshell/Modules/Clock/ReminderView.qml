pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

    property string activeViewTab: "upcoming" // "upcoming" | "done"
    property string quickInputText: ""
    property string selectedDateKey: ClockService._todayDateKey()
    property int selectedHour: 9
    property int selectedMinute: 0
    property string selectedRepeat: "none" // "none" | "daily" | "weekly" | "every2h"
    property int selectedChipIndex: 0 // 0: In 10 min, 1: In 1 hour, 2: Tomorrow 8:00, 3: Repeat

    readonly property var remindersList: ClockService.reminders
    readonly property string todayKey: ClockService._todayDateKey()

    function _formatDate(d) {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function _formatTimeDisp(hour, minute) {
        const use24 = SettingsData.use24HourClock;
        const m = String(minute).padStart(2, "0");
        if (use24) {
            return `${String(hour).padStart(2, "0")}:${m}`;
        }
        const hDisp = String(hour % 12 || 12);
        const meridiem = hour >= 12 ? "PM" : "AM";
        return `${hDisp}:${m} ${meridiem}`;
    }

    function _timeRemainingText(hour, minute) {
        const cur = ClockService.now || new Date();
        const target = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate(), hour, minute, 0);
        const diffMs = target.getTime() - cur.getTime();
        if (diffMs <= 0)
            return "";
        const totalMins = Math.floor(diffMs / 60000);
        const h = Math.floor(totalMins / 60);
        const m = totalMins % 60;
        if (h > 0 && m > 0)
            return `In ${h}h ${m}m`;
        if (h > 0)
            return `In ${h}h`;
        return `In ${m}m`;
    }

    // Overdue items: enabled, one-time, past today or earlier today
    readonly property var overdueReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        const cur = ClockService.now || new Date();
        const curHM = cur.getHours() * 60 + cur.getMinutes();
        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r || !r.enabled)
                continue;
            const rep = r.repeat || "none";
            if (rep === "none" && r.date) {
                if (r.date < todayKey || (r.date === todayKey && (r.hour * 60 + r.minute) < curHM)) {
                    res.push({ index: i, item: r });
                }
            }
        }
        return res;
    }

    // Today items: enabled, matching today or repeating daily/every2h or weekly on today's weekday
    readonly property var todayReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        const cur = ClockService.now || new Date();
        const curHM = cur.getHours() * 60 + cur.getMinutes();
        const jsDay = cur.getDay();
        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r || !r.enabled)
                continue;
            const rep = r.repeat || "none";
            if (rep === "none") {
                if (r.date === todayKey && (r.hour * 60 + r.minute) >= curHM) {
                    res.push({ index: i, item: r });
                }
            } else if (rep === "daily" || rep === "every2h") {
                res.push({ index: i, item: r });
            } else if (rep === "weekly") {
                const rDate = r.date ? new Date(r.date + "T12:00:00") : cur;
                if (rDate.getDay() === jsDay) {
                    res.push({ index: i, item: r });
                }
            }
        }
        return res;
    }

    // Tomorrow items: enabled, scheduled for tomorrow
    readonly property var tomorrowReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        const cur = ClockService.now || new Date();
        const tom = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1);
        const tomKey = _formatDate(tom);
        const tomJsDay = tom.getDay();
        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r || !r.enabled)
                continue;
            const rep = r.repeat || "none";
            if (rep === "none" && r.date === tomKey) {
                res.push({ index: i, item: r });
            } else if (rep === "weekly") {
                const rDate = r.date ? new Date(r.date + "T12:00:00") : cur;
                if (rDate.getDay() === tomJsDay) {
                    res.push({ index: i, item: r });
                }
            }
        }
        return res;
    }

    // Done items: disabled or finished
    readonly property var doneReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (r && !r.enabled) {
                res.push({ index: i, item: r });
            }
        }
        return res;
    }

    function applyChip(idx) {
        selectedChipIndex = idx;
        const cur = ClockService.now || new Date();
        if (idx === 0) {
            // In 10 min
            const t = new Date(cur.getTime() + 10 * 60000);
            selectedDateKey = _formatDate(t);
            selectedHour = t.getHours();
            selectedMinute = t.getMinutes();
            selectedRepeat = "none";
        } else if (idx === 1) {
            // In 1 hour
            const t = new Date(cur.getTime() + 60 * 60000);
            selectedDateKey = _formatDate(t);
            selectedHour = t.getHours();
            selectedMinute = t.getMinutes();
            selectedRepeat = "none";
        } else if (idx === 2) {
            // Tomorrow 8:00
            const tom = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1);
            selectedDateKey = _formatDate(tom);
            selectedHour = 8;
            selectedMinute = 0;
            selectedRepeat = "none";
        } else if (idx === 3) {
            // Repeat toggle
            if (selectedRepeat === "none") {
                selectedRepeat = "daily";
            } else if (selectedRepeat === "daily") {
                selectedRepeat = "weekly";
            } else if (selectedRepeat === "weekly") {
                selectedRepeat = "every2h";
            } else {
                selectedRepeat = "none";
            }
        }
    }

    function parseNaturalTime(str) {
        if (!str) return null;
        const cur = ClockService.now || new Date();
        const lower = str.toLowerCase();

        // Check relative min/hour: "in 10m", "10 min", "1h", "2 hours"
        const relM = lower.match(/(?:in\s+)?(\d+)\s*(?:m|min)\b/);
        const relH = lower.match(/(?:in\s+)?(\d+)\s*(?:h|hr|hour|hours)\b/);
        if (relM || relH) {
            const addM = relM ? parseInt(relM[1], 10) : 0;
            const addH = relH ? parseInt(relH[1], 10) : 0;
            const target = new Date(cur.getTime() + (addH * 60 + addM) * 60000);
            return {
                date: _formatDate(target),
                hour: target.getHours(),
                minute: target.getMinutes()
            };
        }

        // Check "3pm", "15:00", "8:30"
        const timeMatch = lower.match(/(\d{1,2})(?::(\d{2}))?\s*(am|pm)?/);
        if (timeMatch) {
            let h = parseInt(timeMatch[1], 10);
            let m = timeMatch[2] ? parseInt(timeMatch[2], 10) : 0;
            const modifier = timeMatch[3];
            if (modifier === "pm") {
                if (h < 12) h += 12;
            } else if (modifier === "am") {
                if (h === 12) h = 0;
            }
            if (h >= 0 && h < 24 && m >= 0 && m < 60) {
                // If time has passed today, schedule for tomorrow
                const curHM = cur.getHours() * 60 + cur.getMinutes();
                let targetDate = cur;
                if (h * 60 + m <= curHM) {
                    targetDate = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1);
                }
                return {
                    date: _formatDate(targetDate),
                    hour: h,
                    minute: m
                };
            }
        }
        return null;
    }

    function submitQuickReminder() {
        const raw = quickInputText.trim();
        if (raw.length === 0)
            return;

        let title = raw;
        let dateKey = selectedDateKey;
        let hour = selectedHour;
        let min = selectedMinute;

        // Try natural language parsing if user typed time hints like "Meeting at 3pm"
        const parsed = parseNaturalTime(raw);
        if (parsed) {
            dateKey = parsed.date;
            hour = parsed.hour;
            min = parsed.minute;
        }

        ClockService.addReminder({
            title: title,
            date: dateKey,
            hour: hour,
            minute: min,
            repeat: selectedRepeat,
            enabled: true
        });

        quickInputText = "";
        quickInputField.text = "";
        applyChip(0);
    }

    Component.onCompleted: {
        applyChip(0);
    }

    // Top Header: Segmented Tabs (Upcoming / Done)
    Item {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacingL
        height: 40

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            Rectangle {
                width: 104
                height: 36
                radius: Theme.cornerRadiusFull
                color: root.activeViewTab === "upcoming" ? Theme.primaryContainer : Theme.surfaceContainerHigh

                StyledText {
                    anchors.centerIn: parent
                    text: "Upcoming"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: root.activeViewTab === "upcoming" ? Theme.fontWeightBold : Theme.fontWeight
                    color: root.activeViewTab === "upcoming" ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeViewTab = "upcoming"
                }
            }

            Rectangle {
                width: 80
                height: 36
                radius: Theme.cornerRadiusFull
                color: root.activeViewTab === "done" ? Theme.primaryContainer : Theme.surfaceContainerHigh

                StyledText {
                    anchors.centerIn: parent
                    text: "Done"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: root.activeViewTab === "done" ? Theme.fontWeightBold : Theme.fontWeight
                    color: root.activeViewTab === "done" ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeViewTab = "done"
                }
            }
        }
    }

    // Top Quick Add Bar: Input field + Add button + Quick Chips
    Rectangle {
        id: topInputBar
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingL
        anchors.rightMargin: Theme.spacingL
        anchors.topMargin: Theme.spacingXS
        height: 96
        radius: Theme.cornerRadiusXL
        color: "transparent"

        Column {
            anchors.fill: parent
            spacing: Theme.spacingS

            // Input Row + Add Button
            Row {
                width: parent.width
                spacing: Theme.spacingS

                DTextField {
                    id: quickInputField
                    width: parent.width - 48 - Theme.spacingS
                    height: 48
                    cornerRadius: Theme.cornerRadiusL
                    placeholderText: "Type a reminder (e.g., Meeting at 3pm, Water in 30m)..."
                    leftIconName: "notifications"
                    showClearButton: true
                    onTextChanged: root.quickInputText = text
                    Keys.onReturnPressed: root.submitQuickReminder()
                    Keys.onEnterPressed: root.submitQuickReminder()
                }

                Rectangle {
                    width: 48
                    height: 48
                    radius: Theme.cornerRadiusL
                    color: Theme.primaryContainer
                    anchors.verticalCenter: parent.verticalCenter

                    DIcon {
                        anchors.centerIn: parent
                        name: "add"
                        size: Theme.iconSizeMedium
                        color: Theme.onPrimaryContainer
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitQuickReminder()
                    }
                }
            }

            // Quick Preset Chips (In 10 min, In 1 hour, Tomorrow 8:00, Repeat)
            Row {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        { label: "In 10 min", idx: 0 },
                        { label: "In 1 hour", idx: 1 },
                        { label: "Tomorrow 8:00", idx: 2 },
                        { label: root.selectedRepeat !== "none" ? ("Repeat: " + root.selectedRepeat) : "Repeat", idx: 3 }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.selectedChipIndex === modelData.idx
                        height: 32
                        width: chipLabel.implicitWidth + 24
                        radius: Theme.cornerRadiusFull
                        color: isSelected ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        border.width: 1
                        border.color: isSelected ? Theme.primary : Theme.outlineMedium

                        StyledText {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: parent.modelData.label
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: parent.isSelected ? Theme.fontWeightBold : Theme.fontWeight
                            color: parent.isSelected ? Theme.onPrimaryContainer : Theme.surfaceText
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyChip(parent.modelData.idx)
                        }
                    }
                }
            }
        }
    }

    // Main List Area
    DFlickable {
        id: scrollList
        anchors.top: topInputBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: Theme.spacingM
        anchors.bottomMargin: Theme.spacingS
        clip: true
        contentWidth: width
        contentHeight: listCol.implicitHeight + Theme.spacingL

        Column {
            id: listCol
            width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.spacingM

            // --- UPCOMING VIEW ---
            Column {
                visible: root.activeViewTab === "upcoming"
                width: parent.width
                spacing: Theme.spacingM

                // Overdue Section
                Column {
                    visible: overdueReminders.length > 0
                    width: parent.width
                    spacing: Theme.spacingXS

                    Row {
                        width: parent.width
                        StyledText {
                            text: "Overdue"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightBold
                            color: Theme.surfaceVariantText
                        }
                    }

                    Repeater {
                        model: overdueReminders

                        delegate: DCard {
                            id: overdueCard
                            required property var modelData
                            readonly property int remIndex: modelData.index
                            readonly property var remItem: modelData.item

                            width: parent.width
                            height: overdueInner.implicitHeight + pad * 2
                            pad: Theme.spacingM
                            restRadius: Theme.cornerRadiusL
                            color: ClockMetrics.rowColor

                            Row {
                                id: overdueInner
                                width: parent.width
                                spacing: Theme.spacingM

                                // Circular Checkbox
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    border.width: 1.5
                                    border.color: Theme.outlineMedium
                                    color: "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.toggleReminder(overdueCard.remIndex, false)
                                    }
                                }

                                // Title & Subtitle
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(0, parent.width - 26 - Theme.spacingM - timeText.width - Theme.spacingM - deleteBtn.width)
                                    spacing: 3

                                    StyledText {
                                        text: overdueCard.remItem.title || "Reminder"
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.surfaceText
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Row {
                                        spacing: 4
                                        DIcon {
                                            name: "notifications"
                                            size: Theme.iconSizeSmall
                                            color: Theme.error
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        StyledText {
                                            text: overdueCard.remItem.date === todayKey ? "Earlier today" : "Yesterday"
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                StyledText {
                                    id: timeText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: _formatTimeDisp(overdueCard.remItem.hour, overdueCard.remItem.minute)
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.error
                                }

                                DIconButton {
                                    id: deleteBtn
                                    iconName: "delete_outline"
                                    size: "s"
                                    iconColor: Theme.error
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: ClockService.removeReminder(overdueCard.remIndex)
                                }
                            }
                        }
                    }
                }

                // Today Section
                Column {
                    visible: todayReminders.length > 0
                    width: parent.width
                    spacing: Theme.spacingXS

                    Item {
                        width: parent.width
                        height: 20

                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Today"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightBold
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(todayReminders.length)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    Repeater {
                        model: todayReminders

                        delegate: DCard {
                            id: todayCard
                            required property var modelData
                            readonly property int remIndex: modelData.index
                            readonly property var remItem: modelData.item

                            width: parent.width
                            height: todayInner.implicitHeight + pad * 2
                            pad: Theme.spacingM
                            restRadius: Theme.cornerRadiusL
                            color: ClockMetrics.rowColor

                            Row {
                                id: todayInner
                                width: parent.width
                                spacing: Theme.spacingM

                                // Circular Checkbox
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    border.width: 1.5
                                    border.color: Theme.outlineMedium
                                    color: "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.toggleReminder(todayCard.remIndex, false)
                                    }
                                }

                                // Title & Subtitle
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(0, parent.width - 26 - Theme.spacingM - todayTimeText.width - Theme.spacingM - todayDelBtn.width)
                                    spacing: 4

                                    StyledText {
                                        text: todayCard.remItem.title || "Reminder"
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.surfaceText
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Row {
                                        spacing: 6

                                        // Badge chip for Repeat
                                        Rectangle {
                                            visible: todayCard.remItem.repeat && todayCard.remItem.repeat !== "none"
                                            height: 20
                                            width: repeatBadgeText.implicitWidth + 12
                                            radius: 10
                                            color: Theme.primaryContainer
                                            anchors.verticalCenter: parent.verticalCenter

                                            StyledText {
                                                id: repeatBadgeText
                                                anchors.centerIn: parent
                                                text: {
                                                    const rep = todayCard.remItem.repeat;
                                                    if (rep === "daily") return "Daily";
                                                    if (rep === "weekly") return "Weekly";
                                                    if (rep === "every2h") return "Every 2h";
                                                    return rep;
                                                }
                                                font.pixelSize: Theme.fontSizeSmall - 2
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.onPrimaryContainer
                                            }
                                        }

                                        StyledText {
                                            text: {
                                                const rem = _timeRemainingText(todayCard.remItem.hour, todayCard.remItem.minute);
                                                if (rem) return rem;
                                                const rep = todayCard.remItem.repeat;
                                                if (rep === "weekly") {
                                                    const cur = ClockService.now || new Date();
                                                    return Qt.formatDate(cur, "dddd");
                                                }
                                                return "Today";
                                            }
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                StyledText {
                                    id: todayTimeText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: _formatTimeDisp(todayCard.remItem.hour, todayCard.remItem.minute)
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.surfaceText
                                }

                                DIconButton {
                                    id: todayDelBtn
                                    iconName: "delete_outline"
                                    size: "s"
                                    iconColor: Theme.error
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: ClockService.removeReminder(todayCard.remIndex)
                                }
                            }
                        }
                    }
                }

                // Tomorrow Section
                Column {
                    visible: tomorrowReminders.length > 0
                    width: parent.width
                    spacing: Theme.spacingXS

                    Item {
                        width: parent.width
                        height: 20

                        StyledText {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Tomorrow"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightBold
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(tomorrowReminders.length)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }
                    }

                    Repeater {
                        model: tomorrowReminders

                        delegate: DCard {
                            id: tomCard
                            required property var modelData
                            readonly property int remIndex: modelData.index
                            readonly property var remItem: modelData.item

                            width: parent.width
                            height: tomInner.implicitHeight + pad * 2
                            pad: Theme.spacingM
                            restRadius: Theme.cornerRadiusL
                            color: ClockMetrics.rowColor

                            Row {
                                id: tomInner
                                width: parent.width
                                spacing: Theme.spacingM

                                // Circular Checkbox
                                Rectangle {
                                    width: 26
                                    height: 26
                                    radius: 13
                                    border.width: 1.5
                                    border.color: Theme.outlineMedium
                                    color: "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.toggleReminder(tomCard.remIndex, false)
                                    }
                                }

                                // Title & Subtitle
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.max(0, parent.width - 26 - Theme.spacingM - tomTimeText.width - Theme.spacingM - tomDelBtn.width)
                                    spacing: 4

                                    StyledText {
                                        text: tomCard.remItem.title || "Reminder"
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.surfaceText
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Row {
                                        spacing: 4
                                        DIcon {
                                            name: "notifications"
                                            size: Theme.iconSizeSmall
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        StyledText {
                                            text: tomCard.remItem.repeat && tomCard.remItem.repeat !== "none" ? tomCard.remItem.repeat : "One-time"
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: Theme.surfaceVariantText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }

                                StyledText {
                                    id: tomTimeText
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: _formatTimeDisp(tomCard.remItem.hour, tomCard.remItem.minute)
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.surfaceText
                                }

                                DIconButton {
                                    id: tomDelBtn
                                    iconName: "delete_outline"
                                    size: "s"
                                    iconColor: Theme.error
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: ClockService.removeReminder(tomCard.remIndex)
                                }
                            }
                        }
                    }
                }

                // Empty State when no upcoming items
                ClockEmptyState {
                    visible: overdueReminders.length === 0 && todayReminders.length === 0 && tomorrowReminders.length === 0
                    cardHeight: 200
                    iconName: "notifications_none"
                    title: "No upcoming reminders"
                    subtitle: "Type below and press + to schedule."
                }
            }

            // --- DONE VIEW ---
            Column {
                visible: root.activeViewTab === "done"
                width: parent.width
                spacing: Theme.spacingM

                ClockEmptyState {
                    visible: doneReminders.length === 0
                    cardHeight: 200
                    iconName: "check_circle_outline"
                    title: "No completed reminders"
                    subtitle: "Check off reminders to complete them."
                }

                Repeater {
                    model: doneReminders

                    delegate: DCard {
                        id: doneCard
                        required property var modelData
                        readonly property int remIndex: modelData.index
                        readonly property var remItem: modelData.item

                        width: parent.width
                        height: doneInner.implicitHeight + pad * 2
                        pad: Theme.spacingM
                        restRadius: Theme.cornerRadiusL
                        color: ClockMetrics.rowColor
                        opacity: 0.65

                        Row {
                            id: doneInner
                            width: parent.width
                            spacing: Theme.spacingM

                            // Checkbox (checked state)
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 13
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "check"
                                    size: 16
                                    color: Theme.onPrimary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClockService.toggleReminder(doneCard.remIndex, true)
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Math.max(0, parent.width - 26 - Theme.spacingM - doneTimeText.width - Theme.spacingM - doneDelBtn.width)
                                spacing: 2

                                StyledText {
                                    text: doneCard.remItem.title || "Reminder"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.strikeout: true
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                StyledText {
                                    text: "Completed"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }

                            StyledText {
                                id: doneTimeText
                                anchors.verticalCenter: parent.verticalCenter
                                text: _formatTimeDisp(doneCard.remItem.hour, doneCard.remItem.minute)
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                            }

                            DIconButton {
                                id: doneDelBtn
                                iconName: "delete_outline"
                                size: "s"
                                iconColor: Theme.error
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: ClockService.removeReminder(doneCard.remIndex)
                            }
                        }
                    }
                }
            }
        }
    }
}
