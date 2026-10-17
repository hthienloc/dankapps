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
                duration: M3E.effectsMs
                easing.bezierCurve: M3E.curveEffects
            }
        }
        Behavior on scale {
            DAnim {
                duration: M3E.spatialFastMs
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }

        ElevationShadow {
            anchors.fill: parent
            z: -1
            targetRadius: parent.radius
            targetColor: parent.color
            level: Style.elevationLevel2
        }

        component ConnectedEditBtn: DActionButton {
            property int segIndex: 0
            property int segCount: 2
            property bool segActive: false
            readonly property real pillR: height / 2
            readonly property real leftR: M3E.leftRadius(segIndex, segCount, pillR, pressed, hovered, segActive, M3E.pressRadiusS)
            readonly property real rightR: M3E.rightRadius(segIndex, segCount, pillR, pressed, hovered, segActive, M3E.pressRadiusS)

            buttonSize: 40
            iconSize: Style.iconSizeMedium
            topLeftRadius: leftR
            bottomLeftRadius: leftR
            topRightRadius: rightR
            bottomRightRadius: rightR
            backgroundColor: segActive ? Style.primaryContainer : (hovered ? Style.surfaceContainerHighest : Style.surfaceContainer)
            iconColor: segActive ? Style.primary : Style.onSurfaceVariant

            Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
            Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
            Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
            Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
        }

        ColumnLayout {
            id: editColumn
            anchors.centerIn: parent
            spacing: Style.spacingXS

            // Group 1: Rotation Pair (Left & Right)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: M3E.groupGap

                ConnectedEditBtn {
                    segIndex: 0
                    segCount: 2
                    iconName: "rotate_left"
                    tooltipText: "Rotate Counter-Clockwise (L / Shift+R)"
                    tooltipSide: "left"
                    onClicked: ImageService.rotateCounterClockwise()
                }

                ConnectedEditBtn {
                    segIndex: 1
                    segCount: 2
                    iconName: "rotate_right"
                    tooltipText: "Rotate Clockwise (R)"
                    tooltipSide: "right"
                    onClicked: ImageService.rotateClockwise()
                }
            }

            // Group 2: Flip Pair (Horizontal & Vertical)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: M3E.groupGap

                ConnectedEditBtn {
                    segIndex: 0
                    segCount: 2
                    iconName: "flip"
                    tooltipText: "Flip Horizontally (H / M)"
                    tooltipSide: "left"
                    onClicked: ImageService.toggleFlipHorizontal()
                }

                ConnectedEditBtn {
                    segIndex: 1
                    segCount: 2
                    iconName: "flip"
                    tooltipText: "Flip Vertically (V)"
                    tooltipSide: "right"
                    transform: Rotation { angle: 90; origin.x: 20; origin.y: 20 }
                    onClicked: ImageService.toggleFlipVertical()
                }
            }

            // Group 3: Creative Tools (Crop & Annotate)
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: M3E.groupGap

                ConnectedEditBtn {
                    segIndex: 0
                    segCount: 2
                    segActive: ImageService.cropMode
                    iconName: "crop"
                    tooltipText: "Crop Image (X)"
                    tooltipSide: "left"
                    stateColor: Style.primary
                    onClicked: ImageService.toggleCropMode()
                }

                ConnectedEditBtn {
                    segIndex: 1
                    segCount: 2
                    iconName: "draw"
                    tooltipText: "Annotate in Quick Capture (A)"
                    tooltipSide: "right"
                    onClicked: ImageService.annotateImage()
                }
            }

            // Optional Group 4: Animation Play/Pause (if animated GIF/APNG)
            RowLayout {
                visible: ImageService.isAnimated
                Layout.alignment: Qt.AlignHCenter

                ConnectedEditBtn {
                    segIndex: 0
                    segCount: 1
                    segActive: !ImageService.isPlaying
                    iconName: ImageService.isPlaying ? "pause" : "play_arrow"
                    tooltipText: ImageService.isPlaying ? "Pause Animation (Space)" : "Play Animation (Space)"
                    tooltipSide: "left"
                    onClicked: ImageService.togglePlayback()
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

