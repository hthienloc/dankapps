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
    property string dropTargetName: ""
    property bool dropTargetInQA: false
    property bool hasDropTarget: false

    onEditModeChanged: {
        if (!editMode) {
            draggedAlbum = null;
            dropTargetName = "";
            hasDropTarget = false;
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

    function updateDropTarget(rootX, rootY) {
        // Check Quick Access cards first
        for (let i = 0; i < qaRepeater.count; i++) {
            const item = qaRepeater.itemAt(i);
            if (!item || !item.visible || !item.album) continue;
            const tl = item.mapToItem(root, 0, 0);
            if (rootX >= tl.x && rootX <= tl.x + item.width && rootY >= tl.y && rootY <= tl.y + item.height) {
                dropTargetName = item.album.isFavorites ? "" : item.album.name;
                dropTargetInQA = true;
                hasDropTarget = true;
                return;
            }
        }
        // Check Folders cards
        for (let i = 0; i < foldersRepeater.count; i++) {
            const item = foldersRepeater.itemAt(i);
            if (!item || !item.visible || !item.album) continue;
            const tl = item.mapToItem(root, 0, 0);
            if (rootX >= tl.x && rootX <= tl.x + item.width && rootY >= tl.y && rootY <= tl.y + item.height) {
                dropTargetName = item.album.name;
                dropTargetInQA = false;
                hasDropTarget = true;
                return;
            }
        }
        // Check if hovered over Quick Access section or Folders section generally
        const qaTL = qaFlow.mapToItem(root, 0, 0);
        if (rootY >= qaTL.y - 20 && rootY <= qaTL.y + Math.max(qaFlow.height, 180) + 20) {
            dropTargetName = "";
            dropTargetInQA = true;
            hasDropTarget = true;
            return;
        }
        const fTL = foldersSection.mapToItem(root, 0, 0);
        if (rootY >= fTL.y - 20) {
            dropTargetName = "";
            dropTargetInQA = false;
            hasDropTarget = true;
            return;
        }
        hasDropTarget = false;
        dropTargetName = "";
    }

    function finishDrag() {
        if (draggedAlbum && hasDropTarget) {
            ImageService.reorderAlbum(draggedAlbum.name, dropTargetName, dropTargetInQA);
        }
        draggedAlbum = null;
        dropTargetName = "";
        hasDropTarget = false;
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

    DFlickable {
        id: albumsFlick
        anchors.fill: parent
        anchors.leftMargin: Style.spacingM
        anchors.rightMargin: Style.spacingM
        contentHeight: albumsCol.implicitHeight + 64 + 80
        interactive: root.draggedAlbum === null
        clip: true
        property real prevContentY: 0
        property real accumulatedDown: 0

        Connections {
            target: ImageService
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
            anchors.topMargin: 64
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
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
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

                // Add Folder button (Edit mode only)
                Rectangle {
                    visible: root.editMode
                    implicitHeight: Style.buttonHeightXS
                    implicitWidth: addFolderRow.implicitWidth + Style.spacingL
                    radius: height / 2
                    color: addFolderMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
                    border.width: 1

                    RowLayout {
                        id: addFolderRow
                        anchors.centerIn: parent
                        spacing: Style.spacingXS

                        DIcon {
                            name: "create_new_folder"
                            size: Style.iconSizeSmall
                            color: Theme.primary
                        }

                        StyledText {
                            text: "Add Folder"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: Theme.surfaceText
                        }
                    }

                    MouseArea {
                        id: addFolderMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ImageService.openAddFolderDialog()
                    }
                }

                // Edit button (triggers bottom dock morph to Cancel / Confirm)
                Rectangle {
                    visible: !root.editMode
                    implicitHeight: Style.buttonHeightXS
                    implicitWidth: editBtnRow.implicitWidth + Style.spacingL
                    radius: M3E.tileRadius(editBtnMouse.pressed, editBtnMouse.containsMouse, false)
                    color: editBtnMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
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
                        isDropTarget: Boolean(root.draggedAlbum && root.hasDropTarget && root.dropTargetInQA && root.dropTargetName === modelData.name && root.draggedAlbum.name !== modelData.name)
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
                visible: root.filteredFolders.length > 0 || root.editMode

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
                            isDropTarget: Boolean(root.draggedAlbum && root.hasDropTarget && !root.dropTargetInQA && root.dropTargetName === modelData.name && root.draggedAlbum.name !== modelData.name)
                            onDragStarted: (alb, item, sx, sy) => root.startDrag(alb, item, sx, sy)
                            onDragMoved: (item, mx, my) => root.moveDrag(item, mx, my)
                            onDragEnded: () => root.finishDrag()
                        }
                    }
                }
            }
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
