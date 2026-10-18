import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import "../../Engine/GameRegistry.js" as GameRegistry
import "."

Item {
    id: root

    signal gameSelected(string gameId)

    function getRoleColor(role) {
        switch (role) {
        case "primary": return Theme.primary;
        case "secondary": return Theme.secondary;
        case "tertiary": return Theme.tertiary;
        case "warning": return Theme.warning;
        case "success": return Theme.success;
        case "info": return Theme.info;
        default: return Theme.primary;
        }
    }

    DFlickable {
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: galleryColumn.implicitHeight + Style.spacingM + Style.spacingL

        Column {
            id: galleryColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Style.spacingL
            anchors.rightMargin: Style.spacingL
            anchors.topMargin: Style.spacingM
            anchors.bottomMargin: Style.spacingL
            spacing: Style.spacingM

            // Shelf Header Bar (Eliminates empty gap, displays quick stats)
            Rectangle {
                width: parent.width
                height: 38
                radius: Style.cornerRadiusL
                color: Theme.surfaceContainerLow
                border.width: 1
                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingM
                    anchors.rightMargin: Style.spacingM
                    spacing: Style.spacingS

                    // Shelf Title with Arcade Icon
                    Row {
                        spacing: Style.spacingXS
                        Layout.alignment: Qt.AlignVCenter

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "sports_esports"
                            size: 18
                            color: Theme.primary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.trFor("duzzle", "Game Shelf")
                            font.pixelSize: Style.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }

                    // Game Count Badge
                    Rectangle {
                        height: 20
                        radius: height / 2
                        implicitWidth: countText.implicitWidth + 12
                        color: Theme.surfaceContainerHighest
                        border.width: 1
                        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: GameRegistry.getAllGames().length + " " + I18n.trFor("duzzle", "Games")
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Total Played Stat Pill
                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "videogame_asset"
                            size: 15
                            color: Theme.surfaceVariantText
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: StatsService.totalPlayed + " " + I18n.trFor("duzzle", "played")
                            font.family: SettingsData.monoFontFamily || "monospace"
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: Theme.surfaceVariantText
                        }
                    }

                    // Divider dot
                    Rectangle {
                        width: 3
                        height: 3
                        radius: 1.5
                        color: Theme.outlineVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Wins Stat Pill
                    Row {
                        spacing: 4
                        Layout.alignment: Qt.AlignVCenter

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "military_tech"
                            size: 15
                            color: Theme.primary
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: StatsService.totalWon + " " + I18n.trFor("duzzle", "wins")
                            font.family: SettingsData.monoFontFamily || "monospace"
                            font.pixelSize: Style.fontSizeXXS
                            font.weight: Font.DemiBold
                            color: Theme.surfaceText
                        }
                    }
                }
            }

            // Games Grid (Balanced 3-card layout)
            Grid {
                id: gamesGrid
                width: parent.width
                columns: Math.max(1, Math.min(3, Math.floor((width + Style.spacingM) / 240)))
                spacing: Style.spacingM

                Repeater {
                    model: GameRegistry.getAllGames()

                    delegate: GameCard {
                        id: gameCard
                        required property var modelData

                        gameId: gameCard.modelData.id
                        title: gameCard.modelData.name
                        tagline: gameCard.modelData.tagline || ""
                        tag: gameCard.modelData.tag || ""
                        description: gameCard.modelData.description
                        iconName: gameCard.modelData.icon
                        badgeText: gameCard.modelData.badge || ""
                        accentColor: root.getRoleColor(gameCard.modelData.role)
                        enabledGame: gameCard.modelData.enabled !== false

                        onSelected: root.gameSelected(gameCard.gameId)
                    }
                }
            }
        }
    }
}
