pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "."

FloatingWindow {
    id: window

    readonly property var navDestinations: [
        { icon: "alarm", text: "Alarms" },
        { icon: "public", text: "Clock" },
        { icon: "hourglass_empty", text: "Timers" },
        { icon: "psychology", text: "Pomodoro" },
        { icon: "timer", text: "Stopwatch" }
    ]

    title: `${ClockService.currentTabIndex === 5 ? "Settings" : (navDestinations[ClockService.currentTabIndex]?.text ?? "Clock")} — DankClock`
    minimumSize: Qt.size(ClockMetrics.windowMinWidth, ClockMetrics.windowMinHeight)
    implicitWidth: ClockMetrics.windowWidth
    implicitHeight: ClockMetrics.windowHeight
    color: ClockMetrics.windowBgColor
    visible: true

    FloatingWindowControls {
        id: windowControls
        targetWindow: window
    }

    WindowBlur {
        targetWindow: window
        blurRadius: Style.cornerRadiusL
    }

    Rectangle {
        id: rootContent
        anchors.fill: parent
        color: ClockMetrics.windowBgColor
        focus: true

        // Critical for DCommon widgets (Style.isFloatingWindow(item)) to use elevated card surfaces
        readonly property bool isFloatingWindowSurface: true

        Component.onCompleted: {
            forceActiveFocus();
        }

        Keys.onPressed: event => {
            if (ClockService.citySheetOpen || ClockService.timePickerOpen || ClockService.labelDialogOpen || ClockService.settingsOpen)
                return;

            if (event.modifiers & Qt.ControlModifier) {
                switch (event.key) {
                case Qt.Key_1:
                    ClockService.currentTabIndex = 0;
                    event.accepted = true;
                    return;
                case Qt.Key_2:
                    ClockService.currentTabIndex = 1;
                    event.accepted = true;
                    return;
                case Qt.Key_3:
                    ClockService.currentTabIndex = 2;
                    event.accepted = true;
                    return;
                case Qt.Key_4:
                    ClockService.currentTabIndex = 3;
                    event.accepted = true;
                    return;
                case Qt.Key_5:
                    ClockService.currentTabIndex = 4;
                    event.accepted = true;
                    return;
                case Qt.Key_6:
                case Qt.Key_Comma:
                    ClockService.currentTabIndex = 5;
                    event.accepted = true;
                    return;
                case Qt.Key_Q:
                case Qt.Key_W:
                    ClockService.requestQuit();
                    event.accepted = true;
                    return;
                }
            }

            if (ClockService.currentTabIndex === 2 && !ClockService.timerSetupMode) {
                if (event.key === Qt.Key_Space) {
                    ClockService.toggleTimer(ClockService.activeTimerIndex);
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    ClockService.resetTimer(ClockService.activeTimerIndex);
                    event.accepted = true;
                }
            } else if (ClockService.currentTabIndex === 3) {
                if (event.key === Qt.Key_Space) {
                    ClockService.togglePomodoro();
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    ClockService.resetPomodoro();
                    event.accepted = true;
                } else if (event.key === Qt.Key_S) {
                    ClockService.skipPomodoroPhase();
                    event.accepted = true;
                }
            } else if (ClockService.currentTabIndex === 4) {
                if (event.key === Qt.Key_Space) {
                    ClockService.toggleStopwatch();
                    event.accepted = true;
                } else if (event.key === Qt.Key_L) {
                    ClockService.lapStopwatch();
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    ClockService.resetStopwatch();
                    event.accepted = true;
                }
            }
        }

        DWindowHeader {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            z: 10
            controls: windowControls
            title: "DankClock"
            onCloseRequested: ClockService.requestQuit()
        }

        Item {
            id: sidebar
            anchors.left: parent.left
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            width: Style.navigationRailWidth

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: Theme.spacingM
                anchors.bottomMargin: Theme.spacingM
                anchors.leftMargin: Theme.spacingXS
                anchors.rightMargin: Theme.spacingXS
                spacing: Theme.spacingS

                DNavigationBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    Layout.alignment: Qt.AlignTop
                    orientation: Qt.Vertical
                    evenlySpaced: false
                    spacing: Theme.spacingS
                    labelFontSize: Theme.fontSizeMedium
                    model: window.navDestinations
                    currentIndex: ClockService.currentTabIndex < 5 ? ClockService.currentTabIndex : -1
                    onActivated: index => {
                        ClockService.currentTabIndex = index;
                        rootContent.forceActiveFocus();
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                DNavigationBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: implicitHeight
                    orientation: Qt.Vertical
                    evenlySpaced: false
                    spacing: Theme.spacingS
                    labelFontSize: Theme.fontSizeMedium
                    model: [{ icon: "settings", text: "Settings" }]
                    currentIndex: ClockService.currentTabIndex === 5 ? 0 : -1
                    onActivated: {
                        ClockService.currentTabIndex = 5;
                        rootContent.forceActiveFocus();
                    }
                }
            }
        }

        // Main M3E Content Container Card (Rounded container adjacent to sidebar)
        Rectangle {
            id: contentScope
            anchors.left: sidebar.right
            anchors.leftMargin: Theme.spacingXS
            anchors.top: header.bottom
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacingM
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spacingM
            radius: Theme.cornerRadiusXL
            color: ClockMetrics.paneColor
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium
            clip: true

            AlarmView {
                anchors.fill: parent
                visible: ClockService.currentTabIndex === 0
            }

            WorldClockView {
                anchors.fill: parent
                visible: ClockService.currentTabIndex === 1
            }

            TimerView {
                anchors.fill: parent
                visible: ClockService.currentTabIndex === 2
            }

            PomodoroView {
                anchors.fill: parent
                visible: ClockService.currentTabIndex === 3
            }

            StopwatchView {
                anchors.fill: parent
                visible: ClockService.currentTabIndex === 4
            }

            ClockSettingsModal {
                anchors.fill: parent
                visible: ClockService.currentTabIndex === 5
            }
        }

        // Built-in DTimePicker Modal for Creating / Editing Alarms
        DTimePicker {
            id: alarmTimePicker
            is24Hour: SettingsData.use24HourClock
            title: ClockService.editingAlarmIndex >= 0 ? "Edit Alarm Time" : "New Alarm Time"
            onAccepted: (h, m) => {
                ClockService.commitTimePicker(h, m);
                rootContent.forceActiveFocus();
            }
            onRejected: {
                ClockService.timePickerOpen = false;
                ClockService.editingAlarmIndex = -1;
                rootContent.forceActiveFocus();
            }
        }

        Connections {
            target: ClockService
            function onTimePickerOpenChanged() {
                if (ClockService.timePickerOpen) {
                    if (ClockService.editingAlarmIndex >= 0 && ClockService.editingAlarmIndex < ClockService.alarms.length) {
                        const a = ClockService.alarms[ClockService.editingAlarmIndex];
                        alarmTimePicker.hour = a.hour;
                        alarmTimePicker.minute = a.minute;
                    } else {
                        alarmTimePicker.hour = ClockService.now.getHours();
                        alarmTimePicker.minute = ClockService.now.getMinutes();
                    }
                    alarmTimePicker.open();
                } else if (alarmTimePicker.opened) {
                    alarmTimePicker.close();
                }
            }
        }

        // Add World Clock City Bottom Sheet
        DBottomSheet {
            id: citySheet
            opened: ClockService.citySheetOpen
            title: "Add World Clock City"
            sheetHeight: 440
            onDismissRequested: {
                ClockService.citySheetOpen = false;
                citySearchInput.text = "";
                rootContent.forceActiveFocus();
            }

            DSearchField {
                id: citySearchInput
                width: parent.width
                placeholderText: "Search city or country..."
            }

            DListView {
                id: cityCatalogList
                width: parent.width
                height: 290
                spacing: Style.groupedListGap
                clip: true

                readonly property var filteredCities: {
                    const q = (citySearchInput.text || "").trim().toLowerCase();
                    return ClockService.cityCatalog.filter(c => {
                        if (!q)
                            return true;
                        return c.city.toLowerCase().indexOf(q) >= 0 || c.country.toLowerCase().indexOf(q) >= 0;
                    });
                }

                model: filteredCities

                delegate: ClockRow {
                    id: cityItem
                    required property var modelData
                    required property int index

                    width: cityCatalogList.width
                    clickable: true
                    iconName: "public"
                    accent: "blue"
                    title: modelData.city
                    subtitle: modelData.country
                    isFirstInGroup: index === 0
                    isLastInGroup: index === cityCatalogList.filteredCities.length - 1
                    onClicked: {
                        ClockService.addWorldClock(modelData);
                        ClockService.citySheetOpen = false;
                        citySearchInput.text = "";
                        rootContent.forceActiveFocus();
                    }

                    NumericText {
                        text: ClockService.getCityTimeInfo(cityItem.modelData, ClockService.now).timeText
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Bold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }

        // Alarm Label Edit Bottom Sheet
        DBottomSheet {
            id: labelSheet
            opened: ClockService.labelDialogOpen
            title: "Alarm Label"
            onDismissRequested: {
                ClockService.labelDialogOpen = false;
                rootContent.forceActiveFocus();
            }

            onOpenedChanged: {
                if (opened && ClockService.editingLabelAlarmIndex >= 0 && ClockService.editingLabelAlarmIndex < ClockService.alarms.length) {
                    alarmLabelField.text = ClockService.alarms[ClockService.editingLabelAlarmIndex].label || "";
                    alarmLabelField.forceActiveFocus();
                }
            }

            DTextField {
                id: alarmLabelField
                width: parent.width
                placeholderText: "Enter alarm label..."
                Keys.onReturnPressed: saveLabelBtn.clicked()
                Keys.onEnterPressed: saveLabelBtn.clicked()
            }

            Item {
                width: parent.width
                height: 44

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    DButton {
                        text: "Cancel"
                        buttonHeight: Theme.buttonHeightXS
                        backgroundColor: Theme.secondaryContainer
                        textColor: Theme.onSecondaryContainer
                        onClicked: ClockService.labelDialogOpen = false
                    }

                    DButton {
                        id: saveLabelBtn
                        text: "Save"
                        buttonHeight: Theme.buttonHeightXS
                        onClicked: {
                            ClockService.updateAlarmLabel(ClockService.editingLabelAlarmIndex, alarmLabelField.text);
                            ClockService.labelDialogOpen = false;
                            rootContent.forceActiveFocus();
                        }
                    }
                }
            }
        }

        // Ringing Alert Modal using DDialog
        DDialog {
            anchors.fill: parent
            embedded: false
            opened: ClockService.ringingAlert !== null
            maximumWidth: 360
            title: ClockService.ringingAlert?.title ?? "Time's Up"
            supportingText: ClockService.ringingAlert?.subtitle ?? ""
            onRejected: ClockService.dismissRingingAlert()
            onAccepted: ClockService.dismissRingingAlert()

            actions: [
                DButton {
                    text: `Snooze (+${ClockService.ringingAlert?.snoozeMin ?? 5}m)`
                    backgroundColor: Theme.secondaryContainer
                    textColor: Theme.onSecondaryContainer
                    onClicked: ClockService.snoozeRingingAlert()
                },
                DButton {
                    text: "Dismiss"
                    onClicked: ClockService.dismissRingingAlert()
                }
            ]
        }
    }
}
