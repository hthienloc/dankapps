import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    required property var windowControls
    implicitHeight: header.implicitHeight

    signal closeRequested

    DWindowHeader {
        id: header
        anchors.fill: parent
        controls: root.windowControls
        title: ImageService.galleryMode ? "Gallery" : (ImageService.currentFileName || "DankView")
        onCloseRequested: root.closeRequested()
    }

    // Leading item: Back to Gallery button / App icon
    Row {
        id: leadingRow
        anchors.left: parent.left
        anchors.leftMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingS

        DIconButton {
            visible: !ImageService.galleryMode
            iconName: "arrow_back"
            size: "s"
            variant: "standard"
            tooltipText: "Back to Gallery (Esc)"
            Accessible.name: "Back to Gallery"
            onClicked: ImageService.backToGallery()
        }

        DIcon {
            visible: ImageService.galleryMode
            name: "image"
            size: Style.iconSizeSmall
            color: Style.primary
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
