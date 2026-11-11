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

                            delegate: ClockRow {
                                id: overdueRow
                                required property var modelData
                                required property int index
                                readonly property int remIdx: modelData.index
                                readonly property var rem: modelData.item

                                width: parent.width
                                clickable: true
                                iconName: "error_outline"
                                accent: "orange"
                                title: overdueRow.rem.title || "Reminder"
                                subtitle: overdueRow.rem.date === root.todayKey ? "Earlier today" : `Scheduled: ${ClockService.formatReminderSchedule(overdueRow.rem)}`
                                subtitleColor: Theme.error
                                isFirstInGroup: index === 0
                                isLastInGroup: index === root.overdueReminders.length - 1
                                onClicked: ClockService.openEditReminderSheet(overdueRow.remIdx)

                                leading: Rectangle {
                                    id: overdueCheck
                                    width: 24
                                    height: 24
                                    radius: 12
                                    border.width: 1.5
                                    border.color: overdueCheckHover.hovered ? Theme.primary : Theme.outlineMedium
                                    color: overdueCheckHover.hovered ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }
                                    Behavior on border.color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }

                                    HoverHandler {
                                        id: overdueCheckHover
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.toggleReminder(overdueRow.remIdx, true)
                                    }
                                }

                                trailing: Row {
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter

                                    DIcon {
                                        visible: Boolean(overdueRow.rem.important)
                                        name: "star"
                                        size: Theme.iconSizeSmall
                                        color: "#FFA726"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    NumericText {
                                        text: root._formatTimeDisp(overdueRow.rem.hour, overdueRow.rem.minute)
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        color: Theme.error
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
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

                            delegate: ClockRow {
                                id: todayRow
                                required property var modelData
                                required property int index
                                readonly property int remIdx: modelData.index
                                readonly property var rem: modelData.item

                                width: parent.width
                                clickable: true
                                iconName: "today"
                                accent: "blue"
                                title: todayRow.rem.title || "Reminder"
                                subtitle: ClockService.formatReminderSchedule(todayRow.rem)
                                isFirstInGroup: index === 0
                                isLastInGroup: index === root.todayReminders.length - 1
                                onClicked: ClockService.openEditReminderSheet(todayRow.remIdx)

                                leading: Rectangle {
                                    id: todayCheck
                                    width: 24
                                    height: 24
                                    radius: 12
                                    border.width: 1.5
                                    border.color: todayCheckHover.hovered ? Theme.primary : Theme.outlineMedium
                                    color: todayCheckHover.hovered ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }
                                    Behavior on border.color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }

                                    HoverHandler {
                                        id: todayCheckHover
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.toggleReminder(todayRow.remIdx, true)
                                    }
                                }

                                trailing: Row {
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter

                                    DIcon {
                                        visible: Boolean(todayRow.rem.important)
                                        name: "star"
                                        size: Theme.iconSizeSmall
                                        color: "#FFA726"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    NumericText {
                                        text: root._formatTimeDisp(todayRow.rem.hour, todayRow.rem.minute)
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
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

                            delegate: ClockRow {
                                id: futureRow
                                required property var modelData
                                required property int index
                                readonly property int remIdx: modelData.index
                                readonly property var rem: modelData.item

                                width: parent.width
                                clickable: true
                                iconName: "event"
                                accent: "purple"
                                title: futureRow.rem.title || "Reminder"
                                subtitle: ClockService.formatReminderSchedule(futureRow.rem)
                                isFirstInGroup: index === 0
                                isLastInGroup: index === root.upcomingFutureReminders.length - 1
                                onClicked: ClockService.openEditReminderSheet(futureRow.remIdx)

                                leading: Rectangle {
                                    id: futureCheck
                                    width: 24
                                    height: 24
                                    radius: 12
                                    border.width: 1.5
                                    border.color: futureCheckHover.hovered ? Theme.primary : Theme.outlineMedium
                                    color: futureCheckHover.hovered ? Theme.withAlpha(Theme.primary, 0.15) : "transparent"
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }
                                    Behavior on border.color {
                                        enabled: Theme.animationsEnabled
                                        ColorAnimation { duration: ClockMetrics.fadeDuration }
                                    }

                                    HoverHandler {
                                        id: futureCheckHover
                                        cursorShape: Qt.PointingHandCursor
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ClockService.toggleReminder(futureRow.remIdx, true)
                                    }
                                }

                                trailing: Row {
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter

                                    DIcon {
                                        visible: Boolean(futureRow.rem.important)
                                        name: "star"
                                        size: Theme.iconSizeSmall
                                        color: "#FFA726"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    NumericText {
                                        text: root._formatTimeDisp(futureRow.rem.hour, futureRow.rem.minute)
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }
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

                        delegate: ClockRow {
                            id: doneRow
                            required property var modelData
                            required property int index
                            readonly property int remIdx: modelData.index
                            readonly property var rem: modelData.item

                            width: parent.width
                            clickable: true
                            iconName: "check_circle"
                            accent: "green"
                            title: doneRow.rem.title || "Reminder"
                            subtitle: `Completed • ${ClockService.formatReminderSchedule(doneRow.rem)}`
                            isFirstInGroup: index === 0
                            isLastInGroup: index === root.doneReminders.length - 1
                            onClicked: ClockService.openEditReminderSheet(doneRow.remIdx)

                            leading: Rectangle {
                                id: doneCheck
                                width: 24
                                height: 24
                                radius: 12
                                color: doneCheckHover.hovered ? Theme.withAlpha(Theme.primary, 0.8) : Theme.primary
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on color {
                                    enabled: Theme.animationsEnabled
                                    ColorAnimation { duration: ClockMetrics.fadeDuration }
                                }

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "check"
                                    size: 14
                                    color: Theme.onPrimary
                                }

                                HoverHandler {
                                    id: doneCheckHover
                                    cursorShape: Qt.PointingHandCursor
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClockService.toggleReminder(doneRow.remIdx, false)
                                }
                            }

                            trailing: Row {
                                spacing: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter

                                DIcon {
                                    visible: Boolean(doneRow.rem.important)
                                    name: "star"
                                    size: Theme.iconSizeSmall
                                    color: "#FFA726"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                NumericText {
                                    text: root._formatTimeDisp(doneRow.rem.hour, doneRow.rem.minute)
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
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
