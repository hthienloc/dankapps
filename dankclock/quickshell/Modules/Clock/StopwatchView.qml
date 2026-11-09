pragma ComponentBehavior: Bound

import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

DFlickable {
    id: root

    anchors.fill: parent
    clip: true
    contentWidth: width
    contentHeight: pageColumn.height + ClockMetrics.pagePaddingV

    readonly property real minuteProgress: (ClockService.stopwatchElapsedMs % 60000) / 60000
    readonly property string fullFormatted: ClockService.formatStopwatch(ClockService.stopwatchElapsedMs)
    readonly property int dotIdx: fullFormatted.indexOf(".")
    readonly property string mainDigits: dotIdx >= 0 ? fullFormatted.substring(0, dotIdx) : fullFormatted
    readonly property string centiDigits: dotIdx >= 0 ? fullFormatted.substring(dotIdx) : ".00"

    Column {
        id: pageColumn
        topPadding: Theme.spacingL
        width: Math.min(ClockMetrics.contentMaxWidth, parent.width - Theme.spacingL * 2)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: ClockMetrics.cardGap

        // Hero Stopwatch Card
        Rectangle {
            id: heroStopwatchCard
            width: parent.width
            height: swHeroCol.implicitHeight + Theme.spacingXL * 2
            radius: Theme.cornerRadiusXL
            color: swHeroHover.hovered ? Theme.surfaceContainerHighest : ClockMetrics.rowColor
            border.width: Theme.layerOutlineWidth
            border.color: ClockService.stopwatchRunning
                ? Theme.primary
                : (swHeroHover.hovered ? Theme.outline : Theme.outlineMedium)

            Behavior on color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }
            Behavior on border.color {
                enabled: Theme.animationsEnabled
                ColorAnimation { duration: ClockMetrics.fadeDuration }
            }

            HoverHandler {
                id: swHeroHover
            }

            Column {
                id: swHeroCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingXL
                spacing: Theme.spacingL

                // 240x240 Ring Gauge with Organic Blob
                ClockRingDial {
                    anchors.horizontalCenter: parent.horizontalCenter
                    dialSize: 240
                    blobSize: 204
                    progress: root.minuteProgress
                    ringColor: Theme.primary
                    active: ClockService.stopwatchRunning
                    animated: false
                    clickable: true
                    tooltipText: ClockService.stopwatchRunning ? "Click to stop" : (ClockService.stopwatchElapsedMs > 0 ? "Click to resume" : "Click to start")
                    onClicked: ClockService.toggleStopwatch()

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter

                        NumericText {
                            text: root.mainDigits
                            font.pixelSize: root.mainDigits.length > 5 ? Theme.fontSizeXXLarge : Theme.fontSizeDisplay
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.baseline: parent.bottom
                        }

                        NumericText {
                            text: root.centiDigits
                            font.pixelSize: root.mainDigits.length > 5 ? Theme.fontSizeXLarge : Theme.fontSizeXXLarge
                            font.weight: Font.Bold
                            color: Theme.primary
                            anchors.baseline: parent.bottom
                        }
                    }

                    NumericText {
                        visible: ClockService.stopwatchLaps.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Lap " + (ClockService.stopwatchLaps.length + 1) + "  •  " + ClockService.formatStopwatch(ClockService.currentLapElapsedMs)
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceVariantText
                    }
                }

                // Controls Row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingM

                    DButton {
                        text: ClockService.stopwatchRunning ? "Lap" : "Reset"
                        iconName: ClockService.stopwatchRunning ? "flag" : "restart_alt"
                        buttonHeight: Theme.buttonHeightM
                        backgroundColor: ClockService.stopwatchRunning ? Theme.secondaryContainer : Theme.errorContainer
                        textColor: ClockService.stopwatchRunning ? Theme.onSecondaryContainer : Theme.onErrorContainer
                        enabled: ClockService.stopwatchRunning || ClockService.stopwatchElapsedMs > 0
                        onClicked: {
                            if (ClockService.stopwatchRunning)
                                ClockService.lapStopwatch();
                            else
                                ClockService.resetStopwatch();
                        }
                    }
                }
            }
        }

        // Laps Section
        Column {
            width: parent.width
            spacing: 0

            ClockSectionLabel {
                width: parent.width
                text: ClockService.stopwatchLaps.length > 0 ? `Lap Splits (${ClockService.stopwatchLaps.length})` : "Lap Splits"
            }

            ClockEmptyState {
                visible: ClockService.stopwatchLaps.length === 0
                cardHeight: 150
                iconName: "flag"
                iconSize: Theme.iconSizeLarge
                title: "No Laps Recorded"
                titlePixelSize: Theme.fontSizeMedium
                subtitle: "Press Lap while the stopwatch is running to record split times."
            }

            ClockGroup {
                visible: ClockService.stopwatchLaps.length > 0
                width: parent.width

                Repeater {
                    model: ClockService.stopwatchLaps

                    ClockRow {
                        id: lapRow
                        required property var modelData
                        required property int index

                        readonly property bool isFastest: modelData.lapNumber === ClockService.fastestLapNumber
                        readonly property bool isSlowest: modelData.lapNumber === ClockService.slowestLapNumber

                        width: parent.width
                        iconName: isFastest ? "emoji_events" : (isSlowest ? "trending_down" : "flag")
                        accent: isFastest ? "green" : (isSlowest ? "red" : "purple")
                        title: `Lap #${String(modelData.lapNumber).padStart(2, "0")}`
                        subtitle: isFastest ? "Fastest Split" : (isSlowest ? "Slowest Split" : "")
                        subtitleColor: isFastest ? Theme.success : (isSlowest ? Theme.error : Theme.surfaceVariantText)
                        isFirstInGroup: index === 0
                        isLastInGroup: index === ClockService.stopwatchLaps.length - 1

                        Row {
                            spacing: 28
                            anchors.verticalCenter: parent.verticalCenter

                            Column {
                                spacing: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: "LAP TIME"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceVariantText
                                    anchors.right: parent.right
                                }

                                NumericText {
                                    text: "+" + ClockService.formatStopwatch(lapRow.modelData.lapMs)
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: lapRow.isFastest ? Theme.success : (lapRow.isSlowest ? Theme.error : Theme.surfaceText)
                                    anchors.right: parent.right
                                }
                            }

                            Column {
                                spacing: Theme.spacingXS
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    text: "TOTAL"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceVariantText
                                    anchors.right: parent.right
                                }

                                NumericText {
                                    text: ClockService.formatStopwatch(lapRow.modelData.totalMs)
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                    anchors.right: parent.right
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
