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
        if (ImageService.filterMediaType === "Images only" || ImageService.filterMediaType === "Images") {
            if (/\.gif$/i.test(img.path)) return false
        } else if (ImageService.filterMediaType === "GIFs / Animations" || ImageService.filterMediaType === "GIFs") {
            if (!/\.gif$/i.test(img.path)) return false
        }

        if (!ImageService.filterIncludeHidden && (img.name || "").startsWith(".")) {
            return false
        }

        if (ImageService.filterDateAdded !== "Any time" && ImageService.filterDateAdded !== "All" && img.modTime > 0) {
            const nowSec = Date.now() / 1000
            const diffSec = nowSec - img.modTime
            if (ImageService.filterDateAdded === "Today" && diffSec > 86400) return false
            if ((ImageService.filterDateAdded === "7 days" || ImageService.filterDateAdded === "Last 7 days") && diffSec > 7 * 86400) return false
            if ((ImageService.filterDateAdded === "30 days" || ImageService.filterDateAdded === "Last 30 days") && diffSec > 30 * 86400) return false
            if ((ImageService.filterDateAdded === "1 year" || ImageService.filterDateAdded === "This year") && diffSec > 365 * 86400) return false
        }

        return true
    }

    readonly property var filteredGroups: {
        let base = rawGroups
        const cat = ImageService.selectedCategory
        const result = []
        const seenInTimeline = new Set()

        for (let i = 0; i < base.length; i++) {
            const grp = base[i]
            const imgs = grp.images.filter(img => {
                if (!img || !img.path) return false
                if (ImageService.isPathRemoved(img.path, img.category)) return false
                if (cat && cat !== "All") {
                    if (cat === "Favorites") {
                        if (!ImageService.isFavorite(img.path)) return false
                    } else if (img.category !== cat) {
                        return false
                    }
                }
                if (!matchesQuery(img) || !matchesFilters(img)) return false
                if (seenInTimeline.has(img.path)) return false
                seenInTimeline.add(img.path)
                return true
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
                sorted.push({ dateGroup: g.dateGroup, images: g.images.slice().sort((a, b) => (a.name || "").localeCompare(b.name || "", undefined, { numeric: true, sensitivity: 'base' })) })
            }
            return sorted
        } else if (sortOrder === "Name (Z-A)") {
            const sorted = []
            for (let i = 0; i < result.length; i++) {
                const g = result[i]
                sorted.push({ dateGroup: g.dateGroup, images: g.images.slice().sort((a, b) => (b.name || "").localeCompare(a.name || "", undefined, { numeric: true, sensitivity: 'base' })) })
            }
            return sorted
        }

        return result
    }

    readonly property var targetTileSizes: [100, 135, 170, 230, 320]
    readonly property int zoomIdx: Math.max(0, Math.min(4, (ImageService.galleryZoomLevel || 3) - 1))
    readonly property int targetTileSize: targetTileSizes[zoomIdx]
    readonly property int columns: Math.max(1, Math.floor((width - 40) / targetTileSize))
    readonly property real tileWidth: Math.floor((width - 40 - (columns - 1) * 10) / columns)

    WheelHandler {
        target: null
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                ImageService.galleryZoomLevel = Math.min(5, (ImageService.galleryZoomLevel || 3) + 1)
            } else if (event.angleDelta.y < 0) {
                ImageService.galleryZoomLevel = Math.max(1, (ImageService.galleryZoomLevel || 3) - 1)
            }
            event.accepted = true
        }
    }

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
        ImageService.searchBarCollapsed = false
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
        function onScrollToTopRequested() {
            root.resetScroll()
        }
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

                    DIconButton {
                        iconName: "chevron_left"
                        size: "s"
                        tooltipText: "Previous"
                        enabled: recentCarousel.contentWidth > recentCarousel.width && (recentCarousel.stepAnimRunning ? recentCarousel.targetContentX : recentCarousel.contentX) > recentCarousel.originX + 1
                        onClicked: recentCarousel.scrollBatch(-1)
                    }

                    DIconButton {
                        iconName: "chevron_right"
                        size: "s"
                        tooltipText: "Next"
                        enabled: recentCarousel.contentWidth > recentCarousel.width && (recentCarousel.stepAnimRunning ? recentCarousel.targetContentX : recentCarousel.contentX) < (recentCarousel.originX + recentCarousel.contentWidth - recentCarousel.width - 1)
                        onClicked: recentCarousel.scrollBatch(1)
                    }

                    DButton {
                        text: "Clear"
                        buttonHeight: Style.buttonHeightXS
                        backgroundColor: "transparent"
                        textColor: Theme.primary
                        onClicked: ImageService.clearRecentImages()
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
                        interactive: false
                        snapMode: ListView.NoSnap
                        cacheBuffer: 2000
                        reuseItems: true
                        model: ImageService.recentImages

                        property real targetContentX: originX
                        property real wheelAccumulator: 0
                        readonly property bool stepAnimRunning: stepAnim.running

                        function scrollBy(wheel) {
                            const isHoriz = Math.abs(wheel.angleDelta.x) > Math.abs(wheel.angleDelta.y) || Math.abs(wheel.pixelDelta.x) > Math.abs(wheel.pixelDelta.y);
                            const rawDelta = isHoriz
                                ? (wheel.angleDelta.x !== 0 ? wheel.angleDelta.x : wheel.pixelDelta.x * 6)
                                : (wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.pixelDelta.y * 6);

                            if (rawDelta === 0) {
                                wheel.accepted = false;
                                return;
                            }

                            const maxX = originX + Math.max(0, contentWidth - width);
                            const currentTarget = stepAnim.running ? targetContentX : contentX;
                            const scrollDir = rawDelta < 0 ? 1 : -1;

                            // Allow vertical wheel to scroll timeline list when hitting edges
                            if (!isHoriz && ((scrollDir < 0 && currentTarget <= originX + 1) || (scrollDir > 0 && currentTarget >= maxX - 1))) {
                                wheelAccumulator = 0;
                                wheel.accepted = false;
                                return;
                            }

                            wheelAccumulator += rawDelta;
                            if (Math.abs(wheelAccumulator) >= 60) {
                                const stepDir = wheelAccumulator < 0 ? 1 : -1;
                                wheelAccumulator = 0;
                                scrollSingleItem(stepDir);
                            }
                            wheel.accepted = true;
                        }

                        NumberAnimation {
                            id: stepAnim
                            target: recentCarousel
                            property: "contentX"
                            duration: 260
                            easing.type: Easing.OutQuad
                        }

                        function scrollSingleItem(dir) {
                            const step = itemWidth + spacing;
                            const maxX = originX + Math.max(0, contentWidth - width);
                            const base = stepAnim.running ? targetContentX : contentX;
                            targetContentX = Math.max(originX, Math.min(maxX, base + dir * step));
                            stepAnim.stop();
                            stepAnim.duration = 220;
                            stepAnim.from = contentX;
                            stepAnim.to = targetContentX;
                            stepAnim.start();
                        }

                        function scrollBatch(dir) {
                            const batchCount = Math.max(1, arrangement?.large ?? Math.floor(width / (itemWidth + spacing)));
                            const batchStep = batchCount * (itemWidth + spacing);
                            const maxX = originX + Math.max(0, contentWidth - width);
                            const base = stepAnim.running ? targetContentX : contentX;
                            targetContentX = Math.max(originX, Math.min(maxX, base + dir * batchStep));
                            stepAnim.stop();
                            stepAnim.duration = 280;
                            stepAnim.from = contentX;
                            stepAnim.to = targetContentX;
                            stepAnim.start();
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
                                    height: Math.max(38, nameText.implicitHeight + 16)
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                                    }
                                }

                                StyledText {
                                    id: nameText
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.margins: 8
                                    text: tile.itemData?.name || ""
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.Wrap
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
            id: groupDelegate
            required property var modelData
            required property int index

            width: ListView.view.width - 16
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            readonly property var groupImages: modelData.images || []
            readonly property var groupPaths: groupImages.map(img => img.path)
            readonly property bool hasMultipleImages: groupImages.length > 1
            readonly property int selectedInGroupCount: {
                // Dependency on gallerySelectedFiles
                const sel = ImageService.gallerySelectedFiles;
                let c = 0;
                for (let i = 0; i < groupPaths.length; i++) {
                    if (sel[groupPaths[i]]) c++;
                }
                return c;
            }
            readonly property bool isGroupAllSelected: hasMultipleImages && selectedInGroupCount === groupImages.length
            readonly property bool isGroupIndeterminate: hasMultipleImages && selectedInGroupCount > 0 && !isGroupAllSelected
            readonly property bool isSelectionMode: ImageService.gallerySelectedCount > 0
            readonly property bool showGroupCheckbox: hasMultipleImages && (headerHover.hovered || isSelectionMode)

            // Date Group Header with Checkbox
            Item {
                Layout.fillWidth: true
                implicitHeight: Math.max(dateTitle.implicitHeight, Style.iconSize)

                HoverHandler {
                    id: headerHover
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Style.spacingS

                    // Checkbox for Date Group
                    Rectangle {
                        id: groupCheckBtn
                        width: Style.iconSize
                        height: Style.iconSize
                        radius: height / 2
                        visible: groupDelegate.showGroupCheckbox
                        color: (groupDelegate.isGroupAllSelected || groupDelegate.isGroupIndeterminate)
                            ? (groupCheckMouse.containsMouse ? Theme.primaryContainer : Theme.primary)
                            : (groupCheckMouse.containsMouse ? Theme.withAlpha(Theme.surfaceVariant, 0.45) : Theme.withAlpha(Theme.surfaceVariant, 0.2))
                        border.color: (groupDelegate.isGroupAllSelected || groupDelegate.isGroupIndeterminate)
                            ? Theme.primary
                            : (groupCheckMouse.containsMouse ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.6))
                        border.width: (groupDelegate.isGroupAllSelected || groupDelegate.isGroupIndeterminate) ? 0 : 1.5
                        scale: groupCheckMouse.pressed ? 0.9 : (groupCheckMouse.containsMouse ? 1.1 : 1.0)

                        Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
                        Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
                        Behavior on scale { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }

                        DIcon {
                            anchors.centerIn: parent
                            visible: groupDelegate.isGroupAllSelected || groupDelegate.isGroupIndeterminate
                            name: groupDelegate.isGroupAllSelected ? "check" : "remove"
                            size: Style.iconSizeSmall
                            color: groupCheckMouse.containsMouse ? Theme.onPrimaryContainer : Theme.primaryText
                        }

                        DTooltipHost {
                            anchors.fill: parent
                            text: groupDelegate.isGroupAllSelected ? "Deselect date" : "Select date"
                        }

                        MouseArea {
                            id: groupCheckMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ImageService.toggleSelectGroup(groupDelegate.groupPaths);
                            }
                        }
                    }

                    StyledText {
                        id: dateTitle
                        text: groupDelegate.modelData.dateGroup
                        font.pixelSize: Theme.fontSizeMedium + 1
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }
                }
            }

            Grid {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? implicitHeight : 0
                visible: SettingsData.galleryThumbnailLayout !== "masonry"
                columns: root.columns
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: SettingsData.galleryThumbnailLayout === "masonry" ? [] : groupDelegate.groupImages
                    delegate: GalleryThumbnail {
                        flickable: null
                        imageItem: modelData
                        tileSize: root.tileWidth
                    }
                }
            }

            MasonryGrid {
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? implicitHeight : 0
                visible: SettingsData.galleryThumbnailLayout === "masonry"
                model: SettingsData.galleryThumbnailLayout === "masonry" ? groupDelegate.groupImages : []
                columns: root.columns
                tileWidth: root.tileWidth
                spacing: 10
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
