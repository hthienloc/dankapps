import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var album: null
    property real cardWidth: 176
    property real previewHeight: 176
    property bool editMode: ImageService.albumsEditMode
    property bool isBeingDragged: false
    property bool isDropTarget: false

    signal dragStarted(var album, Item cardItem, real startMouseX, real startMouseY)
    signal dragMoved(Item cardItem, real mouseX, real mouseY)
    signal dragEnded()

    readonly property bool isFavAlbum: Boolean(album && album.isFavorites)
    readonly property bool isQuickAccess: Boolean(album && (album.isQuickAccess || album.isPinned))
    readonly property bool canEditCard: editMode && !isFavAlbum

    width: cardWidth
    height: previewHeight + 36
    opacity: isBeingDragged ? 0.3 : 1.0

    Behavior on opacity { NumberAnimation { duration: Theme.shorterDuration } }

    ColumnLayout {
        anchors.fill: parent
        spacing: Style.spacingS

        Rectangle {
            id: previewBox
            Layout.fillWidth: true
            Layout.preferredHeight: root.previewHeight
            radius: M3E.tileRadius(cardMouse.pressed, cardHover.hovered || root.isDropTarget, root.canEditCard)
            clip: true
            color: root.isDropTarget ? Theme.primaryContainer : Theme.surfaceContainerHigh
            border.color: root.isDropTarget
                ? Theme.primary
                : (root.canEditCard
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.65)
                    : (cardHover.hovered
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5)
                        : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)))
            border.width: root.isDropTarget ? (Style.outlineWidth * 2) : (root.canEditCard ? Style.outlineWidth : 1)

            scale: root.isDropTarget ? 1.04 : (cardMouse.pressed && !root.canEditCard ? M3E.tilePressScale : (cardHover.hovered && !root.canEditCard ? 1.02 : 1.0))
            Behavior on radius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
            Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

            HoverHandler {
                id: cardHover
            }

            // 2x2 Grid of Previews
            Grid {
                anchors.fill: parent
                anchors.margins: Style.spacingXS
                columns: 2
                rows: 2
                spacing: 3

                readonly property real cellW: Math.floor((width - 3) / 2)
                readonly property real cellH: Math.floor((height - 3) / 2)

                Repeater {
                    model: 4
                    delegate: ClippingRectangle {
                        id: cellClip
                        width: parent.cellW
                        height: parent.cellH
                        radius: Style.cornerRadiusS
                        color: Theme.surfaceContainerLowest

                        readonly property string imgPath: {
                            if (!root.album || !root.album.previews || root.album.previews.length === 0) return "";
                            if (index < root.album.previews.length) {
                                return root.album.previews[index];
                            }
                            return root.album.previews[0] || "";
                        }

                        Image {
                            anchors.fill: parent
                            visible: cellClip.imgPath !== ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            source: cellClip.imgPath !== "" ? ("file://" + cellClip.imgPath) : ""
                            sourceSize.width: 180
                            sourceSize.height: 180
                        }

                        DIcon {
                            anchors.centerIn: parent
                            visible: cellClip.imgPath === ""
                            name: root.isFavAlbum ? "favorite" : "image"
                            size: Style.iconSize
                            color: root.isFavAlbum ? Theme.error : Theme.surfaceVariantText
                            opacity: root.isFavAlbum ? 0.6 : 1.0
                        }
                    }
                }
            }

            // Main card click / drag area
            MouseArea {
                id: cardMouse
                anchors.fill: parent
                cursorShape: root.canEditCard ? (dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.PointingHandCursor
                preventStealing: root.canEditCard

                property bool dragging: false
                property real pressX: 0
                property real pressY: 0

                onPressed: mouse => {
                    pressX = mouse.x;
                    pressY = mouse.y;
                    dragging = false;
                }

                onPositionChanged: mouse => {
                    if (!root.canEditCard || !pressed) return;
                    if (!dragging) {
                        const dx = mouse.x - pressX;
                        const dy = mouse.y - pressY;
                        if (Math.hypot(dx, dy) > 6) {
                            dragging = true;
                            root.dragStarted(root.album, root, pressX, pressY);
                        }
                    }
                    if (dragging) {
                        root.dragMoved(root, mouse.x, mouse.y);
                    }
                }

                onReleased: {
                    if (dragging) {
                        dragging = false;
                        root.dragEnded();
                    }
                }

                onCanceled: {
                    if (dragging) {
                        dragging = false;
                        root.dragEnded();
                    }
                }

                onClicked: {
                    if (root.editMode) return;
                    if (root.album) {
                        ImageService.selectedCategory = root.album.name;
                        ImageService.galleryTab = "gallery";
                    }
                }
            }

            // Top-Right: Delete Folder button (Edit mode only, danger token)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: Style.spacingS
                width: Style.iconSize
                height: Style.iconSize
                radius: height / 2
                visible: root.canEditCard
                z: 2
                color: removeMouse.containsMouse ? Theme.error : Theme.errorContainer
                border.color: Theme.error
                border.width: 1

                DIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: Style.iconSizeSmall
                    color: removeMouse.containsMouse ? Theme.onError : Theme.onErrorContainer
                }

                MouseArea {
                    id: removeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.album) ImageService.removeAlbumFolder(root.album);
                    }
                }
            }
        }

        // Album Title & Count
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.spacingXXS

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacingXS

                DIcon {
                    visible: root.isFavAlbum
                    name: "favorite"
                    size: Style.iconSizeSmall
                    color: Theme.error
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.album ? root.album.name : ""
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.album ? (root.album.totalCount + " photos") : ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
            }
        }
    }
}
