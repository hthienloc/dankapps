import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Rectangle {
    id: root

    width: 760
    height: 480
    radius: 20
    color: Theme.withAlpha(Theme.cardSurface, 0.97)
    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.28)
    border.width: 1

    // Grab handle indicator for bottom sheet (Click to dismiss/close)
    Item {
        id: grabHandleArea
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 120
        height: 24
        z: 10

        Rectangle {
            id: grabHandleBar
            anchors.centerIn: parent
            width: grabHandleMouse.containsMouse ? 48 : 36
            height: 4
            radius: 2
            color: grabHandleMouse.containsMouse ? Theme.primary : Qt.rgba(1, 1, 1, 0.38)

            Behavior on width { NumberAnimation { duration: Theme.shortDuration; easing.type: Theme.standardEasing } }
            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
        }

        MouseArea {
            id: grabHandleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: ImageService.inspectorOpen = false
        }
    }

    component M3Card: Rectangle {
        Layout.fillWidth: true
        radius: 14
        color: Theme.surfaceContainerHigh
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.20)
        border.width: 1
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

        StyledText {
            Layout.fillWidth: true
            text: title
            font.pixelSize: Theme.fontSizeMedium
            font.weight: Theme.fontWeightBold
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

        StyledText {
            Layout.preferredWidth: 110
            text: label
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Theme.fontWeightMedium
            color: Theme.surfaceVariantText
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            text: value
            font.family: isMono ? Theme.monoFontFamily : Theme.fontFamily
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Theme.fontWeightMedium
            color: Theme.surfaceText
            wrapMode: Text.WrapAnywhere
            elide: Text.ElideRight
        }
    }

    component ActionChip: Rectangle {
        id: chip
        property string iconName: ""
        property string label: ""
        property color iconColor: Theme.primary
        property color labelColor: Theme.surfaceText
        signal clicked()

        implicitHeight: 32
        implicitWidth: chipRow.implicitWidth + 20
        radius: 8
        color: chipMouse.containsMouse ? Theme.surfaceContainerHighest : (Theme.surfaceContainerLow || Theme.surfaceContainerHigh)
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.28)
        border.width: 1

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            DIcon {
                name: chip.iconName
                size: 16
                color: chip.iconColor
            }

            StyledText {
                text: chip.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeightMedium
                color: chip.labelColor
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component PillBadge: Rectangle {
        property alias text: badgeText.text
        property color textColor: Theme.surfaceText
        property color bgColor: Theme.surfaceContainerHighest
        property color borderColor: "transparent"

        implicitHeight: 24
        implicitWidth: badgeText.implicitWidth + 14
        radius: 8
        color: bgColor
        border.color: borderColor
        border.width: borderColor !== "transparent" ? 1 : 0

        StyledText {
            id: badgeText
            anchors.centerIn: parent
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Theme.fontWeightMedium
            color: textColor
        }
    }

    component SpecCell: Rectangle {
        property string label: ""
        property string value: "—"

        Layout.fillWidth: true
        implicitHeight: 48
        radius: 10
        color: Theme.surfaceContainerLow || Theme.surfaceContainerHigh
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.16)
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: label
                font.pixelSize: Theme.fontSizeSmall - 2
                font.weight: Font.Normal
                color: Theme.surfaceVariantText
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: value
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceText
            }
        }
    }

    // Prevent mouse clicks and drags from falling through to the canvas underneath
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        preventStealing: true
        onPressed: mouse => mouse.accepted = true
        onReleased: mouse => mouse.accepted = true
        onClicked: mouse => mouse.accepted = true
        onDoubleClicked: mouse => mouse.accepted = true
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 16
            Layout.bottomMargin: 10
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 10

            DIcon {
                name: "info"
                size: 20
                color: Theme.primary
            }

            StyledText {
                Layout.fillWidth: true
                text: "Image Details"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceText
            }

            DActionButton {
                iconName: "delete"
                iconSize: 18
                buttonSize: 32
                iconColor: Theme.error
                tooltipText: "Move to Trash (Delete)"
                tooltipSide: "left"
                onClicked: {
                    ImageService.inspectorOpen = false;
                    ImageService.moveToTrash();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
            opacity: 0.22
        }

        DFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.implicitHeight + 28
            clip: true

            ColumnLayout {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 16
                spacing: 16

                // Hero File Card
                M3Card {
                    implicitHeight: heroCol.implicitHeight + 28

                    ColumnLayout {
                        id: heroCol
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Rectangle {
                                width: 42
                                height: 42
                                radius: 10
                                color: Theme.primaryContainer

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "image"
                                    size: 22
                                    color: Theme.primaryText
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: ImageService.currentFileName || "Image"
                                    font.pixelSize: Theme.fontSizeMedium + 1
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.surfaceText
                                    elide: Text.ElideMiddle
                                    wrapMode: Text.WrapAnywhere
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: ImageService.currentMeta.fileSizeText || ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        // Badges Row
                        Flow {
                            Layout.fillWidth: true
                            spacing: 6

                            PillBadge {
                                visible: ImageService.currentMeta.format !== undefined && ImageService.currentMeta.format !== ""
                                text: ImageService.currentMeta.format || ""
                                bgColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
                                textColor: Theme.primary
                                borderColor: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.6)
                            }

                            PillBadge {
                                visible: ImageService.currentMeta.megapixels !== undefined && ImageService.currentMeta.megapixels !== ""
                                text: ImageService.currentMeta.megapixels || ""
                            }

                            PillBadge {
                                visible: ImageService.currentMeta.width > 0
                                text: ImageService.currentMeta.width + " × " + ImageService.currentMeta.height
                            }

                            PillBadge {
                                visible: ImageService.currentMeta.aspectRatio !== undefined && ImageService.currentMeta.aspectRatio !== ""
                                text: ImageService.currentMeta.aspectRatio || ""
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.outlineVariant
                            opacity: 0.2
                        }

                        // Quick Action Buttons
                        Flow {
                            Layout.fillWidth: true
                            spacing: 8

                            ActionChip {
                                iconName: "content_copy"
                                label: "Copy Image"
                                onClicked: ImageService.copyToClipboard()
                            }

                            ActionChip {
                                iconName: "link"
                                label: "Copy Path"
                                onClicked: ImageService.copyPathToClipboard()
                            }

                            ActionChip {
                                iconName: "folder_open"
                                label: "Open Folder"
                                onClicked: ImageService.openContainingFolder()
                            }

                            ActionChip {
                                iconName: "wallpaper"
                                label: "Set as Wallpaper"
                                onClicked: ImageService.setAsWallpaper()
                            }

                            ActionChip {
                                iconName: "print"
                                label: "Print"
                                onClicked: ImageService.printImage()
                            }
                        }
                    }
                }

                // Section 1 & 3: Image Attributes and Location side-by-side (2 columns)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16
                    Layout.alignment: Qt.AlignTop

                    // Column 1: Image Attributes
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 8

                        SectionHeader {
                            title: "Attributes"
                            iconName: "photo_size_select_actual"
                        }

                        M3Card {
                            Layout.fillHeight: true
                            implicitHeight: attrCol.implicitHeight + 28

                            ColumnLayout {
                                id: attrCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                DetailRow {
                                    label: "Dimensions"
                                    value: ImageService.currentMeta.width > 0 ? (ImageService.currentMeta.width + " × " + ImageService.currentMeta.height + " px") : ""
                                }
                                DetailRow {
                                    label: "Megapixels"
                                    value: ImageService.currentMeta.megapixels || ""
                                }
                                DetailRow {
                                    label: "Aspect Ratio"
                                    value: ImageService.currentMeta.aspectRatio || ""
                                }
                                DetailRow {
                                    label: "File Size"
                                    value: ImageService.currentMeta.fileSizeText || ""
                                }
                                DetailRow {
                                    label: "Format"
                                    value: ImageService.currentMeta.format || ""
                                }
                                DetailRow {
                                    label: "Modified"
                                    value: ImageService.currentMeta.modTimeText || ""
                                }
                            }
                        }
                    }

                    // Column 2: Location
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 8

                        SectionHeader {
                            title: "Location"
                            iconName: "folder"
                        }

                        M3Card {
                            Layout.fillHeight: true
                            implicitHeight: locCol.implicitHeight + 28

                            ColumnLayout {
                                id: locCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                DetailRow {
                                    label: "Folder"
                                    value: ImageService.currentMeta.directory || ""
                                    isMono: true
                                }

                                DetailRow {
                                    label: "Full Path"
                                    value: ImageService.currentFilePath
                                    isMono: true
                                }
                            }
                        }
                    }
                }

                // Section 2: Camera & Optics (EXIF)
                ColumnLayout {
                    visible: (ImageService.currentMeta.cameraModel !== undefined && ImageService.currentMeta.cameraModel !== "") ||
                             (ImageService.currentMeta.fNumber !== undefined && ImageService.currentMeta.fNumber !== "")
                    Layout.fillWidth: true
                    spacing: 8

                    SectionHeader {
                        title: "Camera & Optics"
                        iconName: "photo_camera"
                    }

                    M3Card {
                        implicitHeight: cameraCol.implicitHeight + 28

                        ColumnLayout {
                            id: cameraCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            StyledText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: (ImageService.currentMeta.cameraMake ? ImageService.currentMeta.cameraMake + " " : "") + (ImageService.currentMeta.cameraModel || "")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Theme.fontWeightBold
                                color: Theme.surfaceText
                            }

                            // 4-cell Photography Quick Spec Grid (Loupe style)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                SpecCell { label: "Aperture"; value: ImageService.currentMeta.fNumber || "—" }
                                SpecCell { label: "Shutter"; value: ImageService.currentMeta.exposureTime || "—" }
                                SpecCell { label: "Focal"; value: ImageService.currentMeta.focalLength || "—" }
                                SpecCell { label: "ISO"; value: ImageService.currentMeta.iso || "—" }
                            }

                            DetailRow {
                                label: "Date Taken"
                                value: ImageService.currentMeta.dateTaken || ""
                            }
                        }
                    }
                }

                // Section 4: GPS Coordinates (if available in EXIF)
                ColumnLayout {
                    visible: ImageService.currentMeta.gpsPosition !== undefined && ImageService.currentMeta.gpsPosition !== ""
                    Layout.fillWidth: true
                    spacing: 8

                    SectionHeader {
                        title: "GPS Location"
                        iconName: "location_on"
                    }

                    M3Card {
                        implicitHeight: gpsCol.implicitHeight + 28

                        ColumnLayout {
                            id: gpsCol
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            DetailRow {
                                label: "Coordinates"
                                value: ImageService.currentMeta.gpsPosition || ""
                                isMono: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                ActionChip {
                                    iconName: "map"
                                    label: "Open in Maps"
                                    onClicked: {
                                        if (ImageService.currentMeta.mapsUrl) {
                                            Quickshell.execDetached(["xdg-open", ImageService.currentMeta.mapsUrl]);
                                        }
                                    }
                                }

                                ActionChip {
                                    iconName: "content_copy"
                                    label: "Copy Coordinates"
                                    onClicked: {
                                        if (ImageService.currentMeta.gpsPosition) {
                                            Quickshell.execDetached([
                                                "dms", "cl", "copy", ImageService.currentMeta.gpsPosition
                                            ]);
                                            ImageService.showToast("Coordinates copied to clipboard");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
