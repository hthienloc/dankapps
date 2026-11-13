pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    anchors.fill: parent

    property string activeFilter: "upcoming" // "upcoming" | "today" | "important" | "done"

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

    // Overdue items: enabled, one-time, past today or earlier today (and not marked completed)
    readonly property var overdueReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        const cur = ClockService.now || new Date();
        const curHM = cur.getHours() * 60 + cur.getMinutes();
        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r || !r.enabled || r.completedDateKey === todayKey)
                continue;
            if (root.activeFilter === "important" && !r.important)
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

    // Today items: enabled, matching today or repeating (daily, every2h, weekdays, weekly, monthly)
    readonly property var todayReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        const cur = ClockService.now || new Date();
        const curHM = cur.getHours() * 60 + cur.getMinutes();
        const jsDay = cur.getDay();
        const dayOfMonth = cur.getDate();

        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r || !r.enabled || r.completedDateKey === todayKey)
                continue;

            if (root.activeFilter === "important" && !r.important)
                continue;

            // Enforce start date: do not show recurring reminders before start date
            if (r.date && todayKey < r.date)
                continue;

            const rep = r.repeat || "none";
            if (rep === "none") {
                if (r.date === todayKey && (r.hour * 60 + r.minute) >= curHM) {
                    res.push({ index: i, item: r });
                }
            } else if (rep === "daily" || rep === "every2h") {
                res.push({ index: i, item: r });
            } else if (rep === "weekdays") {
                if (jsDay >= 1 && jsDay <= 5)
                    res.push({ index: i, item: r });
            } else if (rep === "weekly") {
                const rDate = r.date ? new Date(r.date + "T12:00:00") : cur;
                if (rDate.getDay() === jsDay) {
                    res.push({ index: i, item: r });
                }
            } else if (rep === "monthly") {
                const rDate = r.date ? new Date(r.date + "T12:00:00") : cur;
                if (rDate.getDate() === dayOfMonth) {
                    res.push({ index: i, item: r });
                }
            }
        }
        return res;
    }

    // Upcoming future items (Tomorrow onwards)
    readonly property var upcomingFutureReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        if (root.activeFilter === "today") return [];
        const res = [];
        const cur = ClockService.now || new Date();
        const tom = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1);
        const tomKey = _formatDate(tom);

        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r || !r.enabled || r.completedDateKey === todayKey)
                continue;

            if (root.activeFilter === "important" && !r.important)
                continue;

            const rep = r.repeat || "none";
            if (rep === "none") {
                if (r.date && r.date >= tomKey) {
                    res.push({ index: i, item: r });
                }
            } else {
                // For recurring, if it didn't match today, show in upcoming schedule
                res.push({ index: i, item: r });
            }
        }
        return res;
    }

    // Done items: disabled one-time items, or items with completedDateKey matching today
    readonly property var doneReminders: {
        void ClockService.reminderRevision;
        if (!remindersList) return [];
        const res = [];
        for (let i = 0; i < remindersList.length; i++) {
            const r = remindersList[i];
            if (!r) continue;
            if (root.activeFilter === "important" && !r.important)
                continue;
            if (!r.enabled || r.completedDateKey === todayKey) {
                res.push({ index: i, item: r });
            }
        }
        return res;
    }

    readonly property bool hasAnyActive: overdueReminders.length > 0 || todayReminders.length > 0 || upcomingFutureReminders.length > 0

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

            // 1. Next Incoming Reminder Banner (M3E Hero Notice Banner like Alarms)
            DCard {
                id: incomingCard
                visible: ClockService.nextIncomingReminder !== null
                width: parent.width
                height: incomingInner.implicitHeight + pad * 2
                pad: Theme.spacingL
                tone: "primary"
                clickable: true
                restRadius: Theme.cornerRadiusXL
                bodyRadius: ClockMetrics.cardRadius(focusTarget.pressed, focusTarget.hovered, false)
                onClicked: {
                    const inc = ClockService.nextIncomingReminder;
                    if (inc)
                        ClockService.openEditReminderSheet(inc.index);
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
                                text: "NEXT REMINDER"
                                color: Theme.primary
                                textColor: Theme.onPrimary
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                readonly property var inc: ClockService.nextIncomingReminder
                                text: inc ? inc.relativeText : ""
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightBold
                                color: incomingCard.contentColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        StyledText {
                            readonly property var inc: ClockService.nextIncomingReminder
                            text: inc ? `${inc.timeText}  •  ${inc.reminder.title || "Reminder"} (${inc.dayRelation})` : ""
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Theme.fontWeightBold
                            color: incomingCard.contentColor
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Row {
                        id: bannerActionsRow
                        visible: ClockService.nextIncomingReminder !== null
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DButton {
                            text: "Done"
                            iconName: "check"
                            buttonHeight: Theme.buttonHeightXS
                            backgroundColor: Theme.surfaceContainerHigh
                            textColor: Theme.surfaceText
                            onClicked: {
                                const inc = ClockService.nextIncomingReminder;
                                if (inc)
                                    ClockService.toggleReminder(inc.index, true);
                            }
                        }
                    }
                }
            }

            // 2. Segmented Filter Tabs (DButtonGroup style like ClockSettingsModal)
            Item {
                width: parent.width
                height: filterTabs.height

                DButtonGroup {
                    id: filterTabs
                    width: Math.min(480, parent.width)
                    anchors.horizontalCenter: parent.horizontalCenter
                    fillWidth: true
                    checkEnabled: true
                    selectionMode: "single"
                    size: "small"
                    model: [
                        { icon: "alarm", text: "Upcoming" },
                        { icon: "today", text: "Today" },
                        { icon: "star", text: "Important" },
                        { icon: "check_circle", text: "Done" }
                    ]
                    currentIndex: {
                        switch (root.activeFilter) {
                        case "today": return 1;
                        case "important": return 2;
                        case "done": return 3;
                        default: return 0;
                        }
                    }
                    onSelectionChanged: (idx, sel) => {
                        if (sel) {
                            const map = ["upcoming", "today", "important", "done"];
                            root.activeFilter = map[idx] || "upcoming";
                        }
                    }
                }
            }

            // 3. Active Reminders Grouped List (Upcoming, Today, Important)
            Column {
                visible: root.activeFilter !== "done"
                width: parent.width
                spacing: ClockMetrics.cardGap

                // Overdue Section
                Column {
                    visible: root.overdueReminders.length > 0
                    width: parent.width
                    spacing: 0

                    ClockSectionLabel {
                        width: parent.width
                        text: "Overdue"
                    }

                    ClockGroup {
                        width: parent.width

                        Repeater {
                            model: root.overdueReminders

                            delegate: ClockReminderRow {
                                modelData: modelData
                                index: index
                                listCount: root.overdueReminders.length
                                isDoneGroup: false
                                onClicked: ClockService.openEditReminderSheet(remIdx)
                            }
                        }
                    }
                }

                // Today Section
                Column {
                    visible: root.todayReminders.length > 0
                    width: parent.width
                    spacing: 0

                    ClockSectionLabel {
                        width: parent.width
                        text: "Today"
                    }

                    ClockGroup {
                        width: parent.width

                        Repeater {
                            model: root.todayReminders

                            delegate: ClockReminderRow {
                                modelData: modelData
                                index: index
                                listCount: root.todayReminders.length
                                isDoneGroup: false
                                onClicked: ClockService.openEditReminderSheet(remIdx)
                            }
                        }
                    }
                }

                // Upcoming Future Section
                Column {
                    visible: root.activeFilter === "upcoming" && root.upcomingFutureReminders.length > 0
                    width: parent.width
                    spacing: 0

                    ClockSectionLabel {
                        width: parent.width
                        text: "Upcoming"
                    }

                    ClockGroup {
                        width: parent.width

                        Repeater {
                            model: root.upcomingFutureReminders

                            delegate: ClockReminderRow {
                                modelData: modelData
                                index: index
                                listCount: root.upcomingFutureReminders.length
                                isDoneGroup: false
                                onClicked: ClockService.openEditReminderSheet(remIdx)
                            }
                        }
                    }
                }

                // Empty State for Active View
                ClockEmptyState {
                    visible: !root.hasAnyActive
                    cardHeight: 220
                    iconName: "notifications_none"
                    title: root.activeFilter === "important" ? "No Important Reminders" : (root.activeFilter === "today" ? "No Reminders for Today" : "No Upcoming Reminders")
                    subtitle: "Click the + button below to create a new reminder."
                }
            }

            // 4. Completed / Done View
            Column {
                visible: root.activeFilter === "done"
                width: parent.width
                spacing: 0

                ClockSectionLabel {
                    visible: root.doneReminders.length > 0
                    width: parent.width
                    text: "Completed"
                }

                ClockGroup {
                    visible: root.doneReminders.length > 0
                    width: parent.width

                    Repeater {
                        model: root.doneReminders

                        delegate: ClockReminderRow {
                            modelData: modelData
                            index: index
                            listCount: root.doneReminders.length
                            isDoneGroup: true
                            onClicked: ClockService.openEditReminderSheet(remIdx)
                        }
                    }
                }

                ClockEmptyState {
                    visible: root.doneReminders.length === 0
                    cardHeight: 220
                    iconName: "check_circle_outline"
                    title: "No Completed Reminders"
                    subtitle: "Check off reminders in Upcoming to mark them as done."
                }
            }
        }
    }

    // Floating action button anchored to bottom-right
    DFab {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spacingXL
        iconName: "add"
        colorRole: "primary"
        tooltipText: "Create a new reminder"
        onClicked: ClockService.openAddReminderSheet()
    }
}
