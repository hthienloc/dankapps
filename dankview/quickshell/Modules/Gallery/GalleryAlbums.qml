import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property string query: ImageService.searchQueryDebounced
    readonly property bool editMode: ImageService.albumsEditMode

    property var draggedAlbum: null
    property real dragX: 0
    property real dragY: 0
    property real dragOffsetX: 88
    property real dragOffsetY: 88
    property int dropTargetIndex: -1
    property bool dropTargetInQA: false
    property bool hasDropTarget: false
    property real dropIndicatorX: 0
    property real dropIndicatorY: 0
    property real dropIndicatorHeight: 176

    onEditModeChanged: {
        if (!editMode) {
            draggedAlbum = null;
            hasDropTarget = false;
            dropTargetIndex = -1;
        }
    }

    function startDrag(album, cardItem, startMouseX, startMouseY) {
        if (!album || album.isFavorites) return;
        draggedAlbum = album;
        dragOffsetX = startMouseX;
        dragOffsetY = startMouseY;
        const pt = cardItem.mapToItem(root, startMouseX, startMouseY);
        dragX = pt.x - dragOffsetX;
        dragY = pt.y - dragOffsetY;
        updateDropTarget(pt.x, pt.y);
    }

    function moveDrag(cardItem, mouseX, mouseY) {
        if (!draggedAlbum) return;
        const pt = cardItem.mapToItem(root, mouseX, mouseY);
        dragX = pt.x - dragOffsetX;
        dragY = pt.y - dragOffsetY;
        updateDropTarget(pt.x, pt.y);
    }

    function calculateGap(repeater, containerItem, rootX, rootY) {
        const count = repeater.count;
        if (count === 0) {
            const tl = containerItem.mapToItem(root, 0, 0);
            return { index: 0, x: tl.x, y: tl.y, height: 176 };
        }

        const items = [];
        for (let i = 0; i < count; i++) {
            const it = repeater.itemAt(i);
            if (!it || !it.visible) continue;
            const pt = it.mapToItem(root, 0, 0);
            items.push({
                index: i,
                x: pt.x,
                y: pt.y,
                width: it.width,
                height: it.height,
                previewHeight: it.previewHeight || 176
            });
        }

        if (items.length === 0) {
            const tl = containerItem.mapToItem(root, 0, 0);
            return { index: 0, x: tl.x, y: tl.y, height: 176 };
        }

        const spacing = Style.spacingL;

        // Group cards into rows based on Y coordinates
        const rows = [];
        let currentRow = [items[0]];
        for (let i = 1; i < items.length; i++) {
            if (Math.abs(items[i].y - currentRow[0].y) < 24) {
                currentRow.push(items[i]);
            } else {
                rows.push(currentRow);
                currentRow = [items[i]];
            }
        }
        rows.push(currentRow);

        // Find closest row to rootY
        let bestRow = rows[0];
        let bestRowDist = Infinity;
        for (let r = 0; r < rows.length; r++) {
            const rowY = rows[r][0].y;
            const rowH = rows[r][0].height;
            let distY = 0;
            if (rootY < rowY) distY = rowY - rootY;
            else if (rootY > rowY + rowH) distY = rootY - (rowY + rowH);
            if (distY < bestRowDist) {
                bestRowDist = distY;
                bestRow = rows[r];
            }
        }

        // Before first card in row
        if (rootX < bestRow[0].x + bestRow[0].width / 2) {
            return {
                index: bestRow[0].index,
                x: Math.max(bestRow[0].x - spacing / 2, 4),
                y: bestRow[0].y,
                height: bestRow[0].previewHeight
            };
        }

        // Between cards in row
        for (let j = 0; j < bestRow.length - 1; j++) {
            const mid = (bestRow[j].x + bestRow[j].width + bestRow[j + 1].x) / 2;
            if (rootX < mid) {
                return {
                    index: bestRow[j].index + 1,
                    x: bestRow[j].x + bestRow[j].width + spacing / 2,
                    y: bestRow[j].y,
                    height: bestRow[j].previewHeight
                };
            }
        }

        // After last card in row
        const lastInRow = bestRow[bestRow.length - 1];
        return {
            index: lastInRow.index + 1,
            x: lastInRow.x + lastInRow.width + spacing / 2,
            y: lastInRow.y,
            height: lastInRow.previewHeight
        };
    }

    function updateDropTarget(rootX, rootY) {
        if (!foldersSection) {
            hasDropTarget = false;
            return;
        }

        const fTL = foldersSection.mapToItem(root, 0, 0);
        const inQA = rootY < fTL.y - 10;
        dropTargetInQA = inQA;

        const res = inQA
            ? calculateGap(qaRepeater, qaFlow, rootX, rootY)
            : calculateGap(foldersRepeater, foldersSection, rootX, rootY);

        if (res) {
            dropTargetIndex = res.index;
            dropIndicatorX = res.x;
            dropIndicatorY = res.y;
            dropIndicatorHeight = res.height;
            hasDropTarget = true;
        } else {
            hasDropTarget = false;
        }
    }

    function finishDrag() {
        if (draggedAlbum && hasDropTarget) {
            ImageService.reorderAlbum(draggedAlbum.name, dropTargetIndex, dropTargetInQA);
        }
        draggedAlbum = null;
        hasDropTarget = false;
        dropTargetIndex = -1;
    }

    readonly property var filteredQuickAccessFolders: {
        const list = ImageService.quickAccessFolderAlbums;
        if (!query) return list;
        return list.filter(a => (a._lowerName || (a.name || "").toLowerCase()).indexOf(query) !== -1);
    }

    readonly property var effectiveQuickAccess: {
        return filteredQuickAccessFolders;
    }

    readonly property var filteredFolders: {
        const list = ImageService.folderAlbums;
        if (!query) return list;
        return list.filter(a => (a._lowerName || (a.name || "").toLowerCase()).indexOf(query) !== -1);
    }

    onVisibleChanged: {
        if (visible) {
            albumsFlick.contentY = 0
            albumsFlick.prevContentY = 0
            albumsFlick.accumulatedDown = 0
        }
    }

    DFlickable {
        id: albumsFlick
        anchors.fill: parent
        anchors.leftMargin: Style.spacingM
        anchors.rightMargin: Style.spacingM
        contentHeight: albumsCol.implicitHeight + 72 + 80
        interactive: root.draggedAlbum === null
        clip: true
        property real prevContentY: 0
        property real accumulatedDown: 0

        Connections {
            target: ImageService
            function onScrollToTopRequested() {
                albumsFlick.stopMomentum()
                albumsFlick.contentY = 0
                albumsFlick.prevContentY = 0
                albumsFlick.accumulatedDown = 0
                ImageService.searchBarCollapsed = false
            }
            function onSearchBarCollapsedChanged() {
                if (!ImageService.searchBarCollapsed) {
                    albumsFlick.prevContentY = albumsFlick.contentY
                    albumsFlick.accumulatedDown = 0
                }
            }
        }

        onContentYChanged: {
            if (contentY <= 8) {
                accumulatedDown = 0
                ImageService.searchBarCollapsed = false
            } else {
                const delta = contentY - prevContentY
                if (delta > 0) {
                    accumulatedDown += delta
                    if (accumulatedDown > 12 && contentY > 20) {
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

        ColumnLayout {
            id: albumsCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Style.spacingS
            anchors.rightMargin: Style.spacingS
            anchors.top: parent.top
            anchors.topMargin: 72
            spacing: Style.spacingXL

            // Top Header: Quick Access Title + Edit / Add Folder Controls
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacingS

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.spacingXXS

                    StyledText {
                        text: "Quick Access"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }

                    StyledText {
                        visible: root.editMode
                        text: "Drag folders to reorder or move between Quick Access and Folders"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Restore hidden default folders button (Edit mode only)
                Rectangle {
                    visible: root.editMode && ImageService.hasRemovedFolders
                    implicitHeight: Style.buttonHeightXS
                    implicitWidth: restoreRow.implicitWidth + Style.spacingL
                    radius: height / 2
                    color: restoreMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                    border.width: 1

                    RowLayout {
                        id: restoreRow
                        anchors.centerIn: parent
                        spacing: Style.spacingXS

                        DIcon {
                            name: "restore"
                            size: Style.iconSizeSmall
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "Restore Hidden"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: restoreMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ImageService.restoreRemovedFolders()
                    }
                }


                // Edit button (triggers bottom dock morph to Cancel / Confirm)
                Rectangle {
                    visible: !root.editMode
                    implicitHeight: Style.buttonHeightXS
                    implicitWidth: editBtnRow.implicitWidth + Style.spacingL
                    radius: M3E.tileRadius(editBtnMouse.pressed, editBtnMouse.containsMouse, false)
                    color: editBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                    border.width: 1

                    Behavior on radius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

                    RowLayout {
                        id: editBtnRow
                        anchors.centerIn: parent
                        spacing: Style.spacingXS

                        DIcon {
                            name: "edit"
                            size: Style.iconSizeSmall
                            color: Theme.surfaceText
                        }

                        StyledText {
                            text: "Edit"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: editBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ImageService.startEditAlbums()
                    }
                }
            }

            // Search feedback
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.buttonHeightXS
                visible: root.query !== "" && root.effectiveQuickAccess.length === 0 && root.filteredFolders.length === 0

                RowLayout {
                    anchors.centerIn: parent
                    spacing: Style.spacingS
                    DIcon { name: "search_off"; size: Style.chipIconSize; color: Theme.surfaceVariantText }
                    StyledText {
                        text: 'No results for "' + ImageService.searchQuery + '"'
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }
            }

            // Quick Access Cards Flow
            Flow {
                id: qaFlow
                Layout.fillWidth: true
                spacing: Style.spacingL
                visible: root.effectiveQuickAccess.length > 0

                Repeater {
                    id: qaRepeater
                    model: root.effectiveQuickAccess

                    delegate: AlbumCard {
                        required property var modelData

                        album: modelData
                        cardWidth: 176
                        previewHeight: 176
                        isBeingDragged: Boolean(root.draggedAlbum && root.draggedAlbum.name === modelData.name)
                        onDragStarted: (alb, item, sx, sy) => root.startDrag(alb, item, sx, sy)
                        onDragMoved: (item, mx, my) => root.moveDrag(item, mx, my)
                        onDragEnded: () => root.finishDrag()
                    }
                }
            }

            // Other Folders Section
            ColumnLayout {
                id: foldersSection
                Layout.fillWidth: true
                spacing: Style.spacingM
                visible: root.filteredFolders.length > 0 || root.editMode || !root.query

                StyledText {
                    text: "Folders"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Style.spacingL

                    Repeater {
                        id: foldersRepeater
                        model: root.filteredFolders

                        delegate: AlbumCard {
                            required property var modelData

                            album: modelData
                            cardWidth: 176
                            previewHeight: 176
                            isBeingDragged: Boolean(root.draggedAlbum && root.draggedAlbum.name === modelData.name)
                            onDragStarted: (alb, item, sx, sy) => root.startDrag(alb, item, sx, sy)
                            onDragMoved: (item, mx, my) => root.moveDrag(item, mx, my)
                            onDragEnded: () => root.finishDrag()
                        }
                    }

                    // Empty album card with (+) to add folder
                    Item {
                        id: addFolderCard
                        width: 176
                        height: 176 + 36
                        visible: !root.query

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: Style.spacingS

                            Rectangle {
                                id: addPreviewBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 176
                                radius: 0
                                color: addCardHover.hovered
                                    ? Theme.surfaceContainerHighest
                                    : Theme.surfaceContainerHigh
                                border.color: addCardHover.hovered
                                    ? Theme.primary
                                    : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                                border.width: addCardHover.hovered ? Style.outlineWidth : 1

                                scale: addCardMouse.pressed ? M3E.tilePressScale : (addCardHover.hovered ? 1.02 : 1.0)

                                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }
                                Behavior on border.color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                                HoverHandler {
                                    id: addCardHover
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 48
                                    height: 48
                                    radius: 0
                                    color: addCardHover.hovered ? Theme.primaryContainer : Theme.surfaceContainerLowest
                                    border.color: addCardHover.hovered ? Theme.primary : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                                    border.width: 1

                                    DIcon {
                                        anchors.centerIn: parent
                                        name: "add"
                                        size: 28
                                        color: addCardHover.hovered ? Theme.primary : Theme.surfaceVariantText
                                    }
                                }

                                MouseArea {
                                    id: addCardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ImageService.openAddFolderDialog()
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Style.spacingXXS

                                StyledText {
                                    Layout.fillWidth: true
                                    text: "Add Folder"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Theme.fontWeightBold
                                    color: addCardHover.hovered ? Theme.primary : Theme.surfaceText
                                    elide: Text.ElideRight
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: "Choose directory"
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Drop Insertion Gap Indicator
    Rectangle {
        id: dropIndicator
        visible: root.draggedAlbum !== null && root.hasDropTarget
        x: Math.round(root.dropIndicatorX - width / 2)
        y: Math.round(root.dropIndicatorY)
        width: 4
        height: root.dropIndicatorHeight
        radius: 2
        color: Theme.primary
        z: 95

        // Subtle glow / pill effect
        Rectangle {
            anchors.centerIn: parent
            width: parent.width + 4
            height: parent.height + 4
            radius: 4
            color: Theme.primary
            opacity: 0.35
            z: -1
        }

        // Top dot cap
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -3
            width: 8
            height: 8
            radius: 4
            color: Theme.primary
        }

        // Bottom dot cap
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -3
            width: 8
            height: 8
            radius: 4
            color: Theme.primary
        }

        Behavior on x {
            DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
        }
        Behavior on y {
            DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
        }
        Behavior on height {
            DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
        }
    }

    // Floating Drag Ghost Preview
    AlbumCard {
        visible: root.draggedAlbum !== null
        album: root.draggedAlbum
        x: root.dragX
        y: root.dragY
        cardWidth: 176
        previewHeight: 176
        editMode: false
        scale: 1.05
        opacity: 0.92
        z: 100
    }
}
