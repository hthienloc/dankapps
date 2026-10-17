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

    function matchesFilters(img) {
        if (ImageService.filterMediaType === "Images only") {
            if (/\.(mp4|mkv|webm|avi|mov|m4v)$/i.test(img.path) || /\.gif$/i.test(img.path)) return false
        } else if (ImageService.filterMediaType === "Videos only") {
            if (!/\.(mp4|mkv|webm|avi|mov|m4v)$/i.test(img.path)) return false
        } else if (ImageService.filterMediaType === "GIFs / Animations") {
            if (!/\.gif$/i.test(img.path)) return false
        }

        if (ImageService.filterLocation !== "Anywhere") {
            if (ImageService.filterLocation === "Favorites") {
                if (!ImageService.isFavorite(img.path)) return false
            } else if (img.category !== ImageService.filterLocation) {
                return false
            }
        }

        if (ImageService.filterFavoritesOnly && !ImageService.isFavorite(img.path)) {
            return false
        }

        if (!ImageService.filterIncludeHidden && (img.name || "").startsWith(".")) {
            return false
        }

        if (ImageService.filterDateAdded !== "Any time" && img.modTime > 0) {
            const nowSec = Date.now() / 1000
            const diffSec = nowSec - img.modTime
            if (ImageService.filterDateAdded === "Today" && diffSec > 86400) return false
            if (ImageService.filterDateAdded === "Last 7 days" && diffSec > 7 * 86400) return false
            if (ImageService.filterDateAdded === "Last 30 days" && diffSec > 30 * 86400) return false
            if (ImageService.filterDateAdded === "This year" && diffSec > 365 * 86400) return false
        }

        return true
    }

    readonly property var filteredGroups: {
        let base = rawGroups
        const cat = ImageService.selectedCategory
        const result = []

        for (let i = 0; i < base.length; i++) {
            const grp = base[i]
            const imgs = grp.images.filter(img => {
                if (ImageService.isAlbumRemoved(img.category, "")) return false
                if (cat && cat !== "All") {
                    if (cat === "Favorites") {
                        if (!ImageService.isFavorite(img.path)) return false
                    } else if (img.category !== cat) {
                        return false
                    }
                }
                return matchesQuery(img) && matchesFilters(img)
            })
            if (imgs.length > 0) result.push({ dateGroup: grp.dateGroup, images: imgs })
        }

        const sortOrder = ImageService.filterSortOrder
        if (sortOrder === "Oldest first") {
            const rev = []
            for (let i = result.length - 1; i >= 0; i--) {
                const g = result[i]
                rev.push({ dateGroup: g.dateGroup, images: g.images.slice().reverse() })
            }
            return rev
        } else if (sortOrder === "Name (A-Z)") {
            const sorted = []
            for (let i = 0; i < result.length; i++) {
                const g = result[i]
                sorted.push({ dateGroup: g.dateGroup, images: g.images.slice().sort((a, b) => (a.name || "").localeCompare(b.name || "")) })
            }
            return sorted
        } else if (sortOrder === "Name (Z-A)") {
            const sorted = []
            for (let i = 0; i < result.length; i++) {
                const g = result[i]
                sorted.push({ dateGroup: g.dateGroup, images: g.images.slice().sort((a, b) => (b.name || "").localeCompare(a.name || "")) })
            }
            return sorted
        }

        return result
    }

    readonly property int columns: Math.max(3, Math.min(6, Math.floor((width - 40) / 168)))
    readonly property real tileWidth: Math.floor((width - 40 - (columns - 1) * 10) / columns)

    property real lastContentY: -72
    property string lastCategory: ImageService.selectedCategory

    function resetScroll() {
        const topY = list.originY < 0 ? list.originY : -72
        root.lastContentY = topY
        list.savedY = topY
        list.prevContentY = topY
        list.accumulatedDown = 0
        list.contentY = topY
        list.stopMomentum()
    }

    onVisibleChanged: {
        if (visible) {
            root.resetScroll()
        }
    }

    Connections {
        target: ImageService
        function onSelectedCategoryChanged() {
            root.resetScroll()
        }
        function onGalleryTabChanged() {
            if (ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline") {
                root.resetScroll()
            }
        }
        function onSearchQueryDebouncedChanged() {
            root.resetScroll()
        }
        function onSearchBarCollapsedChanged() {
            if (!ImageService.searchBarCollapsed) {
                list.prevContentY = list.contentY
                list.accumulatedDown = 0
            }
        }
    }

    // Virtualized list of date groups — DListView provides DMS momentum and accelerated wheel/touchpad scrolling
    DListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        clip: true
        model: root.filteredGroups
        spacing: 24
        cacheBuffer: 400
        topMargin: 0
        reuseItems: true
        fadeEdges: false
        showScrollBar: true

        header: Item {
            width: 1
            height: 72
        }

        footer: Item {
            width: 1
            height: 80
        }

        onModelChanged: {
            if (root.lastCategory !== ImageService.selectedCategory) {
                root.lastCategory = ImageService.selectedCategory
                root.resetScroll()
            }
        }

        property real prevContentY: -72
        property real accumulatedDown: 0

        onContentYChanged: {
            const topY = list.originY < 0 ? list.originY : -72
            if (contentY > topY) {
                root.lastContentY = contentY
            }
            if (contentY <= topY + 12) {
                accumulatedDown = 0
                ImageService.searchBarCollapsed = false
            } else {
                const delta = contentY - prevContentY
                if (delta > 0) {
                    accumulatedDown += delta
                    if (accumulatedDown > 12 && contentY > topY + 20) {
                        if (!ImageService.searchQuery) {
                            ImageService.searchBarCollapsed = true
                        }
                    }
                } else if (delta < -2) {
                    accumulatedDown = 0
                }
            }
            prevContentY = contentY
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
