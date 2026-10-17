import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    width: 380
    color: Style.withAlpha(Theme.cardSurface, 0.96)
    border.color: Theme.withAlpha(Theme.outlineVariant, 0.25)
    border.width: 1

    ElevationShadow {
        anchors.fill: parent
        z: -1
        targetRadius: parent.radius
        targetColor: parent.color
        level: Style.elevationLevel3
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.AllButtons
        onWheel: event => event.accepted = true
    }

    component M3Card: Rectangle {
        Layout.fillWidth: true
        radius: Style.cornerRadiusL
        color: Theme.surfaceContainerHigh
        border.color: Theme.withAlpha(Theme.outlineVariant, 0.20)
        border.width: 1
    }

    component ActionChip: Rectangle {
        property string iconName: ""
        property string label: ""
        property int segIndex: 0
        property int segCount: 2
        signal clicked()

        readonly property real pillR: height / 2
        readonly property real leftR: M3E.leftRadius(segIndex, segCount, pillR, chipMouse.pressed, chipMouse.containsMouse, false, M3E.pressRadiusXS)
        readonly property real rightR: M3E.rightRadius(segIndex, segCount, pillR, chipMouse.pressed, chipMouse.containsMouse, false, M3E.pressRadiusXS)

        Layout.fillWidth: true
        implicitHeight: Style.buttonHeightXS
        topLeftRadius: leftR
        bottomLeftRadius: leftR
        topRightRadius: rightR
        bottomRightRadius: rightR
        scale: chipMouse.pressed ? M3E.rowPressScale : 1.0
        color: chipMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
        border.color: Theme.withAlpha(Theme.outlineVariant, 0.25)
        border.width: Style.outlineWidth

        Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

        RowLayout {
            anchors.centerIn: parent
            spacing: Style.spacingS

            DIcon {
                name: iconName
                size: Style.iconSizeSmall
                color: Theme.primary
            }

            StyledText {
                text: label
                font.pixelSize: Style.fontSizeSmall
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
        spacing: Style.spacingS

        DIcon {
            name: iconName
            size: Style.chipIconSize
            color: Theme.primary
        }

        StyledText {
            Layout.fillWidth: true
            text: title
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
        spacing: Style.spacingM

        StyledText {
            Layout.preferredWidth: 105
            text: label
            font.pixelSize: Style.fontSizeSmall
            color: Theme.surfaceVariantText
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            text: value
            font.family: isMono ? Theme.monoFontFamily : Theme.fontFamily
            font.pixelSize: Style.fontSizeSmall
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
            height: Style.buttonHeightM
            color: Theme.surfaceContainer

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Style.spacingL
                anchors.rightMargin: Style.spacingS
                spacing: Style.spacingS

                DIcon {
                    name: "info"
                    size: Style.iconSizeMedium
                    color: Theme.primary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: "Media Details"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                DActionButton {
                    iconName: "close"
                    iconSize: Style.iconSizeSmall
                    buttonSize: Style.buttonHeightXS
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
        DFlickable {
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
                            spacing: M3E.groupGap

                            ActionChip {
                                segIndex: 0
                                segCount: 2
                                iconName: "content_copy"
                                label: "Copy Path"
                                onClicked: VideoService.copyPathToClipboard()
                            }

                            ActionChip {
                                segIndex: 1
                                segCount: 2
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
