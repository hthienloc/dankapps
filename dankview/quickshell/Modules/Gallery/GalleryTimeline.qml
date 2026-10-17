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

    readonly property bool showRecents: {
        return Boolean(ImageService.recentImages && ImageService.recentImages.length > 0) &&
               !root.query &&
               (ImageService.selectedCategory === "All" || !ImageService.selectedCategory) &&
               !ImageService.hasActiveFilters
    }

    onVisibleChanged: {
        if (visible) {
            const topY = list.originY < 0 ? list.originY : -72
            if (root.lastContentY > topY) {
                Qt.callLater(() => {
                    if (root.visible && root.lastContentY > (list.originY < 0 ? list.originY : -72)) {
                        list.contentY = root.lastContentY
                        list.savedY = root.lastContentY
                        list.prevContentY = root.lastContentY
                    }
                })
            }
        }
    }

    Connections {
        target: ImageService
        function onSelectedCategoryChanged() {
            root.resetScroll()
        }
        function onGalleryTabChanged() {
            if (ImageService.galleryTab === "gallery" || ImageService.galleryTab === "timeline") {
                const topY = list.originY < 0 ? list.originY : -72
                if (root.lastContentY > topY) {
                    list.contentY = root.lastContentY
                    list.savedY = root.lastContentY
                    list.prevContentY = root.lastContentY
                }
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

        header: ColumnLayout {
            width: list.width
            spacing: 0

            Item {
                Layout.fillWidth: true
                implicitHeight: 72
            }

            ColumnLayout {
                id: recentsContainer
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                visible: root.showRecents
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        text: "Recent"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: prevMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                        opacity: recentCarousel.contentX > recentCarousel.originX + 1 ? 1.0 : 0.35

                        DIcon {
                            anchors.centerIn: parent
                            name: "chevron-left"
                            size: 16
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: recentCarousel.contentX > recentCarousel.originX + 1
                            onClicked: recentCarousel.scrollStep(-1)
                        }
                    }

                    Rectangle {
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: nextMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                        opacity: recentCarousel.contentX < (recentCarousel.originX + recentCarousel.contentWidth - recentCarousel.width - 1) ? 1.0 : 0.35

                        DIcon {
                            anchors.centerIn: parent
                            name: "chevron-right"
                            size: 16
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: recentCarousel.contentX < (recentCarousel.originX + recentCarousel.contentWidth - recentCarousel.width - 1)
                            onClicked: recentCarousel.scrollStep(1)
                        }
                    }

                    Item { width: 4; height: 1 }

                    Rectangle {
                        implicitWidth: clearLabel.implicitWidth + 16
                        implicitHeight: 28
                        radius: 14
                        color: clearMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                        StyledText {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: clearMouse.containsMouse ? Theme.primary : Theme.surfaceVariantText
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ImageService.clearRecentImages()
                        }
                    }
                }

                DCarousel {
                    id: recentCarousel
                    Layout.fillWidth: true
                    height: 140
                    preferredItemWidth: Math.min(220, Math.max(160, width * 0.35))
                    smallItemWidth: Style.listItemHeight
                    itemRadius: Style.cornerRadiusM
                    spacing: 10
                    model: ImageService.recentImages

                    property real targetContentX: originX
                    property bool isSmoothScrolling: false

                    onOriginXChanged: targetContentX = originX

                    NumberAnimation {
                        id: smoothScrollAnim
                        target: recentCarousel
                        property: "contentX"
                        duration: 260
                        easing.type: Easing.OutCubic
                        onFinished: {
                            recentCarousel.isSmoothScrolling = false
                        }
                    }

                    function scrollBy(wheel) {
                        const isPad = wheel.phase !== Qt.NoScrollPhase && (wheel.pixelDelta.x !== 0 || wheel.pixelDelta.y !== 0);
                        const delta = isPad
                            ? (Math.abs(wheel.pixelDelta.x) > Math.abs(wheel.pixelDelta.y) ? wheel.pixelDelta.x : wheel.pixelDelta.y)
                            : (Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y) ? wheel.angleDelta.x : wheel.angleDelta.y) / 120 * (itemWidth + spacing);
                        const maxX = originX + Math.max(0, contentWidth - width);

                        if (isPad) {
                            smoothScrollAnim.stop();
                            isSmoothScrolling = false;
                            contentX = Math.max(originX, Math.min(maxX, contentX - delta));
                            targetContentX = contentX;
                        } else {
                            const startX = isSmoothScrolling ? targetContentX : contentX;
                            targetContentX = Math.max(originX, Math.min(maxX, startX - delta));
                            smoothScrollAnim.stop();
                            smoothScrollAnim.from = contentX;
                            smoothScrollAnim.to = targetContentX;
                            isSmoothScrolling = true;
                            smoothScrollAnim.start();
                        }
                    }

                    function scrollStep(dir) {
                        const maxX = originX + Math.max(0, contentWidth - width);
                        const startX = isSmoothScrolling ? targetContentX : contentX;
                        targetContentX = Math.max(originX, Math.min(maxX, startX + dir * (itemWidth + spacing)));
                        smoothScrollAnim.stop();
                        smoothScrollAnim.from = contentX;
                        smoothScrollAnim.to = targetContentX;
                        isSmoothScrolling = true;
                        smoothScrollAnim.start();
                    }

                    delegate: DCarouselItem {
                        id: tile

                        required property var modelData
                        required property int index

                        readonly property var itemData: modelData !== undefined ? modelData : (ImageService.recentImages && ImageService.recentImages[index] ? ImageService.recentImages[index] : null)

                        tooltipText: tile.itemData?.name || ""
                        onClicked: {
                            if (tile.itemData && tile.itemData.path) {
                                const path = tile.itemData.path
                                const thumb = tile.itemData.thumbnail || ""
                                Qt.callLater(() => {
                                    ImageService.openImageFromGallery(path, thumb)
                                })
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceContainerHigh

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                source: {
                                    if (!tile.itemData) return ""
                                    if (tile.itemData.thumbnail) return "file://" + tile.itemData.thumbnail
                                    return "file://" + tile.itemData.path
                                }
                                sourceSize.width: 320
                                sourceSize.height: 320
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 38
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                                }
                            }

                            StyledText {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 8
                                text: tile.itemData?.name || ""
                                elide: Text.ElideRight
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.fontWeightMedium
                                color: "#FFFFFF"
                                visible: tile.maskWidth > 64
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: 12
                }
            }
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
            if (!root.visible) return
            const topY = list.originY < 0 ? list.originY : -72
            root.lastContentY = contentY
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
