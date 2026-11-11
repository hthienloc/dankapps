pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

DBottomSheet {
    id: root

    opened: ClockService.reminderEditSheetOpen
    title: ClockService.editingReminderIndex >= 0 ? "Edit Reminder" : "New Reminder"
    sheetHeight: Math.min(520, parent.height - 40)

    onDismissRequested: {
        ClockService.reminderEditSheetOpen = false;
        ClockService.editingReminderIndex = -1;
        titleField.text = "";
        showDatePicker = false;
        root.forceActiveFocus();
    }

    property string inputTitle: ""
    property string inputDate: ClockService._todayDateKey()
    property int inputHour: 9
    property int inputMinute: 0
    property string inputRepeat: "none"
    property bool inputImportant: false
    property bool showDatePicker: false
    property date calendarViewDate: new Date()

    function _formatDate(d) {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function _formatDateDisplay(dateKey) {
        if (!dateKey) return "";
        const curKey = ClockService._todayDateKey();
        if (dateKey === curKey) return "Today";
        const cur = ClockService.now || new Date();
        const tom = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1);
        if (dateKey === _formatDate(tom)) return "Tomorrow";
        const parts = dateKey.split("-");
        if (parts.length === 3) {
            const d = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
            return Qt.formatDate(d, "ddd, MMM d, yyyy");
        }
        return dateKey;
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

    onOpenedChanged: {
        if (opened) {
            showDatePicker = false;
            const idx = ClockService.editingReminderIndex;
            if (idx >= 0 && idx < ClockService.reminders.length) {
                const r = ClockService.reminders[idx];
                inputTitle = r.title || "";
                inputDate = r.date || ClockService._todayDateKey();
                inputHour = typeof r.hour === "number" ? r.hour : 9;
                inputMinute = typeof r.minute === "number" ? r.minute : 0;
                inputRepeat = r.repeat || "none";
                inputImportant = Boolean(r.important);
            } else {
                inputTitle = "";
                const cur = ClockService.now || new Date();
                const nextHour = new Date(cur.getTime() + 60 * 60000);
                inputDate = _formatDate(nextHour);
                inputHour = nextHour.getHours();
                inputMinute = 0;
                inputRepeat = "none";
                inputImportant = false;
            }
            titleField.text = inputTitle;
            const curD = new Date(inputDate + "T12:00:00");
            calendarViewDate = isNaN(curD.getTime()) ? (ClockService.now || new Date()) : curD;
            titleField.forceActiveFocus();
        }
    }

    function openTimePicker() {
        ClockService.reminderTimePickerHour = root.inputHour;
        ClockService.reminderTimePickerMinute = root.inputMinute;
        ClockService.reminderTimePickerOpen = true;
    }

    Connections {
        target: ClockService
        function onReminderTimePickerOpenChanged() {
            if (!ClockService.reminderTimePickerOpen && root.opened) {
                root.inputHour = ClockService.reminderTimePickerHour;
                root.inputMinute = ClockService.reminderTimePickerMinute;
            }
        }
    }

    function saveReminder() {
        const titleStr = titleField.text.trim();
        if (titleStr.length === 0)
            return;

        const remObj = {
            title: titleStr,
            date: root.inputDate,
            hour: root.inputHour,
            minute: root.inputMinute,
            repeat: root.inputRepeat,
            important: root.inputImportant,
            enabled: true
        };

        if (ClockService.editingReminderIndex >= 0) {
            ClockService.updateReminder(ClockService.editingReminderIndex, remObj);
        } else {
            ClockService.addReminder(remObj);
        }

        ClockService.reminderEditSheetOpen = false;
        ClockService.editingReminderIndex = -1;
        titleField.text = "";
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // Title input field
        DTextField {
            id: titleField
            width: parent.width
            placeholderText: "What do you need to be reminded of?"
            leftIconName: "edit_note"
            showClearButton: true
            onTextChanged: root.inputTitle = text
            Keys.onReturnPressed: root.saveReminder()
            Keys.onEnterPressed: root.saveReminder()
        }

        // Quick Date presets + Pick Date Customizer
        Row {
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { label: "Today", idx: 0 },
                    { label: "Tomorrow", idx: 1 },
                    { label: "In 2 days", idx: 2 }
                ]

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    readonly property string targetDate: {
                        const cur = ClockService.now || new Date();
                        const d = new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + modelData.idx);
                        return root._formatDate(d);
                    }
                    readonly property bool isSelected: !root.showDatePicker && root.inputDate === targetDate

                    height: 32
                    width: dateChipText.implicitWidth + 24
                    radius: Theme.cornerRadiusFull
                    color: isSelected ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: isSelected ? Theme.primary : Theme.outlineMedium

                    StyledText {
                        id: dateChipText
                        anchors.centerIn: parent
                        text: parent.modelData.label
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: parent.isSelected ? Theme.fontWeightBold : Theme.fontWeight
                        color: parent.isSelected ? Theme.onPrimaryContainer : Theme.surfaceText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showDatePicker = false;
                            root.inputDate = parent.targetDate;
                        }
                    }
                }
            }

            // Pick Date Button (Specific Date Picker toggle)
            Rectangle {
                readonly property bool isCustomDate: {
                    const cur = ClockService.now || new Date();
                    const d0 = root._formatDate(cur);
                    const d1 = root._formatDate(new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 1));
                    const d2 = root._formatDate(new Date(cur.getFullYear(), cur.getMonth(), cur.getDate() + 2));
                    return root.showDatePicker || (root.inputDate !== d0 && root.inputDate !== d1 && root.inputDate !== d2);
                }

                height: 32
                width: customDateRow.implicitWidth + 24
                radius: Theme.cornerRadiusFull
                color: isCustomDate ? Theme.primaryContainer : Theme.surfaceContainerHigh
                border.width: 1
                border.color: isCustomDate ? Theme.primary : Theme.outlineMedium

                Row {
                    id: customDateRow
                    anchors.centerIn: parent
                    spacing: 4

                    DIcon {
                        name: "calendar_month"
                        size: 16
                        color: parent.parent.isCustomDate ? Theme.onPrimaryContainer : Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: parent.parent.isCustomDate && !root.showDatePicker ? root._formatDateDisplay(root.inputDate) : "Pick date"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: parent.parent.isCustomDate ? Theme.fontWeightBold : Theme.fontWeight
                        color: parent.parent.isCustomDate ? Theme.onPrimaryContainer : Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.showDatePicker = !root.showDatePicker;
                    }
                }
            }
        }

        // Inline Month Calendar for selecting a specific date
        Rectangle {
            visible: root.showDatePicker
            width: parent.width
            height: calendarCol.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadiusXL
            color: Theme.surfaceContainerLow
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium

            Column {
                id: calendarCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                // Calendar Month Header + Nav Buttons
                Item {
                    width: parent.width
                    height: 32

                    DIconButton {
                        iconName: "chevron_left"
                        size: "s"
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            const d = new Date(root.calendarViewDate);
                            d.setMonth(d.getMonth() - 1);
                            root.calendarViewDate = d;
                        }
                    }

                    StyledText {
                        anchors.centerIn: parent
                        text: Qt.formatDate(root.calendarViewDate, "MMMM yyyy")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }

                    DIconButton {
                        iconName: "chevron_right"
                        size: "s"
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            const d = new Date(root.calendarViewDate);
                            d.setMonth(d.getMonth() + 1);
                            root.calendarViewDate = d;
                        }
                    }
                }

                // Month Grid
                DMonthGrid {
                    id: monthGrid
                    width: parent.width
                    height: 200
                    displayDate: root.calendarViewDate
                    selectedDate: {
                        const d = new Date(root.inputDate + "T12:00:00");
                        return isNaN(d.getTime()) ? new Date() : d;
                    }
                    onDayClicked: date => {
                        root.inputDate = root._formatDate(date);
                        root.showDatePicker = false;
                    }
                }
            }
        }

        // Time, Repeat & Important Settings Group
        ClockGroup {
            width: parent.width

            ClockRow {
                width: parent.width
                title: "Time"
                subtitle: root._formatTimeDisp(root.inputHour, root.inputMinute)
                iconName: "schedule"
                accent: "blue"
                clickable: true
                isFirstInGroup: true
                isLastInGroup: false
                onClicked: root.openTimePicker()

                DButton {
                    text: root._formatTimeDisp(root.inputHour, root.inputMinute)
                    buttonHeight: Theme.buttonHeightXS
                    backgroundColor: Theme.surfaceContainerHighest
                    textColor: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: root.openTimePicker()
                }
            }

            ClockRow {
                width: parent.width
                title: "Repeat"
                subtitle: {
                    switch (root.inputRepeat) {
                    case "daily": return "Daily";
                    case "weekdays": return "Weekdays (Mon-Fri)";
                    case "weekly": return "Weekly";
                    default: return "Never (One-time)";
                    }
                }
                iconName: "repeat"
                accent: "purple"
                clickable: false
                isFirstInGroup: false
                isLastInGroup: false

                DButtonGroup {
                    selectionMode: "single"
                    size: "small"
                    checkEnabled: false
                    model: ["None", "Daily", "Weekdays", "Weekly"]
                    currentIndex: {
                        switch (root.inputRepeat) {
                        case "daily": return 1;
                        case "weekdays": return 2;
                        case "weekly": return 3;
                        default: return 0;
                        }
                    }
                    anchors.verticalCenter: parent.verticalCenter
                    onSelectionChanged: (idx, sel) => {
                        if (sel) {
                            const map = ["none", "daily", "weekdays", "weekly"];
                            root.inputRepeat = map[idx] || "none";
                        }
                    }
                }
            }

            ClockRow {
                width: parent.width
                title: "Important"
                iconName: "star"
                accent: root.inputImportant ? "orange" : ""
                clickable: true
                isFirstInGroup: false
                isLastInGroup: true
                onClicked: root.inputImportant = !root.inputImportant

                DToggle {
                    hideText: true
                    checked: root.inputImportant
                    anchors.verticalCenter: parent.verticalCenter
                    onToggled: isChecked => {
                        root.inputImportant = isChecked;
                    }
                }
            }
        }

        // Bottom action buttons
        Item {
            width: parent.width
            height: 48

            // Delete button (visible when editing an existing reminder)
            DButton {
                visible: ClockService.editingReminderIndex >= 0
                text: "Delete"
                iconName: "delete_outline"
                buttonHeight: Theme.buttonHeightS
                backgroundColor: Theme.withAlpha(Theme.error, 0.15)
                textColor: Theme.error
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    const idx = ClockService.editingReminderIndex;
                    ClockService.reminderEditSheetOpen = false;
                    ClockService.editingReminderIndex = -1;
                    if (idx >= 0)
                        ClockService.removeReminder(idx);
                }
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingS

                DButton {
                    text: "Cancel"
                    buttonHeight: Theme.buttonHeightS
                    backgroundColor: Theme.secondaryContainer
                    textColor: Theme.onSecondaryContainer
                    onClicked: {
                        ClockService.reminderEditSheetOpen = false;
                        ClockService.editingReminderIndex = -1;
                    }
                }

                DButton {
                    text: ClockService.editingReminderIndex >= 0 ? "Save Changes" : "Create Reminder"
                    iconName: "check"
                    buttonHeight: Theme.buttonHeightS
                    enabled: root.inputTitle.trim().length > 0
                    opacity: enabled ? 1.0 : 0.45
                    onClicked: root.saveReminder()
                }
            }
        }
    }
}
