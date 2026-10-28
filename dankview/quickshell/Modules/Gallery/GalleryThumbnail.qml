import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var flickable: null // kept for compatibility, unused with ListView virtualization
    property var imageItem: null
    property real tileSize: 160
    property bool isTrashMode: false
    property string thumbnailLayout: SettingsData.galleryThumbnailLayout
    property int masonryColumn: -1
    property var navigationPaths: []

    width: tileSize
    height: thumbnailLayout === "masonry"
        ? width / Math.max(0.25, Math.min(4, imageAspectRatio))
        : tileSize

    readonly property bool isSelected: imageItem ? ImageService.isSelected(imageItem.path) : false
    readonly property bool isFav: imageItem ? ImageService.isFavorite(imageItem.path) : false
    readonly property bool isSelectionMode: ImageService.gallerySelectedCount > 0
    readonly property bool isCardHovered: cardHover.hovered
    readonly property real imageAspectRatio: thumbImg.status === Image.Ready && thumbImg.implicitHeight > 0
        ? thumbImg.implicitWidth / thumbImg.implicitHeight
        : 1

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 0
        color: Theme.surfaceContainerHigh

        scale: root.isCardHovered ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }

        HoverHandler {
            id: cardHover
        }

        Image {
            id: thumbImg
            anchors.fill: parent
            fillMode: root.thumbnailLayout === "crop" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
            asynchronous: true
            cache: true
            source: {
                if (!root.imageItem) return ""
                if (root.imageItem.thumbnail) return "file://" + root.imageItem.thumbnail
                return "file://" + root.imageItem.path
            }
            sourceSize.width: 256
            sourceSize.height: 256
        }

        // Selection Border & Highlight Tint Overlay — square (no clip)
        Rectangle {
            id: selectionOverlay
            anchors.fill: parent
            radius: 0
            color: root.isSelected
                ? Theme.withAlpha(Theme.primary, root.isCardHovered ? 0.22 : 0.16)
                : "transparent"
            border.color: root.isSelected
                ? Theme.primary
                : (root.isCardHovered ? Theme.withAlpha(Theme.surfaceText, 0.4) : "transparent")
            border.width: root.isSelected ? 3 : (root.isCardHovered ? 1 : 0)

            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
            Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
        }

        // Dark gradient overlay for icons visibility
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Style.buttonHeightS
            visible: root.isCardHovered || root.isSelected || (!root.isTrashMode && root.isFav) || root.isSelectionMode
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.withAlpha(Theme.scrimColor, 0.55) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Selection Checkbox (Top-Left)
        Rectangle {
            id: selectBtn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Style.spacingS
            width: Style.iconSize
            height: Style.iconSize
            radius: height / 2
            visible: root.isCardHovered || root.isSelected || root.isSelectionMode
            color: root.isSelected
                ? (selectMouse.containsMouse ? Theme.primaryContainer : Theme.primary)
                : (selectMouse.containsMouse ? Theme.withAlpha(Theme.scrimColor, 0.6) : Theme.withAlpha(Theme.scrimColor, 0.35))
            border.color: root.isSelected
                ? Theme.primary
                : (selectMouse.containsMouse ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.8))
            border.width: root.isSelected ? 0 : 1.5
            scale: selectMouse.pressed ? 0.9 : (selectMouse.containsMouse ? 1.1 : 1.0)

            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
            Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
            Behavior on scale { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }

            DIcon {
                anchors.centerIn: parent
                visible: root.isSelected
                name: "check"
                size: Style.iconSizeSmall
                color: root.isSelected && selectMouse.containsMouse ? Theme.onPrimaryContainer : Theme.primaryText
            }

            MouseArea {
                id: selectMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.imageItem) ImageService.toggleSelect(root.imageItem.path)
                }
            }
        }

        // Top-Right Action Button: Restore (Trash mode) or Favorite Heart (Normal)
        Rectangle {
            id: actionBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Style.spacingS
            width: Style.iconSize
            height: Style.iconSize
            radius: height / 2
            visible: root.isCardHovered || (!root.isTrashMode && root.isFav)
            color: actionMouse.containsMouse ? Theme.withAlpha(Theme.scrimColor, 0.6) : Theme.withAlpha(Theme.scrimColor, 0.35)
            scale: actionMouse.pressed ? 0.9 : (actionMouse.containsMouse ? 1.1 : 1.0)

            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
            Behavior on scale { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }

            DIcon {
                anchors.centerIn: parent
                name: root.isTrashMode ? "restore" : "favorite"
                filled: !root.isTrashMode && root.isFav
                size: Style.iconSizeSmall
                color: root.isTrashMode
                    ? (actionMouse.containsMouse ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.8))
                    : (root.isFav
                        ? (actionMouse.containsMouse ? Qt.lighter(Theme.error, 1.2) : Theme.error)
                        : (actionMouse.containsMouse ? Theme.surfaceText : Theme.withAlpha(Theme.surfaceText, 0.8)))
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.imageItem) return
                    if (root.isTrashMode) {
                        ImageService.restoreFromTrash(root.imageItem)
                    } else {
                        ImageService.toggleFavorite(root.imageItem.path)
                    }
                }
            }
        }

        // Body Click to Open in Viewer or Toggle Selection
        MouseArea {
            id: thumbMouse
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            z: -1
            onClicked: {
                if (root.imageItem) {
                    if (root.isSelectionMode) ImageService.toggleSelect(root.imageItem.path)
                    else ImageService.openImageFromGallery(root.imageItem.path, root.imageItem.thumbnail || "", root.navigationPaths)
                }
            }
        }
    }
}
