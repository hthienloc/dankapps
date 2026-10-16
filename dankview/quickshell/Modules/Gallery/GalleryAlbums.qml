import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Item {
    id: root

    readonly property var allAlbums: (ImageService.galleryData && ImageService.galleryData.albums) ? ImageService.galleryData.albums : []
    readonly property string query: ImageService.searchQueryDebounced
    readonly property var filteredAlbums: {
        if (!query) return allAlbums
        return allAlbums.filter(a => (a._lowerName || (a.name || "").toLowerCase()).indexOf(query) !== -1)
    }
    readonly property var customAlbums: filteredAlbums.filter(a => !a.isPinned)

    // Recompute pinned correctly: include favorites album only if it matches query or query empty
    readonly property var effectivePinned: {
        const fav = ImageService.favoritesAlbum
        const favLower = fav._lowerName || (fav.name || "").toLowerCase()
        const favMatch = !query || favLower.indexOf(query) !== -1
        const list = favMatch ? [fav] : []
        for (let i = 0; i < filteredAlbums.length; i++) {
            const a = filteredAlbums[i]
            if (a.isPinned) list.push(a)
        }
        return list
    }

    DFlickable {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        contentHeight: albumsCol.implicitHeight + 80
        clip: true

        ColumnLayout {
            id: albumsCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            anchors.top: parent.top
            spacing: 28

            // Search feedback
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                visible: root.query !== "" && root.filteredAlbums.length === 0 && root.effectivePinned.length === 0

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    DIcon { name: "search_off"; size: 18; color: Theme.surfaceVariantText }
                    StyledText {
                        text: 'No results for "' + ImageService.searchQuery + '"'
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }

            // Pinned Categories
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: root.effectivePinned.length > 0

                StyledText {
                    text: "Pinned Categories"
                    font.pixelSize: Theme.fontSizeMedium + 1
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 16

                    Repeater {
                        model: root.effectivePinned

                        delegate: AlbumCard {
                            album: modelData
                            cardWidth: 176
                            previewHeight: 176
                        }
                    }
                }
            }

            // Custom Categories
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14
                visible: root.customAlbums.length > 0

                StyledText {
                    text: "Custom Categories"
                    font.pixelSize: Theme.fontSizeMedium + 1
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 16

                    Repeater {
                        model: root.customAlbums

                        delegate: AlbumCard {
                            album: modelData
                            cardWidth: 176
                            previewHeight: 176
                        }
                    }
                }
            }

            // Empty state if no albums at all
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 160
                visible: root.allAlbums.length === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    DIcon {
                        Layout.alignment: Qt.AlignHCenter
                        name: "folder_open"
                        size: 40
                        color: Theme.surfaceVariantText
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No albums found"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }
                }
            }
        }
    }
}
