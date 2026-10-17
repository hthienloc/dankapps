import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    implicitHeight: 40
    implicitWidth: contentRow.implicitWidth + 16
    radius: height / 2
    color: Style.withAlpha(Theme.cardSurface, 0.92)
    border.color: Theme.withAlpha(Theme.outlineVariant, 0.25)
    border.width: 1

    ElevationShadow {
        anchors.fill: parent
        z: -1
        targetRadius: parent.radius
        targetColor: parent.color
        level: Style.elevationLevel2
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        // Open Video Action
        DActionButton {
            iconName: "folder_open"
            iconSize: 18
            buttonSize: Style.buttonHeightXS
            iconColor: Theme.surfaceText
            tooltipText: "Open Video (O)"
            tooltipSide: "bottom"
            onClicked: VideoService.openFileDialog()
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 18
            color: Theme.outlineVariant
            opacity: 0.35
            Layout.alignment: Qt.AlignVCenter
        }

        // Media Details / Inspector Toggle
        DActionButton {
            iconName: "info"
            iconSize: 18
            buttonSize: Style.buttonHeightXS
            iconColor: VideoService.inspectorOpen ? Theme.primary : Theme.surfaceText
            backgroundColor: VideoService.inspectorOpen ? Theme.secondaryContainer : "transparent"
            tooltipText: "Media Details (I)"
            tooltipSide: "bottom"
            onClicked: VideoService.toggleInspector()
        }

        Rectangle {
            implicitWidth: 1
            implicitHeight: 18
            color: Theme.outlineVariant
            opacity: 0.35
            Layout.alignment: Qt.AlignVCenter
        }

        // Lock UI Action
        DActionButton {
            iconName: "lock_open"
            iconSize: 18
            buttonSize: Style.buttonHeightXS
            iconColor: Theme.surfaceText
            tooltipText: "Lock UI / Clean View (K)"
            tooltipSide: "bottom"
            onClicked: VideoService.toggleLockUI()
        }

        // Counter badge e.g. "2 / 5" if playlist has multiple files
        Rectangle {
            visible: VideoService.fileList.length > 1
            implicitHeight: Style.buttonHeightXS - 6
            implicitWidth: counterText.implicitWidth + 14
            radius: height / 2
            color: Theme.surfaceContainerHighest
            border.color: Theme.withAlpha(Theme.outlineVariant, 0.2)
            border.width: 1
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 2

            StyledText {
                id: counterText
                anchors.centerIn: parent
                text: (VideoService.currentIndex + 1) + " / " + VideoService.fileList.length
                font.pixelSize: Style.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }
        }
    }
}
