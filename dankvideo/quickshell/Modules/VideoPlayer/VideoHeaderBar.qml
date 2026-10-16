import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    property var windowControls: null
    property var targetWindow: null

    implicitHeight: header.implicitHeight
    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.90)
    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
    border.width: 1

    DWindowHeader {
        id: header
        anchors.fill: parent
        controls: root.windowControls
        title: VideoService.currentFileName || "DankVideo"
        onCloseRequested: Qt.quit()

        // Open Video Action
        DActionButton {
            iconName: "folder_open"
            iconSize: Style.iconSizeSmall
            iconColor: Theme.surfaceText
            tooltipText: "Open Video (O)"
            tooltipSide: "bottom"
            onClicked: VideoService.openFileDialog()
        }

        // Media Details / Inspector Toggle
        DActionButton {
            visible: VideoService.currentFilePath !== ""
            iconName: "info"
            iconSize: Style.iconSizeSmall
            iconColor: VideoService.inspectorOpen ? Theme.primary : Theme.surfaceText
            backgroundColor: VideoService.inspectorOpen ? Theme.surfaceContainerHighest : "transparent"
            tooltipText: "Media Details (I)"
            tooltipSide: "bottom"
            onClicked: VideoService.toggleInspector()
        }

        // Lock UI / Zen View
        DActionButton {
            visible: VideoService.currentFilePath !== ""
            iconName: "lock_open"
            iconSize: Style.iconSizeSmall
            iconColor: Theme.surfaceText
            tooltipText: "Lock UI / Clean View (K)"
            tooltipSide: "bottom"
            onClicked: VideoService.toggleLockUI()
        }
    }

    // Leading item: Media metadata badges
    Row {
        id: leadingRow
        anchors.left: parent.left
        anchors.leftMargin: Style.spacingM
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.spacingS

        // Counter badge e.g. "2 / 5"
        Rectangle {
            visible: VideoService.fileList.length > 0
            implicitHeight: 24
            implicitWidth: counterText.implicitWidth + 16
            radius: 12
            color: Theme.surfaceContainerHighest
            anchors.verticalCenter: parent.verticalCenter

            StyledText {
                id: counterText
                anchors.centerIn: parent
                text: (VideoService.currentIndex + 1) + " / " + VideoService.fileList.length
                font.pixelSize: Style.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }
        }

        // Resolution & Codec badge if available
        Rectangle {
            visible: VideoService.currentMeta && (VideoService.currentMeta.videoCodec || VideoService.currentMeta.width > 0)
            implicitHeight: 24
            implicitWidth: codecRow.implicitWidth + 16
            radius: 12
            color: Theme.surfaceContainerHigh
            anchors.verticalCenter: parent.verticalCenter

            RowLayout {
                id: codecRow
                anchors.centerIn: parent
                spacing: 4

                DIcon {
                    name: "hd"
                    size: 14
                    color: Theme.surfaceVariantText
                    visible: VideoService.currentMeta && VideoService.currentMeta.height >= 720
                }

                StyledText {
                    id: codecText
                    text: {
                        if (!VideoService.currentMeta) return "";
                        let parts = [];
                        if (VideoService.currentMeta.videoCodec) {
                            parts.push(VideoService.currentMeta.videoCodec.toUpperCase());
                        }
                        if (VideoService.currentMeta.width > 0) {
                            parts.push(VideoService.currentMeta.width + "x" + VideoService.currentMeta.height);
                        }
                        return parts.join(" • ");
                    }
                    font.pixelSize: Style.fontSizeSmall
                    font.weight: Font.Medium
                    color: Theme.surfaceVariantText
                }
            }
        }
    }
}
