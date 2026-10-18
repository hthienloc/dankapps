import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    property string gameId: ""
    property string title: ""
    property string description: ""
    property string tagline: ""
    property string tag: ""
    property string iconName: "extension"
    property string badgeText: ""
    property color accentColor: Theme.primary
    property bool enabledGame: true

    signal selected()

    width: parent ? Math.max(220, (parent.width - Style.spacingM * (parent.columns > 1 ? parent.columns - 1 : 0)) / (parent.columns || 1)) : 240
    implicitHeight: 310
    radius: Style.cornerRadiusXL
    color: Theme.surfaceContainerHigh
    clip: true
    z: (mouseArea.containsMouse && root.enabledGame) ? 10 : 1

    scale: (mouseArea.pressed && root.enabledGame)
        ? 0.985
        : ((mouseArea.containsMouse && root.enabledGame) ? 1.02 : 1.0)

    Behavior on scale {
        NumberAnimation { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Cover Art / Banner Area
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 165
            topLeftRadius: root.radius
            topRightRadius: root.radius
            bottomLeftRadius: 0
            bottomRightRadius: 0
            clip: true

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root.enabledGame
                        ? M3E.alpha(root.accentColor, 0.40)
                        : Theme.surfaceContainerHighest
                }
                GradientStop {
                    position: 1.0
                    color: Theme.surfaceContainerLowest
                }
            }

            // Background Decorative Watermark Icon
            DIcon {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: -16
                name: root.iconName
                size: 130
                color: Theme.surfaceText
                opacity: 0.07
                rotation: -10
            }

            // Top Status Badges Row
            RowLayout {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Style.spacingM

                // Genre Tag Chip
                Rectangle {
                    height: 22
                    radius: height / 2
                    implicitWidth: genreText.implicitWidth + 14
                    color: Theme.surfaceContainerHighest
                    border.width: 1
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                    Text {
                        id: genreText
                        anchors.centerIn: parent
                        text: root.tag || "Puzzle"
                        font.pixelSize: Style.fontSizeXXS
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                    }
                }

                Item { Layout.fillWidth: true }

                // Badge Chip
                Rectangle {
                    height: 22
                    radius: height / 2
                    implicitWidth: badgeLabel.implicitWidth + 14
                    color: root.enabledGame ? root.accentColor : Theme.surfaceContainerHighest
                    border.width: root.enabledGame ? 0 : 1
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                    Text {
                        id: badgeLabel
                        anchors.centerIn: parent
                        text: root.badgeText
                        font.pixelSize: Style.fontSizeXXS
                        font.weight: Font.Bold
                        color: root.enabledGame ? Theme.primaryText : Theme.surfaceVariantText
                    }
                }
            }

            // Center Hero Game Icon Plate
            Rectangle {
                anchors.centerIn: parent
                width: 64
                height: 64
                radius: 20
                color: Theme.surfaceContainerHighest
                border.width: 1
                border.color: (mouseArea.containsMouse && root.enabledGame)
                    ? root.accentColor
                    : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                scale: mouseArea.containsMouse && root.enabledGame ? 1.08 : 1.0

                Behavior on scale {
                    NumberAnimation { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
                }
                Behavior on border.color {
                    ColorAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
                }

                DIcon {
                    anchors.centerIn: parent
                    name: root.iconName
                    size: 34
                    color: root.accentColor
                }
            }
        }

        // Details Panel
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.surfaceContainerHigh
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: root.radius
            bottomRightRadius: root.radius

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Style.spacingM
                spacing: Style.spacingXXS

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Style.fontSizeLarge
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.tagline || root.description
                    font.pixelSize: Style.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Item { Layout.fillHeight: true }

                // Card Footer: Best Stat + Play Arrow Button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.spacingS

                    // Stat / Feature pill (Score vs Time aware)
                    Row {
                        spacing: Style.spacingXS
                        visible: root.enabledGame

                        readonly property int bestSc: StatsService.getBestScore(root.gameId)
                        readonly property int bestTm: StatsService.getBestTime(root.gameId)
                        readonly property bool hasScore: root.gameId === "2048" || root.gameId === "snake"

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: (hasScore && bestSc > 0) ? "emoji_events" : (bestTm > 0 && bestTm < 999999 ? "timer" : "sports_esports")
                            size: 14
                            color: ((hasScore && bestSc > 0) || (bestTm > 0 && bestTm < 999999))
                                ? Theme.primary
                                : Theme.surfaceVariantText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (hasScore && bestSc > 0) return "Best: " + bestSc;
                                if (bestTm > 0 && bestTm < 999999) return "Best: " + StatsService.formatTime(bestTm);
                                return root.gameId === "snake" ? "3 Speeds" : (root.gameId === "2048" ? "3 Sizes" : "3 Difficulties");
                            }
                            font.family: SettingsData.monoFontFamily || "monospace"
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: ((hasScore && bestSc > 0) || (bestTm > 0 && bestTm < 999999))
                                ? Theme.surfaceText
                                : Theme.surfaceVariantText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Action Button / Pill
                    Rectangle {
                        height: 28
                        radius: height / 2
                        implicitWidth: actionRow.implicitWidth + 16
                        color: root.enabledGame
                            ? (mouseArea.containsMouse ? root.accentColor : Theme.surfaceContainerHighest)
                            : "transparent"
                        border.width: root.enabledGame ? 0 : 1
                        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                        Behavior on color {
                            ColorAnimation { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects }
                        }

                        Row {
                            id: actionRow
                            anchors.centerIn: parent
                            spacing: Style.spacingXXS

                            DIcon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: root.enabledGame ? "play_arrow" : "lock"
                                size: 14
                                color: root.enabledGame
                                    ? (mouseArea.containsMouse ? Theme.primaryText : Theme.surfaceText)
                                    : Theme.surfaceVariantText
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.enabledGame ? I18n.trFor("duzzle", "Play") : I18n.trFor("duzzle", "Soon")
                                font.pixelSize: Style.fontSizeXXS
                                font.weight: Font.Bold
                                color: root.enabledGame
                                    ? (mouseArea.containsMouse ? Theme.primaryText : Theme.surfaceText)
                                    : Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }
        }
    }

    // Highlight Border Overlay
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: (mouseArea.containsMouse && root.enabledGame) ? 2 : 1
        border.color: (mouseArea.containsMouse && root.enabledGame)
            ? root.accentColor
            : M3E.stroke(Theme.outlineVariant, M3E.strokeCard)

        Behavior on border.color {
            ColorAnimation { duration: M3E.effectsMs; easing.bezierCurve: M3E.curveEffects }
        }
        Behavior on border.width {
            NumberAnimation { duration: M3E.effectsFastMs }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabledGame
        hoverEnabled: true
        cursorShape: root.enabledGame ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.selected()
    }
}
