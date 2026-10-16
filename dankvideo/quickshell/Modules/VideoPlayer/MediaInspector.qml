import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Rectangle {
    id: root

    width: 380
    color: Qt.rgba(Theme.surfaceContainer.r, Theme.surfaceContainer.g, Theme.surfaceContainer.b, 0.96)
    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
    border.width: 1

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.AllButtons
        onWheel: event => event.accepted = true
    }

    component M3Card: Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.surfaceContainerHigh
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.18)
        border.width: 1
    }

    component ActionChip: Rectangle {
        property string iconName: ""
        property string label: ""
        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 34
        radius: 8
        color: chipMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            DIcon {
                name: iconName
                size: 16
                color: Theme.primary
            }

            Text {
                text: label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    component SectionHeader: RowLayout {
        property string title: ""
        property string iconName: ""

        Layout.fillWidth: true
        spacing: 8

        DIcon {
            name: iconName
            size: 18
            color: Theme.primary
        }

        Text {
            Layout.fillWidth: true
            text: title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Font.DemiBold
            color: Theme.primary
        }
    }

    component DetailRow: RowLayout {
        property string label: ""
        property string value: ""
        property bool isMono: false
        visible: value !== ""

        Layout.fillWidth: true
        spacing: 12

        Text {
            Layout.preferredWidth: 105
            text: label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            text: value
            font.family: isMono ? Theme.monoFontFamily : Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: Theme.surfaceText
            wrapMode: Text.WrapAnywhere
            elide: Text.ElideRight
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: Theme.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 10
                spacing: 10

                DIcon {
                    name: "info"
                    size: 20
                    color: Theme.primary
                }

                Text {
                    Layout.fillWidth: true
                    text: "Media Details"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                DActionButton {
                    iconName: "close"
                    iconSize: 18
                    iconColor: Theme.surfaceText
                    tooltipText: "Close Panel (Esc)"
                    tooltipSide: "bottom"
                    onClicked: VideoService.inspectorOpen = false
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
            opacity: 0.2
        }

        // Scrollable content
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentCol.implicitHeight + 32
            clip: true

            ColumnLayout {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 14

                // Video File Card
                M3Card {
                    implicitHeight: fileCol.implicitHeight + 20

                    ColumnLayout {
                        id: fileCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        SectionHeader {
                            title: "File Information"
                            iconName: "description"
                        }

                        DetailRow {
                            label: "File Name"
                            value: VideoService.currentFileName
                        }

                        DetailRow {
                            label: "Location"
                            value: VideoService.currentMeta.directory || ""
                        }

                        DetailRow {
                            label: "Size"
                            value: {
                                const sz = VideoService.currentMeta.fileSize || 0;
                                if (sz <= 0) return "";
                                if (sz < 1024 * 1024) return (sz / 1024).toFixed(1) + " KB";
                                return (sz / (1024 * 1024)).toFixed(2) + " MB";
                            }
                            isMono: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 8

                            ActionChip {
                                iconName: "content_copy"
                                label: "Copy Path"
                                onClicked: VideoService.copyPathToClipboard()
                            }

                            ActionChip {
                                iconName: "folder_open"
                                label: "Open Folder"
                                onClicked: VideoService.openContainingFolder()
                            }
                        }
                    }
                }

                // Video Stream Details
                M3Card {
                    implicitHeight: videoStreamCol.implicitHeight + 20

                    ColumnLayout {
                        id: videoStreamCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        SectionHeader {
                            title: "Video Stream"
                            iconName: "videocam"
                        }

                        DetailRow {
                            label: "Resolution"
                            value: (VideoService.currentMeta.width > 0) ? (VideoService.currentMeta.width + " × " + VideoService.currentMeta.height) : ""
                            isMono: true
                        }

                        DetailRow {
                            label: "Codec"
                            value: VideoService.currentMeta.videoCodec ? VideoService.currentMeta.videoCodec.toUpperCase() : ""
                        }

                        DetailRow {
                            label: "Duration"
                            value: VideoService.formatTime(VideoService.duration)
                            isMono: true
                        }

                        DetailRow {
                            label: "Bitrate"
                            value: VideoService.currentMeta.bitrate > 0 ? (Math.round(VideoService.currentMeta.bitrate / 1000) + " kbps") : ""
                            isMono: true
                        }
                    }
                }

                // Audio Stream Details
                M3Card {
                    visible: VideoService.currentMeta.audioCodec !== undefined && VideoService.currentMeta.audioCodec !== ""
                    implicitHeight: audioStreamCol.implicitHeight + 20

                    ColumnLayout {
                        id: audioStreamCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        SectionHeader {
                            title: "Audio Stream"
                            iconName: "audiotrack"
                        }

                        DetailRow {
                            label: "Codec"
                            value: VideoService.currentMeta.audioCodec ? VideoService.currentMeta.audioCodec.toUpperCase() : ""
                        }
                    }
                }
            }
        }
    }
}
