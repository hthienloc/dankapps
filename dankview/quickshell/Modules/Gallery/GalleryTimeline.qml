import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property var rawGroups: (ImageService.galleryData && ImageService.galleryData.groups) ? ImageService.galleryData.groups : []
    readonly property string query: ImageService.searchQueryDebounced

    function matchesQuery(img) {
        if (!query) return true
        const ln = img._lowerName || (img.name || "").toLowerCase()
        const lp = img._lowerPath || (img.path || "").toLowerCase()
        return ln.indexOf(query) !== -1 || lp.indexOf(query) !== -1
    }

    readonly property var filteredGroups: {
        let base = rawGroups
        const cat = ImageService.selectedCategory
        const q = query
        if (cat && cat !== "All") {
            if (cat === "Favorites") {
                const result = []
                for (let i = 0; i < base.length; i++) {
                    const grp = base[i]
                    const imgs = grp.images.filter(img => ImageService.isFavorite(img.path) && matchesQuery(img))
                    if (imgs.length > 0) result.push({ dateGroup: grp.dateGroup, images: imgs })
                }
                return result
            }
            const result = []
            for (let i = 0; i < base.length; i++) {
                const grp = base[i]
                const imgs = grp.images.filter(img => img.category === cat && matchesQuery(img))
                if (imgs.length > 0) result.push({ dateGroup: grp.dateGroup, images: imgs })
            }
            return result
        }
        if (!q) return base
        const result = []
        for (let i = 0; i < base.length; i++) {
            const grp = base[i]
            const imgs = grp.images.filter(matchesQuery)
            if (imgs.length > 0) result.push({ dateGroup: grp.dateGroup, images: imgs })
        }
        return result
    }

    readonly property int columns: Math.max(3, Math.min(6, Math.floor((width - 40) / 168)))
    readonly property real tileWidth: Math.floor((width - 40 - (columns - 1) * 10) / columns)

    property real lastContentY: -8
    property bool restoringScroll: false

    onFilteredGroupsChanged: {
        if (root.lastContentY > 0) {
            root.restoringScroll = true
            const targetY = root.lastContentY
            Qt.callLater(() => {
                if (list.contentHeight > 0) {
                    list.contentY = Math.min(targetY, Math.max(-list.topMargin, list.contentHeight - list.height))
                }
                root.restoringScroll = false
            })
        }
    }

    Connections {
        target: ImageService
        function onSelectedCategoryChanged() {
            root.lastContentY = -list.topMargin
            list.contentY = -list.topMargin
        }
        function onSearchQueryDebouncedChanged() {
            root.lastContentY = -list.topMargin
            list.contentY = -list.topMargin
        }
    }

    // Virtualized list of date groups — Grid is ~3× faster than Flow for fixed columns
    ListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        clip: true
        model: root.filteredGroups
        spacing: 24
        cacheBuffer: 400
        topMargin: 8
        bottomMargin: 80
        reuseItems: true
        boundsBehavior: Flickable.StopAtBounds
        maximumFlickVelocity: 2500

        onContentYChanged: {
            if (!root.restoringScroll && contentY > 0) {
                root.lastContentY = contentY
            }
        }

        delegate: ColumnLayout {
            width: ListView.view.width - 16
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            StyledText {
                text: modelData.dateGroup
                font.pixelSize: Theme.fontSizeMedium + 1
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceText
            }

            Grid {
                Layout.fillWidth: true
                columns: root.columns
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: modelData.images
                    delegate: GalleryThumbnail {
                        flickable: null
                        imageItem: modelData
                        tileSize: root.tileWidth
                    }
                }
            }
        }

        // Empty / loading overlays
        Item {
            anchors.fill: parent
            visible: !ImageService.isGalleryLoading && root.filteredGroups.length === 0
            z: 2

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 12
                DIcon {
                    Layout.alignment: Qt.AlignHCenter
                    name: root.query !== "" ? "search_off" : (ImageService.selectedCategory === "Favorites" ? "favorite_border" : "image_not_supported")
                    size: 40
                    color: root.query !== "" ? Theme.surfaceVariantText : (ImageService.selectedCategory === "Favorites" ? Theme.error : Theme.surfaceVariantText)
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.query !== "" ? ('No results for "' + ImageService.searchQuery + '"') : (ImageService.selectedCategory === "Favorites" ? "No favorite images yet" : "No images found")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.query !== "" ? "Try a different search term" : (ImageService.selectedCategory === "Favorites" ? "Click the heart icon on any photo to add it to favorites" : "Add images to your Pictures folder or choose another category")
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                }
            }
        }
    }

    // Loading indicator centered over list — original
    Item {
        anchors.fill: parent
        visible: ImageService.isGalleryLoading && root.filteredGroups.length === 0
        z: 3
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            DIcon { Layout.alignment: Qt.AlignHCenter; name: "sync"; size: 32; color: Theme.primary }
            StyledText { Layout.alignment: Qt.AlignHCenter; text: "Scanning pictures..."; font.pixelSize: Theme.fontSizeMedium; color: Theme.surfaceVariantText }
        }
    }
}
