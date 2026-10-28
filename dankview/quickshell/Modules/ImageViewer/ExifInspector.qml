import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    width: 760
    readonly property real contentHeight: headerRow.implicitHeight + Theme.spacingL + contentCol.implicitHeight + Theme.spacingL * 2
    implicitHeight: Math.min(540, contentHeight)

    radius: Theme.cornerRadiusXL
    color: Theme.withAlpha(Theme.surfaceContainerLow, 0.96)
    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
    border.width: Style.layerOutlineWidth

    component M3Card: Rectangle {
        Layout.fillWidth: true
        radius: Theme.cornerRadiusL
        color: Theme.surfaceContainerHigh
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeDivider)
        border.width: 1
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
            font.weight: Theme.fontWeightMedium
            color: Theme.primary
        }
    }

    component InfoRow: RowLayout {
        id: infoRowRoot
        property string iconName: ""
        property string label: ""
        property string value: ""
        property bool isMono: false
        property bool clickable: false
        signal clicked()
        visible: value !== ""

        Layout.fillWidth: true
        spacing: Theme.spacingM

        DIcon {
            name: iconName
            size: Style.chipIconSize
            color: Theme.primary
            visible: iconName !== ""
        }

        StyledText {
            Layout.preferredWidth: 80
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
            font.weight: Font.Normal
            color: infoRowHover.hovered && clickable ? Theme.primary : Theme.surfaceText
            elide: Text.ElideMiddle

            Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
        }

        HoverHandler {
            id: infoRowHover
            cursorShape: infoRowRoot.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            enabled: infoRowRoot.clickable
            onTapped: infoRowRoot.clicked()
        }
    }

    component PillBadge: Rectangle {
        property alias text: badgeText.text
        property color textColor: Theme.surfaceText
        property color bgColor: Theme.surfaceContainerHighest
        property color borderColor: "transparent"

        implicitHeight: Style.iconSize
        implicitWidth: badgeText.implicitWidth + Style.spacingM
        radius: Style.fullRadius(width, height)
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
        implicitHeight: 52
        radius: Theme.cornerRadiusM
        color: Theme.surfaceContainer
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeFaint)
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
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightBold
                color: Theme.primary
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
            id: headerRow
            Layout.fillWidth: true
            Layout.topMargin: Theme.spacingL
            Layout.bottomMargin: Theme.spacingS
            Layout.leftMargin: Theme.spacingL
            Layout.rightMargin: Theme.spacingL
            spacing: Theme.spacingM

            Rectangle {
                width: 38
                height: 38
                radius: Theme.cornerRadiusS
                color: Theme.primaryContainer

                DIcon {
                    anchors.centerIn: parent
                    name: "info"
                    size: 20
                    color: Theme.onPrimaryContainer
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: "Image Details"
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Theme.fontWeightMedium
                color: Theme.surfaceText
            }

            DActionButton {
                iconName: "delete"
                iconSize: Style.chipIconSize
                buttonSize: Style.buttonHeightXS
                iconColor: Theme.error
                tooltipText: "Move to Trash (Delete)"
                tooltipSide: "left"
                onClicked: {
                    ImageService.inspectorOpen = false;
                    ImageService.moveToTrash();
                }
            }
        }

        DFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentCol.implicitHeight + Theme.spacingL * 2
            clip: true

            ColumnLayout {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                // Hero File Card
                M3Card {
                    implicitHeight: heroCol.implicitHeight + Theme.spacingL * 2

                    ColumnLayout {
                        id: heroCol
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingM

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacingM

                            Rectangle {
                                width: 44
                                height: 44
                                radius: Theme.cornerRadiusM
                                color: Theme.primaryContainer

                                DIcon {
                                    anchors.centerIn: parent
                                    name: "image"
                                    size: 24
                                    color: Theme.onPrimaryContainer
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                StyledText {
                                    Layout.fillWidth: true
                                    text: ImageService.currentFileName || "Image"
                                    font.pixelSize: Theme.fontSizeLarge
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
                            spacing: Theme.spacingXS

                            PillBadge {
                                visible: ImageService.currentMeta.format !== undefined && ImageService.currentMeta.format !== ""
                                text: ImageService.currentMeta.format || ""
                                bgColor: Theme.secondaryContainer
                                textColor: Theme.onSecondaryContainer
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
                                visible: {
                                    const r = ImageService.currentMeta.aspectRatio;
                                    if (!r || r === "") return false;
                                    return ["16:9", "4:3", "3:2", "1:1", "21:9", "9:16", "3:4", "2:3"].indexOf(r) !== -1;
                                }
                                text: ImageService.currentMeta.aspectRatio || ""
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.outlineVariant
                            opacity: 0.15
                        }

                        // Quick Action Buttons
                        Flow {
                            Layout.fillWidth: true
                            spacing: Theme.spacingS

                            DButton {
                                iconName: "content_copy"
                                text: "Copy Image"
                                shape: "round"
                                buttonHeight: Style.buttonHeightXS
                                backgroundColor: Theme.surfaceContainer
                                textColor: Theme.surfaceText
                                onClicked: ImageService.copyToClipboard()
                            }

                            DButton {
                                iconName: "link"
                                text: "Copy Path"
                                shape: "round"
                                buttonHeight: Style.buttonHeightXS
                                backgroundColor: Theme.surfaceContainer
                                textColor: Theme.surfaceText
                                onClicked: ImageService.copyPathToClipboard()
                            }

                            DButton {
                                iconName: "folder_open"
                                text: "Open Folder"
                                shape: "round"
                                buttonHeight: Style.buttonHeightXS
                                backgroundColor: Theme.surfaceContainer
                                textColor: Theme.surfaceText
                                onClicked: ImageService.openContainingFolder()
                            }

                            DButton {
                                iconName: "wallpaper"
                                text: "Set as Wallpaper"
                                shape: "round"
                                buttonHeight: Style.buttonHeightXS
                                backgroundColor: Theme.surfaceContainer
                                textColor: Theme.surfaceText
                                onClicked: ImageService.setAsWallpaper()
                            }

                            DButton {
                                iconName: "print"
                                text: "Print"
                                shape: "round"
                                buttonHeight: Style.buttonHeightXS
                                backgroundColor: Theme.surfaceContainer
                                textColor: Theme.surfaceText
                                onClicked: ImageService.printImage()
                            }
                        }
                    }
                }

                // File Location & Timestamp Card
                M3Card {
                    visible: (ImageService.currentMeta.directory !== undefined && ImageService.currentMeta.directory !== "") ||
                             (ImageService.currentMeta.modTimeText !== undefined && ImageService.currentMeta.modTimeText !== "")
                    implicitHeight: locCol.implicitHeight + Theme.spacingL * 2

                    ColumnLayout {
                        id: locCol
                        anchors.fill: parent
                        anchors.margins: Theme.spacingL
                        spacing: Theme.spacingM

                        InfoRow {
                            iconName: "folder"
                            label: "Folder"
                            value: ImageService.currentMeta.directory || ""
                            isMono: true
                            clickable: true
                            onClicked: ImageService.openContainingFolder()
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.outlineVariant
                            opacity: 0.12
                            visible: ImageService.currentMeta.modTimeText !== undefined && ImageService.currentMeta.modTimeText !== ""
                        }

                        InfoRow {
                            iconName: "schedule"
                            label: "Modified"
                            value: ImageService.currentMeta.modTimeText || ""
                        }
                    }
                }

                // Section: Camera & Optics (EXIF)
                ColumnLayout {
                    visible: (ImageService.currentMeta.cameraModel !== undefined && ImageService.currentMeta.cameraModel !== "") ||
                             (ImageService.currentMeta.fNumber !== undefined && ImageService.currentMeta.fNumber !== "")
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    SectionHeader {
                        title: "Camera & Optics"
                        iconName: "photo_camera"
                    }

                    M3Card {
                        implicitHeight: cameraCol.implicitHeight + Theme.spacingL * 2

                        ColumnLayout {
                            id: cameraCol
                            anchors.fill: parent
                            anchors.margins: Theme.spacingL
                            spacing: Theme.spacingM

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
                                spacing: Theme.spacingS

                                SpecCell { label: "Aperture"; value: ImageService.currentMeta.fNumber || "—" }
                                SpecCell { label: "Shutter"; value: ImageService.currentMeta.exposureTime || "—" }
                                SpecCell { label: "Focal"; value: ImageService.currentMeta.focalLength || "—" }
                                SpecCell { label: "ISO"; value: ImageService.currentMeta.iso || "—" }
                            }

                            InfoRow {
                                iconName: "event"
                                label: "Date Taken"
                                value: ImageService.currentMeta.dateTaken || ""
                            }
                        }
                    }
                }

                // Section: GPS Coordinates (if available in EXIF)
                ColumnLayout {
                    visible: ImageService.currentMeta.gpsPosition !== undefined && ImageService.currentMeta.gpsPosition !== ""
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    SectionHeader {
                        title: "GPS Location"
                        iconName: "location_on"
                    }

                    M3Card {
                        implicitHeight: gpsCol.implicitHeight + Theme.spacingL * 2

                        ColumnLayout {
                            id: gpsCol
                            anchors.fill: parent
                            anchors.margins: Theme.spacingL
                            spacing: Theme.spacingM

                            InfoRow {
                                iconName: "pin_drop"
                                label: "Coordinates"
                                value: ImageService.currentMeta.gpsPosition || ""
                                isMono: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacingS

                                DButton {
                                    iconName: "map"
                                    text: "Open in Maps"
                                    shape: "round"
                                    buttonHeight: Style.buttonHeightXS
                                    backgroundColor: Theme.surfaceContainer
                                    textColor: Theme.surfaceText
                                    onClicked: {
                                        if (ImageService.currentMeta.mapsUrl) {
                                            Quickshell.execDetached(["xdg-open", ImageService.currentMeta.mapsUrl]);
                                        }
                                    }
                                }

                                DButton {
                                    iconName: "content_copy"
                                    text: "Copy Coordinates"
                                    shape: "round"
                                    buttonHeight: Style.buttonHeightXS
                                    backgroundColor: Theme.surfaceContainer
                                    textColor: Theme.surfaceText
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
