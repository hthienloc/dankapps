import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var cropOverlay: null

    readonly property var aspectModel: [
        { label: "Free", ar: "" },
        { label: "1:1",  ar: "1:1" },
        { label: "4:3",  ar: "4:3" },
        { label: "16:9", ar: "16:9" },
        { label: "3:2",  ar: "3:2" }
    ]
    readonly property int aspectIndex: {
        if (!cropOverlay) return 0
        const ar = cropOverlay.aspectRatio ?? ""
        for (let i = 0; i < aspectModel.length; i++) if (aspectModel[i].ar === ar) return i
        return 0
    }

    implicitWidth: ImageService.cropMode ? cropBar.implicitWidth : verticalSpeedDial.implicitWidth
    implicitHeight: ImageService.cropMode ? cropBar.implicitHeight : verticalSpeedDial.implicitHeight

    // ── 1. Editing Floating Grid Panel (Anchored right above Edit FAB) ──────────
    Rectangle {
        id: verticalSpeedDial
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        implicitWidth: editColumn.implicitWidth + Style.spacingM * 2
        implicitHeight: editColumn.implicitHeight + Style.spacingM * 2
        radius: Style.cornerRadiusXL
        color: Style.withAlpha(Style.surfaceContainerHigh, 0.95)
        border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.30)
        border.width: Style.outlineWidth
        clip: true
        visible: opacity > 0
        opacity: ImageService.editMode && !ImageService.cropMode ? 1.0 : 0.0
        scale: opacity > 0 ? 1.0 : 0.8
        transformOrigin: Item.BottomRight

        Behavior on opacity {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }
        Behavior on scale {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }

        ElevationShadow {
            anchors.fill: parent
            z: -1
            targetRadius: parent.radius
            targetColor: parent.color
            level: Style.elevationLevel2
        }

        ColumnLayout {
            id: editColumn
            anchors.centerIn: parent
            spacing: Style.spacingS

            // Group 1: Rotation Pair (Left & Right)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: rotateRow.implicitWidth + 8
                implicitHeight: 46
                radius: 12
                color: Style.surfaceContainerHighest
                border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.25)
                border.width: 1

                RowLayout {
                    id: rotateRow
                    anchors.centerIn: parent
                    spacing: 4

                    DActionButton {
                        iconName: "rotate_left"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: "Rotate Counter-Clockwise (L / Shift+R)"
                        tooltipSide: "left"
                        onClicked: ImageService.rotateCounterClockwise()
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 22
                        color: Style.outlineVariant
                        opacity: 0.35
                    }

                    DActionButton {
                        iconName: "rotate_right"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: "Rotate Clockwise (R)"
                        tooltipSide: "right"
                        onClicked: ImageService.rotateClockwise()
                    }
                }
            }

            // Group 2: Flip Pair (Horizontal & Vertical)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: flipRow.implicitWidth + 8
                implicitHeight: 46
                radius: 12
                color: Style.surfaceContainerHighest
                border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.25)
                border.width: 1

                RowLayout {
                    id: flipRow
                    anchors.centerIn: parent
                    spacing: 4

                    DActionButton {
                        iconName: "flip"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: "Flip Horizontally (H / M)"
                        tooltipSide: "left"
                        onClicked: ImageService.toggleFlipHorizontal()
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 22
                        color: Style.outlineVariant
                        opacity: 0.35
                    }

                    DActionButton {
                        iconName: "flip"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: "Flip Vertically (V)"
                        tooltipSide: "right"
                        transform: Rotation { angle: 90; origin.x: 19; origin.y: 19 }
                        onClicked: ImageService.toggleFlipVertical()
                    }
                }
            }

            // Group 3: Creative Tools (Crop & Annotate)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: toolRow.implicitWidth + 8
                implicitHeight: 46
                radius: 12
                color: Style.surfaceContainerHighest
                border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.25)
                border.width: 1

                RowLayout {
                    id: toolRow
                    anchors.centerIn: parent
                    spacing: 4

                    DActionButton {
                        iconName: "crop"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: "Crop Image (X)"
                        tooltipSide: "left"
                        backgroundColor: ImageService.cropMode ? Style.primaryContainer : "transparent"
                        iconColor: ImageService.cropMode ? Style.primary : Style.onSurfaceVariant
                        stateColor: Style.primary
                        onClicked: ImageService.toggleCropMode()
                    }

                    Rectangle {
                        implicitWidth: 1
                        implicitHeight: 22
                        color: Style.outlineVariant
                        opacity: 0.35
                    }

                    DActionButton {
                        iconName: "draw"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: "Annotate in Quick Capture (A)"
                        tooltipSide: "right"
                        onClicked: ImageService.annotateImage()
                    }
                }
            }

            // Optional Group 4: Animation Play/Pause (if animated GIF/APNG)
            Rectangle {
                visible: ImageService.isAnimated
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: animRow.implicitWidth + 8
                implicitHeight: 46
                radius: 12
                color: Style.surfaceContainerHighest
                border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.25)
                border.width: 1

                RowLayout {
                    id: animRow
                    anchors.centerIn: parent

                    DActionButton {
                        iconName: ImageService.isPlaying ? "pause" : "play_arrow"
                        iconSize: Style.iconSizeMedium
                        buttonSize: 38
                        tooltipText: ImageService.isPlaying ? "Pause Animation (Space)" : "Play Animation (Space)"
                        tooltipSide: "left"
                        onClicked: ImageService.togglePlayback()
                    }
                }
            }
        }
    }

    // ── 2. Horizontal Crop Bar (Only in crop mode at bottom center) ──────────────
    Rectangle {
        id: cropBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        implicitHeight: 46
        implicitWidth: cropRow.implicitWidth + Style.spacingM * 2
        radius: Style.fullRadius(height, height)
        color: Style.withAlpha(Style.surfaceContainerHigh, 0.95)
        border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.30)
        border.width: Style.outlineWidth
        clip: true
        visible: opacity > 0
        opacity: ImageService.cropMode ? 1.0 : 0.0
        scale: opacity > 0 ? 1.0 : 0.92

        Behavior on opacity {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }
        Behavior on scale {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }

        ElevationShadow {
            anchors.fill: parent
            z: -1
            targetRadius: parent.radius
            targetColor: parent.color
            level: Style.elevationLevel2
        }

        component BarSeparator: Rectangle {
            implicitWidth: Style.dividerWidth
            implicitHeight: 20
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: Style.spacingXS / 2
            Layout.rightMargin: Style.spacingXS / 2
            color: Style.outlineVariant
            opacity: 0.35
        }

    // Crop controls — same pill background
    RowLayout {
        id: cropRow
        anchors.centerIn: parent
        spacing: Style.spacingXS
        opacity: ImageService.cropMode ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            DAnim {
                duration: Style.shortDuration
                easing.bezierCurve: Style.expressiveCurves.standard
            }
        }

        DButtonGroup {
            id: aspectGroup
            model: root.aspectModel.map(m => m.label)
            currentIndex: root.aspectIndex
            size: "small"
            onSelectionChanged: (index, selected) => {
                if (!selected || !root.cropOverlay) return
                root.cropOverlay.aspectRatio = root.aspectModel[index].ar
                root.cropOverlay._applyAspect()
            }
        }

        BarSeparator {}

        DActionButton {
            iconName: "restart_alt"
            iconSize: Style.iconSizeMedium
            buttonSize: 34
            tooltipText: "Reset Crop Selection"
            tooltipSide: "top"
            onClicked: {
                if (root.cropOverlay) {
                    root.cropOverlay.aspectRatio = ""
                    root.cropOverlay.cropX = root.cropOverlay.imageX
                    root.cropOverlay.cropY = root.cropOverlay.imageY
                    root.cropOverlay.cropW = root.cropOverlay.imageW
                    root.cropOverlay.cropH = root.cropOverlay.imageH
                }
            }
        }

        BarSeparator {}

        DButton {
            text: "Cancel"
            iconName: "close"
            buttonHeight: Style.buttonHeightXS
            backgroundColor: Style.surfaceContainerHighest
            textColor: Style.onSurfaceVariant
            tooltipText: "Cancel Crop (Esc)"
            tooltipSide: "top"
            onClicked: {
                if (root.cropOverlay)
                    root.cropOverlay.cancelled()
            }
        }

        DButton {
            text: "Done"
            iconName: "check"
            buttonHeight: Style.buttonHeightXS
            backgroundColor: Style.primary
            textColor: Style.onPrimary
            tooltipText: "Apply Crop (Enter)"
            tooltipSide: "top"
            onClicked: {
                if (root.cropOverlay)
                    root.cropOverlay.applyCrop()
            }
        }
    }
}
}

