pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "."

Item {
    id: root

    anchors.fill: parent

    Column {
        anchors.fill: parent
        spacing: 0

        Item {
            id: tabBarContainer
            width: parent.width
            height: settingsTabs.height + Theme.spacingL + Theme.spacingS

            DButtonGroup {
                id: settingsTabs
                width: Math.min(360, parent.width - Theme.spacingL * 2)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spacingS
                fillWidth: true
                checkEnabled: true
                selectionMode: "single"
                size: "small"
                model: [
                    { icon: "tune", text: "Preferences" },
                    { icon: "info", text: "About" }
                ]
                currentIndex: ClockService.settingsTabIndex
                onSelectionChanged: (idx, sel) => {
                    if (sel)
                        ClockService.settingsTabIndex = idx;
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - tabBarContainer.height
            clip: true

            // Tab 0: Preferences (Clock, Pomodoro & Appearance)
            DFlickable {
                anchors.fill: parent
                visible: ClockService.settingsTabIndex === 0
                clip: true
                contentWidth: width
                contentHeight: settingsCol.height + ClockMetrics.pagePaddingV

                Column {
                    id: settingsCol
                    topPadding: Theme.spacingXS
                    width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: ClockMetrics.cardGap

                            // Clock & Display Section
                            Column {
                                width: parent.width
                                spacing: 0

                                ClockSectionLabel {
                                    width: parent.width
                                    text: "Clock & Display"
                                }

                                ClockGroup {
                                    width: parent.width

                                    ClockRow {
                                        width: parent.width
                                        iconName: "schedule"
                                        accent: "blue"
                                        title: "Time format"
                                        subtitle: "Use 24-hour or 12-hour AM/PM clock display"
                                        isFirstInGroup: true
                                        isLastInGroup: false

                                        DButtonGroup {
                                            selectionMode: "single"
                                            size: "small"
                                            checkEnabled: false
                                            model: ["24-hour", "12-hour"]
                                            currentIndex: SettingsData.use24HourClock ? 0 : 1
                                            anchors.verticalCenter: parent.verticalCenter
                                            onSelectionChanged: (idx, sel) => {
                                                if (sel)
                                                    SettingsData.use24HourClock = (idx === 0);
                                            }
                                        }
                                    }

                                    ClockRow {
                                        width: parent.width
                                        iconName: "timer"
                                        accent: "teal"
                                        title: "Show seconds"
                                        subtitle: "Display live seconds on the local digital and analog clock"
                                        clickable: true
                                        isFirstInGroup: false
                                        isLastInGroup: true
                                        onClicked: SettingsData.showSeconds = !SettingsData.showSeconds

                                        DToggle {
                                            hideText: true
                                            checked: SettingsData.showSeconds
                                            anchors.verticalCenter: parent.verticalCenter
                                            onToggled: chk => SettingsData.showSeconds = chk
                                        }
                                    }
                                }
                            }

                            // Pomodoro Defaults Section
                            Column {
                                width: parent.width
                                spacing: 0

                                ClockSectionLabel {
                                    width: parent.width
                                    text: "Pomodoro Defaults"
                                }

                                ClockGroup {
                                    width: parent.width

                                    Repeater {
                                        model: [
                                            {
                                                icon: "psychology",
                                                accent: "purple",
                                                title: "Focus duration",
                                                subtitle: `${SettingsData.pomodoroFocusMinutes} minutes per focus session`,
                                                min: 5,
                                                max: 90,
                                                step: 5,
                                                prop: "pomodoroFocusMinutes"
                                            },
                                            {
                                                icon: "coffee",
                                                accent: "green",
                                                title: "Short break",
                                                subtitle: `${SettingsData.pomodoroShortBreakMinutes} minutes rest between sessions`,
                                                min: 1,
                                                max: 30,
                                                step: 1,
                                                prop: "pomodoroShortBreakMinutes"
                                            },
                                            {
                                                icon: "self_improvement",
                                                accent: "orange",
                                                title: "Long break",
                                                subtitle: `${SettingsData.pomodoroLongBreakMinutes} minutes after ${SettingsData.pomodoroTargetCycles} cycles`,
                                                min: 5,
                                                max: 60,
                                                step: 5,
                                                prop: "pomodoroLongBreakMinutes"
                                            }
                                        ]

                                        ClockRow {
                                            id: pomoSettingRow
                                            required property var modelData
                                            required property int index

                                            width: parent.width
                                            iconName: modelData.icon
                                            accent: modelData.accent
                                            title: modelData.title
                                            subtitle: modelData.subtitle
                                            isFirstInGroup: index === 0
                                            isLastInGroup: index === 2
                                            body: [
                                                DSlider {
                                                    width: parent.width
                                                    size: "s"
                                                    minimum: pomoSettingRow.modelData.min
                                                    maximum: pomoSettingRow.modelData.max
                                                    step: pomoSettingRow.modelData.step
                                                    unit: "m"
                                                    value: SettingsData[pomoSettingRow.modelData.prop]
                                                    onSliderValueChanged: v => SettingsData[pomoSettingRow.modelData.prop] = v
                                                }
                                            ]
                                        }
                                    }
                                }
                            }

                            // Appearance & Motion Section
                            Column {
                                width: parent.width
                                spacing: 0

                                ClockSectionLabel {
                                    width: parent.width
                                    text: "Appearance & Motion"
                                }

                                ClockGroup {
                                    width: parent.width

                                    ClockRow {
                                        width: parent.width
                                        iconName: "palette"
                                        accent: "purple"
                                        title: "Theme mode"
                                        subtitle: "Follow Dux Shell colors or force light/dark mode"
                                        isFirstInGroup: true
                                        isLastInGroup: false

                                        DButtonGroup {
                                            selectionMode: "single"
                                            size: "small"
                                            checkEnabled: false
                                            model: ["Auto", "Light", "Dark"]
                                            currentIndex: {
                                                switch (SettingsData.themeMode) {
                                                case "light": return 1;
                                                case "dark": return 2;
                                                default: return 0;
                                                }
                                            }
                                            anchors.verticalCenter: parent.verticalCenter
                                            onSelectionChanged: (idx, sel) => {
                                                if (!sel)
                                                    return;
                                                const modes = ["auto", "light", "dark"];
                                                SettingsData.themeMode = modes[idx];
                                            }
                                        }
                                    }

                                    ClockRow {
                                        width: parent.width
                                        iconName: "rounded_corner"
                                        accent: "blue"
                                        title: "Corner roundness"
                                        subtitle: `Expressive shape scale (${SettingsData.radiusStrength}%)`
                                        isFirstInGroup: false
                                        isLastInGroup: false
                                        body: [
                                            DSlider {
                                                width: parent.width
                                                size: "s"
                                                minimum: 0
                                                maximum: 100
                                                step: 5
                                                unit: "%"
                                                value: SettingsData.radiusStrength
                                                onSliderValueChanged: v => SettingsData.radiusStrength = v
                                            }
                                        ]
                                    }

                                    ClockRow {
                                        width: parent.width
                                        iconName: "touch_app"
                                        accent: "teal"
                                        title: "Interactive ripples"
                                        subtitle: "Show Material touch ripple effects when clicking controls"
                                        clickable: true
                                        isFirstInGroup: false
                                        isLastInGroup: false
                                        onClicked: SettingsData.enableRippleEffects = !SettingsData.enableRippleEffects

                                        DToggle {
                                            hideText: true
                                            checked: SettingsData.enableRippleEffects
                                            anchors.verticalCenter: parent.verticalCenter
                                            onToggled: chk => SettingsData.enableRippleEffects = chk
                                        }
                                    }

                                    ClockRow {
                                        width: parent.width
                                        iconName: "motion_photos_off"
                                        accent: "orange"
                                        title: "Reduce motion"
                                        subtitle: "Minimize smooth animations and spatial transitions"
                                        clickable: true
                                        isFirstInGroup: false
                                        isLastInGroup: true
                                        onClicked: SettingsData.reduceMotion = !SettingsData.reduceMotion

                                        DToggle {
                                            hideText: true
                                            checked: SettingsData.reduceMotion
                                            anchors.verticalCenter: parent.verticalCenter
                                            onToggled: chk => SettingsData.reduceMotion = chk
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Tab 1: About (Official DMS App style)
                    DFlickable {
                        anchors.fill: parent
                        visible: ClockService.settingsTabIndex === 1
                        clip: true
                        contentWidth: width
                        contentHeight: aboutCol.height + ClockMetrics.pagePaddingV

                        Column {
                            id: aboutCol
                            topPadding: Theme.spacingM
                            width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.spacingL

                            DHeroCard {
                                brand: "DankClock"
                                caption: "dclock 0.1.0"

                                DButton {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Support Dux Labs"
                                    iconName: "favorite"
                                    backgroundColor: Theme.primary
                                    textColor: Theme.onPrimary
                                    onClicked: Qt.openUrlExternally("https://ko-fi.com/duxlabs")
                                }
                            }

                            DCard {
                                width: parent.width
                                height: aboutText.implicitHeight + pad * 2
                                pad: Theme.spacingL
                                restRadius: Theme.groupedListOuterRadius
                                color: ClockMetrics.rowColor

                                StyledText {
                                    id: aboutText
                                    width: parent.width
                                    text: 'DankClock is a world clock, alarm, countdown timer, Pomodoro focus assistant, and stopwatch utility for the modern Linux desktop with a <a href="https://m3.material.io/" style="text-decoration:none; color:%1;">Material 3 Expressive</a> design, part of the Dux Shell ecosystem.<br /><br />Built with <a href="https://quickshell.org" style="text-decoration:none; color:%1;">Quickshell</a> and <a href="https://go.dev" style="text-decoration:none; color:%1;">Go</a>.'.arg(Theme.primary)
                                    textFormat: Text.RichText
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    linkColor: Theme.primary
                                    wrapMode: Text.WordWrap
                                    onLinkActivated: url => Qt.openUrlExternally(url)
                                }
                            }

                            ClockGroup {
                                width: parent.width

                                Repeater {
                                    model: [
                                        { icon: "menu_book", accent: "blue", title: "Docs", subtitle: "duxlabs.dev/docs", url: "https://duxlabs.dev/docs" },
                                        { icon: "code", accent: "purple", title: "GitHub", subtitle: "github.com/hthienloc/dankapps", url: "https://github.com/hthienloc/dankapps" },
                                        { icon: "gavel", accent: "green", title: "License", subtitle: "MIT License", url: "https://github.com/hthienloc/dankapps/blob/master/LICENSE" }
                                    ]

                                    ClockRow {
                                        id: aboutLinkRow
                                        required property var modelData
                                        required property int index

                                        width: parent.width
                                        iconName: modelData.icon
                                        accent: modelData.accent
                                        title: modelData.title
                                        subtitle: modelData.subtitle
                                        clickable: true
                                        isFirstInGroup: index === 0
                                        isLastInGroup: index === 2
                                        onClicked: Qt.openUrlExternally(aboutLinkRow.modelData.url)

                                        DIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "open_in_new"
                                            size: Theme.iconSizeSmall
                                            color: Theme.surfaceVariantText
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
}
