pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

DBottomSheet {
    id: root

    opened: ClockService.vacationSheetOpen
    title: "Vacation Mode"
    sheetHeight: Math.min(420, parent.height - 40)

    onDismissRequested: {
        ClockService.vacationSheetOpen = false;
        root.forceActiveFocus();
    }

    readonly property string todayStr: ClockService._todayDateKey()
    readonly property var currentVacation: ClockService.vacation
    readonly property bool isEnabled: Boolean(currentVacation && currentVacation.enabled)
    readonly property string startDateStr: (currentVacation && currentVacation.startDate) || todayStr
    readonly property string endDateStr: (currentVacation && currentVacation.endDate) || startDateStr

    readonly property int totalDaysCount: {
        const s = new Date(startDateStr);
        const e = new Date(endDateStr);
        const diffMs = e.getTime() - s.getTime();
        return Math.max(1, Math.round(diffMs / 86400000) + 1);
    }

    function _formatDate(d) {
        return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
    }

    function _applyPreset(idx) {
        const now = ClockService.now;
        const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const sStr = _formatDate(start);
        let eStr = sStr;

        if (idx === 0) {
            // Today only
            eStr = sStr;
        } else if (idx === 1) {
            // Until end of weekend (Sunday)
            const jsDay = start.getDay(); // 0=Sun .. 6=Sat
            const daysUntilSun = (7 - jsDay) % 7;
            const end = new Date(start.getTime() + daysUntilSun * 86400000);
            eStr = _formatDate(end);
        } else if (idx === 2) {
            // Next 3 days
            const end = new Date(start.getTime() + 2 * 86400000);
            eStr = _formatDate(end);
        } else if (idx === 3) {
            // 1 week
            const end = new Date(start.getTime() + 6 * 86400000);
            eStr = _formatDate(end);
        }
        ClockService.setVacationMode(true, sStr, eStr);
    }

    function _adjustDays(deltaDays) {
        const s = new Date(startDateStr);
        const curEnd = new Date(endDateStr);
        const nextEnd = new Date(curEnd.getTime() + deltaDays * 86400000);
        if (nextEnd >= s) {
            ClockService.setVacationMode(true, startDateStr, _formatDate(nextEnd));
        }
    }

    Column {
        width: parent.width
        spacing: Theme.spacingM

        // Master Switch Row (Full row clickable, persists immediately)
        ClockRow {
            width: parent.width
            title: "Silence all alarms"
            subtitle: root.isEnabled ? "Pause all active alarms" : "Alarms will go off as scheduled"
            iconName: "beach_access"
            accent: root.isEnabled ? "orange" : ""
            clickable: true
            isFirstInGroup: true
            isLastInGroup: true
            onClicked: {
                if (root.isEnabled) {
                    ClockService.disableVacationMode();
                } else {
                    root._applyPreset(2); // default to 3 days when toggled on
                }
            }

            DToggle {
                hideText: true
                checked: root.isEnabled
                anchors.verticalCenter: parent.verticalCenter
                onToggled: isChecked => {
                    if (isChecked)
                        root._applyPreset(2);
                    else
                        ClockService.disableVacationMode();
                }
            }
        }

        // Section: Presets
        Column {
            width: parent.width
            spacing: Theme.spacingXS
            opacity: root.isEnabled ? 1.0 : 0.45
            enabled: root.isEnabled

            StyledText {
                text: "PRESETS"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceVariantText
            }

            DButtonGroup {
                id: presetGroup
                width: parent.width
                size: "small"
                selectionMode: "single"
                checkEnabled: false
                fillWidth: true
                model: ["Today only", "This weekend", "Next 3 days", "1 week"]
                currentIndex: -1
                selectedColor: Theme.primary
                selectedContentColor: Theme.onPrimary
                unselectedColor: Theme.surfaceContainerHigh
                unselectedContentColor: Theme.surfaceText
                onSelectionChanged: (idx, sel) => {
                    if (sel && idx >= 0)
                        root._applyPreset(idx);
                }
            }
        }

        // Section: Date Duration Adjuster Card
        Rectangle {
            width: parent.width
            height: adjustCol.implicitHeight + Theme.spacingL * 2
            radius: Theme.cornerRadiusXL
            color: Theme.surfaceContainerLow
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineLight
            opacity: root.isEnabled ? 1.0 : 0.45
            enabled: root.isEnabled

            Column {
                id: adjustCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                // Date Timeline Bar (Start -> Duration Pill -> End)
                Row {
                    width: parent.width
                    height: 52

                    // Start Block
                    Column {
                        width: (parent.width - 90) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: "STARTS"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightBold
                            color: Theme.surfaceVariantText
                        }

                        StyledText {
                            text: root.startDateStr
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Theme.fontWeightBold
                            color: Theme.surfaceText
                        }
                    }

                    // Duration Badge in the middle
                    Item {
                        width: 90
                        height: parent.height

                        DBadge {
                            anchors.centerIn: parent
                            text: `${root.totalDaysCount} ${root.totalDaysCount === 1 ? 'day' : 'days'}`
                            color: Theme.surfaceContainerHighest
                            textColor: Theme.primary
                        }
                    }

                    // End Block
                    Column {
                        width: (parent.width - 90) / 2
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            anchors.right: parent.right
                            text: "ENDS (INCLUSIVE)"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightBold
                            color: Theme.tertiary
                        }

                        StyledText {
                            anchors.right: parent.right
                            text: root.endDateStr
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Theme.fontWeightBold
                            color: Theme.surfaceText
                        }
                    }
                }

                // Adjust Stepper Buttons
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingS

                    DButton {
                        text: "-1 Day"
                        iconName: "remove"
                        buttonHeight: Theme.buttonHeightS
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        onClicked: root._adjustDays(-1)
                    }

                    DButton {
                        text: "+1 Day"
                        iconName: "add"
                        buttonHeight: Theme.buttonHeightS
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        onClicked: root._adjustDays(1)
                    }

                    DButton {
                        text: "+1 Week"
                        iconName: "date_range"
                        buttonHeight: Theme.buttonHeightS
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        onClicked: root._adjustDays(7)
                    }
                }
            }
        }
    }
}
