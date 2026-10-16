import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Item {
    id: root

    property var flickable: null // kept for compatibility, unused with ListView virtualization
    property var imageItem: null
    property real tileSize: 160

    width: tileSize
    height: tileSize

    readonly property bool isSelected: imageItem ? ImageService.isSelected(imageItem.path) : false
    readonly property bool isFav: imageItem ? ImageService.isFavorite(imageItem.path) : false
    readonly property bool isSelectionMode: ImageService.gallerySelectedCount > 0

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 0
        color: Theme.surfaceContainerHigh

        scale: thumbMouse.containsMouse ? 1.02 : 1.0
        Behavior on scale { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }

        Image {
            id: thumbImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
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
                ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, thumbMouse.containsMouse ? 0.22 : 0.16)
                : "transparent"
            border.color: root.isSelected
                ? Theme.primary
                : (thumbMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.4) : "transparent")
            border.width: root.isSelected ? 3 : (thumbMouse.containsMouse ? 1 : 0)

            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
            Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }
        }

        // Dark gradient overlay for icons visibility
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            visible: thumbMouse.containsMouse || root.isSelected || root.isFav || root.isSelectionMode
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // Selection Checkbox (Top-Left)
        Rectangle {
            id: selectBtn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 8
            width: 24
            height: 24
            radius: 12
            visible: thumbMouse.containsMouse || root.isSelected || root.isSelectionMode
            color: root.isSelected ? Theme.primary : Qt.rgba(0, 0, 0, 0.35)
            border.color: root.isSelected ? Theme.primary : Qt.rgba(1, 1, 1, 0.8)
            border.width: root.isSelected ? 0 : 1.5

            DIcon {
                anchors.centerIn: parent
                visible: root.isSelected
                name: "check"
                size: 16
                color: Theme.primaryText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.imageItem) ImageService.toggleSelect(root.imageItem.path)
                }
            }
        }

        // Favorite Heart Button (Top-Right)
        Rectangle {
            id: favBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 8
            width: 24
            height: 24
            radius: 12
            visible: thumbMouse.containsMouse || root.isFav
            color: Qt.rgba(0, 0, 0, 0.35)

            DIcon {
                anchors.centerIn: parent
                name: "favorite"
                filled: root.isFav
                size: 16
                color: root.isFav ? Theme.error : Qt.rgba(1, 1, 1, 0.9)
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.imageItem) ImageService.toggleFavorite(root.imageItem.path)
                }
            }
        }

        // Body Click to Open in Viewer or Toggle Selection
        MouseArea {
            id: thumbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: -1
            onClicked: {
                if (root.imageItem) {
                    if (root.isSelectionMode) ImageService.toggleSelect(root.imageItem.path)
                    else ImageService.openImageFromGallery(root.imageItem.path, root.imageItem.thumbnail || "")
                }
            }
        }
    }
}
