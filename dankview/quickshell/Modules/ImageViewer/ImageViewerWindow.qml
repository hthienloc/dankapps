import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import qs.DCommon.FileBrowser
import "."
import "../Gallery"

FloatingWindow {
    id: window

    title: ImageService.galleryMode ? "Gallery — DankView" : (ImageService.currentFileName ? (ImageService.currentFileName + " — DankView") : "DankView")
    minimumSize: Qt.size(480, 360)
    implicitWidth: 1050
    implicitHeight: 720
    color: Theme.surfaceContainerLowest
    visible: true

    Item {
        id: rootContent
        anchors.fill: parent
        focus: true

        // Keyboard navigation and shortcuts
        Keys.onPressed: event => {
            switch (event.key) {
            // Navigation
            case Qt.Key_Left:
            case Qt.Key_PageUp:
            case Qt.Key_Backspace:
                ImageService.prevImage();
                event.accepted = true;
                break;
            case Qt.Key_Right:
            case Qt.Key_PageDown:
                ImageService.nextImage();
                event.accepted = true;
                break;
            case Qt.Key_Space:
                if (ImageService.isAnimated && !ImageService.galleryMode) {
                    ImageService.togglePlayback();
                } else {
                    ImageService.nextImage();
                }
                event.accepted = true;
                break;

            // Zoom & Scale
            case Qt.Key_Plus:
            case Qt.Key_Equal:
                ImageService.zoomIn();
                event.accepted = true;
                break;
            case Qt.Key_Minus:
                ImageService.zoomOut();
                event.accepted = true;
                break;
            case Qt.Key_0:
                ImageService.fitToWindow();
                event.accepted = true;
                break;
            case Qt.Key_1:
                ImageService.actualSize();
                event.accepted = true;
                break;

            // Rotation & Orientation
            case Qt.Key_R:
                if (event.modifiers & Qt.ShiftModifier) {
                    ImageService.rotateCounterClockwise();
                } else {
                    ImageService.rotateClockwise();
                }
                event.accepted = true;
                break;
            case Qt.Key_L:
                ImageService.rotateCounterClockwise();
                event.accepted = true;
                break;
            case Qt.Key_H:
            case Qt.Key_M:
                ImageService.toggleFlipHorizontal();
                event.accepted = true;
                break;
            case Qt.Key_V:
                ImageService.toggleFlipVertical();
                event.accepted = true;
                break;

            // Actions & Editing
            case Qt.Key_A:
                if (event.modifiers & Qt.ControlModifier) {
                    if (ImageService.galleryMode) {
                        ImageService.selectAll();
                        event.accepted = true;
                    }
                } else if (!ImageService.galleryMode && ImageService.currentFilePath !== "") {
                    ImageService.annotateImage();
                    event.accepted = true;
                }
                break;
            case Qt.Key_C:
                if (ImageService.galleryMode && ImageService.gallerySelectedCount > 0) {
                    ImageService.copySelectedFiles();
                } else {
                    ImageService.copyToClipboard();
                }
                event.accepted = true;
                break;
            case Qt.Key_X:
                ImageService.toggleCropMode();
                event.accepted = true;
                break;
            case Qt.Key_E:
                ImageService.toggleEditMode();
                event.accepted = true;
                break;
            case Qt.Key_S:
                saveDialog.cropRegion = null;
                ImageService.openSaveDialog();
                event.accepted = true;
                break;
            case Qt.Key_P:
                ImageService.printImage();
                event.accepted = true;
                break;
            case Qt.Key_W:
                ImageService.setAsWallpaper();
                event.accepted = true;
                break;

            // File & Trash Management
            case Qt.Key_O:
                ImageService.openFileDialog();
                event.accepted = true;
                break;
            case Qt.Key_Delete:
            case Qt.Key_D:
                if (ImageService.galleryMode && ImageService.gallerySelectedCount > 0) {
                    ImageService.trashSelected();
                } else {
                    ImageService.moveToTrash();
                }
                event.accepted = true;
                break;
            case Qt.Key_Z:
                if (event.modifiers & Qt.ControlModifier) {
                    if (event.modifiers & Qt.ShiftModifier) {
                        ImageService.redoTransform();
                    } else {
                        ImageService.undoTransform();
                    }
                } else {
                    ImageService.undoTrash();
                }
                event.accepted = true;
                break;
            case Qt.Key_Y:
                if (event.modifiers & Qt.ControlModifier) {
                    ImageService.redoTransform();
                    event.accepted = true;
                }
                break;
            case Qt.Key_U:
                ImageService.undoTrash();
                event.accepted = true;
                break;

            case Qt.Key_F:
                if (event.modifiers & Qt.ControlModifier) {
                    windowControls.tryToggleMaximize();
                } else if (!ImageService.galleryMode && ImageService.currentFilePath !== "") {
                    ImageService.toggleFavorite(ImageService.currentFilePath);
                } else {
                    windowControls.tryToggleMaximize();
                }
                event.accepted = true;
                break;
            case Qt.Key_F11:
                windowControls.tryToggleMaximize();
                event.accepted = true;
                break;
            case Qt.Key_I:
                ImageService.toggleInspector();
                event.accepted = true;
                break;
            case Qt.Key_K:
            case Qt.Key_Tab:
                ImageService.toggleLockUI();
                event.accepted = true;
                break;

            // Modal & Dialog Keys
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (ImageService.cropMode && !cropOverlay.promptVisible) {
                    cropOverlay.applyCrop();
                    event.accepted = true;
                } else if (ImageService.editMode) {
                    ImageService.editMode = false;
                    event.accepted = true;
                }
                break;
            case Qt.Key_Escape:
                if (ImageService.galleryMode && ImageService.gallerySelectedCount > 0) {
                    ImageService.clearSelection();
                    event.accepted = true;
                } else if (ImageService.uiLocked) {
                    ImageService.uiLocked = false;
                    event.accepted = true;
                } else if (cropOverlay.promptVisible) {
                    cropOverlay.promptVisible = false;
                    event.accepted = true;
                } else if (ImageService.cropMode) {
                    ImageService.cropMode = false;
                    event.accepted = true;
                } else if (ImageService.editMode) {
                    ImageService.editMode = false;
                    event.accepted = true;
                } else if (ImageService.saveMode) {
                    ImageService.saveMode = false;
                    saveDialog.cropRegion = null;
                    event.accepted = true;
                } else if (ImageService.inspectorOpen) {
                    ImageService.inspectorOpen = false;
                    event.accepted = true;
                } else if (!ImageService.galleryMode) {
                    ImageService.backToGallery();
                    event.accepted = true;
                } else if (window.maximized) {
                    windowControls.tryToggleMaximize();
                    event.accepted = true;
                } else {
                    Qt.quit();
                }
                break;
            }
        }

        // Floating Window Controls (resizing, moving, maximizing)
        FloatingWindowControls {
            id: windowControls
            targetWindow: window
        }

        // Window background card with border outline
        Rectangle {
            id: windowFrame
            anchors.fill: parent
            radius: window.maximized ? 0 : Theme.windowRadius
            color: ImageService.galleryMode ? Theme.surface : Theme.surfaceContainerLowest
            border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.4)
            border.width: window.maximized ? 0 : 1
            clip: !window.maximized

            // Top Header Bar — thin DankWindowHeader with centered title, expand & close
            Rectangle {
                id: headerBarBg
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: headerBar.implicitHeight
                color: ImageService.galleryMode ? "transparent" : Theme.withAlpha(Theme.cardSurface, 0.90)
                border.color: ImageService.galleryMode ? "transparent" : Theme.withAlpha(Theme.outlineVariant, 0.25)
                border.width: ImageService.galleryMode ? 0 : 1
                opacity: !ImageService.uiLocked ? 1.0 : 0.0
                visible: opacity > 0
                z: 40

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }

                ImageHeaderBar {
                    id: headerBar
                    windowControls: windowControls
                    anchors.fill: parent
                    onCloseRequested: Qt.quit()
                }
            }

            // Gallery View (Shown when dankview opens without an image or when returned to gallery)
            GalleryView {
                id: galleryView
                windowControls: windowControls
                targetWindow: window
                anchors.top: headerBarBg.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                visible: ImageService.galleryMode
                z: 35
            }

            // Main Image Canvas Container (Rounded Viewport with Checkerboard)
            Rectangle {
                id: canvasContainer
                anchors.top: ImageService.uiLocked ? parent.top : headerBarBg.bottom
                anchors.topMargin: ImageService.uiLocked ? 0 : 8
                anchors.left: parent.left
                anchors.leftMargin: ImageService.uiLocked ? 0 : 16
                anchors.right: parent.right
                anchors.rightMargin: ImageService.uiLocked ? 0 : 16
                anchors.bottom: parent.bottom
                anchors.bottomMargin: ImageService.uiLocked ? 0 : 16
                radius: ImageService.uiLocked || window.maximized ? 0 : 16
                color: Theme.surfaceContainerLowest
                clip: true
                visible: !ImageService.galleryMode
                border.color: ImageService.uiLocked ? "transparent" : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.2)
                border.width: ImageService.uiLocked ? 0 : 1

                ImageCanvas {
                    anchors.fill: parent
                }


                // Crop Overlay inside canvas container
                CropOverlay {
                    id: cropOverlay
                    anchors.fill: parent
                    visible: ImageService.cropMode
                    imageX: {
                        if (!visible) return 0;
                        return (parent.width - imageW) / 2 + ImageService.panX;
                    }
                    imageY: {
                        if (!visible) return 0;
                        return (parent.height - imageH) / 2 + ImageService.panY;
                    }
                    imageW: {
                        if (!visible) return 1;
                        const m = ImageService.currentMeta;
                        return m.width > 0 ? m.width * ImageService.fitScale * ImageService.zoom : 1;
                    }
                    imageH: {
                        if (!visible) return 1;
                        const m = ImageService.currentMeta;
                        return m.height > 0 ? m.height * ImageService.fitScale * ImageService.zoom : 1;
                    }
                    srcW: ImageService.currentMeta.width || 1
                    srcH: ImageService.currentMeta.height || 1

                    onCropped: (x, y, w, h) => ImageService.executeCrop(x, y, w, h)
                    onSaveCopyRequested: (x, y, w, h) => ImageService.saveCropCopy(x, y, w, h)
                    onCopyRequested: (x, y, w, h) => ImageService.copyCropToClipboard(x, y, w, h)
                    onSaveAsRequested: (x, y, w, h) => {
                        ImageService.cropMode = false;
                        saveDialog.cropRegion = { x: x, y: y, w: w, h: h };
                        saveDialog.customDestPath = "";
                        ImageService.saveMode = true;
                    }
                    onCancelled: ImageService.cropMode = false
                }
            }



            // Floating Lock Badge (shown only when UI is locked and hovered nearby)
            Item {
                id: lockBadgeArea
                anchors.top: parent.top
                anchors.right: parent.right
                width: 76
                height: 76
                z: 90
                visible: ImageService.uiLocked

                Rectangle {
                    id: floatingLockBadge
                    anchors.centerIn: parent
                    width: Style.buttonHeightS
                    height: Style.buttonHeightS
                    radius: height / 2
                    color: lockBadgeMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    opacity: lockBadgeMouse.containsMouse ? 0.95 : 0.0
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.3)
                    border.width: Style.outlineWidth

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.shortDuration
                            easing.type: Theme.standardEasing
                        }
                    }

                    DIcon {
                        anchors.centerIn: parent
                        name: "lock_open"
                        size: Style.iconSizeMedium
                        color: Theme.primary
                    }
                }

                MouseArea {
                    id: lockBadgeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        ImageService.toggleLockUI();
                    }
                }
            }

            // Edit Toolbar (Vertical Speed-Dial above FAB or Horizontal Crop Bar at bottom)
            ImageEditBar {
                id: editBar
                cropOverlay: cropOverlay
                anchors.right: ImageService.cropMode ? undefined : editFab.right
                anchors.horizontalCenter: ImageService.cropMode ? parent.horizontalCenter : undefined
                anchors.bottom: ImageService.cropMode ? parent.bottom : editFab.top
                anchors.bottomMargin: ImageService.cropMode ? Style.spacingXL : Style.spacingM
                z: 60
            }

            // Material 3 Expressive Floating Action Button (FAB)
            Rectangle {
                id: editFab
                anchors.right: parent.right
                anchors.rightMargin: 28
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                width: Style.buttonHeightM
                height: Style.buttonHeightM
                radius: fabMouse.pressed ? M3E.pressRadiusM : ((ImageService.editMode || fabMouse.containsMouse) ? height / 2 : Style.cornerRadiusL)
                z: 60

                readonly property bool shouldShow: !ImageService.galleryMode &&
                                                   !ImageService.uiLocked &&
                                                   ImageService.currentFilePath !== "" &&
                                                   !ImageService.cropMode &&
                                                   !ImageService.saveMode &&
                                                   !ImageService.inspectorOpen
                readonly property bool isDimmed: ImageService.zoom > 1.05 && !fabMouse.containsMouse && !ImageService.editMode

                visible: opacity > 0
                opacity: shouldShow ? (isDimmed ? 0.35 : 1.0) : 0.0
                scale: shouldShow ? (fabMouse.pressed ? M3E.iconBtnPressScale : (fabMouse.containsMouse ? 1.05 : 1.0)) : 0.8

                color: ImageService.editMode
                    ? Theme.surfaceContainerHighest
                    : (fabMouse.pressed
                        ? Qt.darker(Theme.primary, 1.15)
                        : (fabMouse.containsMouse ? Qt.lighter(Theme.primary, 1.08) : Theme.primary))

                border.color: ImageService.editMode
                    ? Theme.primary
                    : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                border.width: Style.outlineWidth

                Behavior on opacity { DAnim { duration: M3E.effectsMs; easing.bezierCurve: M3E.curveEffects } }
                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on radius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                DIcon {
                    anchors.centerIn: parent
                    name: ImageService.editMode ? "close" : "edit"
                    size: Style.iconSize
                    color: ImageService.editMode ? Theme.primary : (Theme.onPrimary || Theme.primaryText)

                    Behavior on rotation {
                        DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial }
                    }
                }

                StateLayer {
                    id: fabMouse
                    cornerRadius: editFab.radius
                    stateColor: ImageService.editMode ? Theme.primary : (Theme.onPrimary || Theme.primaryText)
                    tooltipText: ImageService.editMode ? "Close Edit Menu (E / Esc)" : "Edit (E)"
                    tooltipSide: "left"
                    onClicked: ImageService.toggleEditMode()
                }
            }

            // Material 3 Expressive Floating Actions Pill (Connected Button Group)
            Rectangle {
                id: floatingActionsPill
                anchors.right: editFab.left
                anchors.rightMargin: Style.spacingM
                anchors.verticalCenter: editFab.verticalCenter
                implicitHeight: Style.buttonHeightM
                implicitWidth: actionRow.implicitWidth + Style.spacingL
                radius: height / 2
                z: 60

                readonly property bool shouldShow: !ImageService.galleryMode &&
                                                   !ImageService.uiLocked &&
                                                   ImageService.currentFilePath !== "" &&
                                                   !ImageService.cropMode &&
                                                   !ImageService.saveMode &&
                                                   !ImageService.inspectorOpen
                readonly property bool isDimmed: ImageService.zoom > 1.05 && !pillHover.hovered

                visible: opacity > 0
                opacity: shouldShow ? (isDimmed ? 0.35 : 1.0) : 0.0
                scale: shouldShow ? 1.0 : 0.8
                color: Theme.withAlpha(Theme.chipSurface, 0.95)
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                border.width: Style.outlineWidth

                Behavior on opacity { DAnim { duration: M3E.effectsMs; easing.bezierCurve: M3E.curveEffects } }
                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

                HoverHandler {
                    id: pillHover
                }

                component ConnectedPillButton: DActionButton {
                    property int segIndex: 0
                    property int segCount: 2
                    property bool segActive: false
                    readonly property real pillR: height / 2
                    readonly property real leftR: M3E.leftRadius(segIndex, segCount, pillR, pressed, hovered, segActive, M3E.pressRadiusS)
                    readonly property real rightR: M3E.rightRadius(segIndex, segCount, pillR, pressed, hovered, segActive, M3E.pressRadiusS)

                    buttonSize: Style.buttonHeightS
                    iconSize: Style.iconSizeMedium
                    topLeftRadius: leftR
                    bottomLeftRadius: leftR
                    topRightRadius: rightR
                    bottomRightRadius: rightR
                    backgroundColor: segActive ? Theme.secondaryContainer : (hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                    Behavior on topLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on bottomLeftRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on topRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                    Behavior on bottomRightRadius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                }

                RowLayout {
                    id: actionRow
                    anchors.centerIn: parent
                    spacing: M3E.groupGap

                    readonly property int totalCount: ImageService.isAnimated ? 3 : 2

                    ConnectedPillButton {
                        visible: ImageService.isAnimated
                        segIndex: 0
                        segCount: actionRow.totalCount
                        segActive: !ImageService.isPlaying
                        iconName: ImageService.isPlaying ? "pause" : "play_arrow"
                        iconColor: !ImageService.isPlaying ? Theme.primary : Theme.surfaceText
                        tooltipText: ImageService.isPlaying ? "Pause GIF (Space)" : "Play GIF (Space)"
                        tooltipSide: "top"
                        onClicked: ImageService.togglePlayback()
                    }

                    ConnectedPillButton {
                        readonly property bool isFav: ImageService.isFavorite(ImageService.currentFilePath)
                        segIndex: ImageService.isAnimated ? 1 : 0
                        segCount: actionRow.totalCount
                        segActive: isFav
                        iconName: isFav ? "favorite" : "favorite_border"
                        iconFilled: isFav
                        iconColor: isFav ? Theme.error : Theme.surfaceText
                        backgroundColor: isFav ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) : (hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                        tooltipText: isFav ? "Remove from Favorites (F)" : "Add to Favorites (F)"
                        tooltipSide: "top"
                        onClicked: ImageService.toggleFavorite(ImageService.currentFilePath)
                    }

                    ConnectedPillButton {
                        segIndex: ImageService.isAnimated ? 2 : 1
                        segCount: actionRow.totalCount
                        segActive: ImageService.inspectorOpen
                        iconName: "info"
                        iconFilled: ImageService.inspectorOpen
                        iconColor: ImageService.inspectorOpen ? Theme.primary : Theme.surfaceText
                        tooltipText: "Image Info / EXIF (I)"
                        tooltipSide: "top"
                        onClicked: ImageService.toggleInspector()
                    }
                }
            }

            // Material 3 Expressive Floating Zoom Action Button (M3 Extended FAB)
            Rectangle {
                id: zoomFab
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                implicitWidth: zoomContentRow.implicitWidth + Style.spacingXL
                implicitHeight: Style.buttonHeightM
                radius: zoomMouse.pressed ? M3E.pressRadiusM : (zoomMouse.containsMouse ? height / 2 : Style.cornerRadiusL)
                z: 60

                readonly property bool shouldShow: !ImageService.galleryMode &&
                                                   !ImageService.uiLocked &&
                                                   ImageService.currentFilePath !== "" &&
                                                   !ImageService.cropMode &&
                                                   !ImageService.saveMode &&
                                                   !ImageService.inspectorOpen
                readonly property bool isDimmed: ImageService.zoom > 1.05 && !zoomMouse.containsMouse

                visible: opacity > 0
                opacity: shouldShow ? (isDimmed ? 0.35 : 1.0) : 0.0
                scale: shouldShow ? (zoomMouse.pressed ? M3E.iconBtnPressScale : (zoomMouse.containsMouse ? 1.05 : 1.0)) : 0.8

                color: zoomMouse.pressed
                    ? Qt.darker(Theme.chipSurface, 1.15)
                    : (zoomMouse.containsMouse ? Qt.lighter(Theme.chipSurface, 1.08) : Theme.withAlpha(Theme.chipSurface, 0.95))

                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                border.width: Style.outlineWidth

                Behavior on opacity { DAnim { duration: M3E.effectsMs; easing.bezierCurve: M3E.curveEffects } }
                Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on radius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
                Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                RowLayout {
                    id: zoomContentRow
                    anchors.centerIn: parent
                    spacing: Style.spacingS

                    DIcon {
                        name: "zoom_in"
                        size: Style.iconSizeMedium
                        color: Theme.surfaceText
                    }

                    StyledText {
                        text: Math.round(ImageService.zoom * 100) + "%"
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceText
                    }
                }

                StateLayer {
                    id: zoomMouse
                    cornerRadius: zoomFab.radius
                    stateColor: Theme.surfaceText
                    tooltipText: "Scroll to zoom • Click to reset"
                    tooltipSide: "top"
                    onClicked: ImageService.resetZoom()
                    onWheel: wheel => {
                        if (wheel.angleDelta.y > 0)
                            ImageService.zoomIn();
                        else if (wheel.angleDelta.y < 0)
                            ImageService.zoomOut();
                    }
                }
            }

            // Dismiss inspector when clicking outside it
            MouseArea {
                anchors.fill: parent
                enabled: ImageService.inspectorOpen
                visible: enabled
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: ImageService.inspectorOpen = false
                z: 92
            }

            // Slide-up EXIF Inspector Bottom Sheet
            ExifInspector {
                id: inspector
                anchors.bottom: parent.bottom
                anchors.bottomMargin: ImageService.inspectorOpen ? 16 : -height - 30
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(760, parent.width - 32)
                height: Math.min(480, Math.max(380, parent.height * 0.60))
                visible: anchors.bottomMargin > -height || ImageService.inspectorOpen
                z: 95

                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: Theme.shortDuration
                        easing.type: Theme.standardEasing
                    }
                }
            }

            // Save As / Export Dialog
            SaveDialog {
                id: saveDialog
                anchors.fill: parent
                visible: ImageService.saveMode
                z: 100
                onCancelled: {
                    ImageService.saveMode = false;
                    saveDialog.cropRegion = null;
                }
                onSaved: {
                    ImageService.saveMode = false;
                    saveDialog.cropRegion = null;
                }
            }
        }
    }

    FileBrowserModal {
        id: openImageModal
        browserTitle: "Open Image"
        browserIcon: "image"
        parentModal: window
        fileExtensions: [
            "*.jpg", "*.jpeg", "*.png", "*.webp", "*.svg", "*.gif",
            "*.bmp", "*.avif", "*.heic", "*.heif", "*.jxl", "*.tif",
            "*.tiff", "*.exr", "*.hdr", "*.tga", "*.qoi", "*.psd", "*.dds"
        ]
        revealPath: ImageService.currentFilePath || ""
        onFileSelected: path => {
            ImageService.loadDirectoryFor(path);
            close();
        }
    }

    FileBrowserModal {
        id: addFolderModal
        folderMode: true
        browserTitle: "Add Album Folder"
        browserIcon: "create_new_folder"
        parentModal: window
        onFileSelected: path => {
            ImageService.addAlbumFolder(path);
            close();
        }
    }

    Connections {
        target: ImageService
        function onOpenFileDialogRequested() {
            openImageModal.revealPath = ImageService.currentFilePath || "";
            openImageModal.open();
        }
        function onOpenAddFolderDialogRequested() {
            addFolderModal.open();
        }
    }
}
