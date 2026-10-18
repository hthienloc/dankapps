import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

// Crop overlay drawn over the image viewport.
// Caller must provide imageX/imageY/imageW/imageH — the screen-space rect of the
// displayed image (after zoom/pan), so we can map crop coords to image pixels.
Item {
    id: root

    signal cropped(int x, int y, int w, int h)
    signal saveCopyRequested(int x, int y, int w, int h)
    signal saveAsRequested(int x, int y, int w, int h)
    signal copyRequested(int x, int y, int w, int h)
    signal cancelled()

    property bool promptVisible: false
    property var pendingCrop: null

    onVisibleChanged: {
        if (visible) {
            aspectRatio = "";
            _reset();
        } else {
            promptVisible = false;
            pendingCrop = null;
            aspectRatio = "";
        }
    }

    property real imageX: 0
    property real imageY: 0
    property real imageW: 1
    property real imageH: 1
    property int  srcW: 1
    property int  srcH: 1

    // Aspect ratio lock: "" = freeform
    property string aspectRatio: ""

    // Crop rect in screen space, clamped to image bounds
    property real cropX: imageX + imageW * 0.1
    property real cropY: imageY + imageH * 0.1
    property real cropW: imageW * 0.8
    property real cropH: imageH * 0.8

    readonly property int handleSize: 14

    // Reset crop rect whenever the image position/size changes
    onImageXChanged: _reset()
    onImageYChanged: _reset()
    onImageWChanged: _reset()
    onImageHChanged: _reset()

    function _reset() {
        cropX = imageX + imageW * 0.1;
        cropY = imageY + imageH * 0.1;
        cropW = imageW * 0.8;
        cropH = imageH * 0.8;
        if (aspectRatio !== "") {
            _applyAspect();
        }
    }

    function _clamp() {
        // Clamp size when resizing: keep within image bounds, preserve min size
        if (cropX < imageX) { cropW -= (imageX - cropX); cropX = imageX; }
        if (cropY < imageY) { cropH -= (imageY - cropY); cropY = imageY; }
        if (cropX + cropW > imageX + imageW) cropW = imageX + imageW - cropX;
        if (cropY + cropH > imageY + imageH) cropH = imageY + imageH - cropY;
        cropW = Math.max(20, cropW);
        cropH = Math.max(20, cropH);
    }

    // Clamp position only (used when moving): preserves rect size
    function _clampMove() {
        cropX = Math.max(imageX, Math.min(cropX, imageX + imageW - cropW));
        cropY = Math.max(imageY, Math.min(cropY, imageY + imageH - cropH));
    }

    function _applyAspect() {
        if (aspectRatio === "") return;
        const parts = aspectRatio.split(":");
        const ar = parseFloat(parts[0]) / parseFloat(parts[1]);
        if (!ar || ar <= 0) return;

        const centerX = cropX + cropW / 2;
        const centerY = cropY + cropH / 2;

        let w = cropW;
        let h = w / ar;
        if (h > imageH) {
            h = imageH;
            w = h * ar;
        }
        if (w > imageW) {
            w = imageW;
            h = w / ar;
        }

        cropW = Math.max(20, w);
        cropH = Math.max(20, h);
        cropX = centerX - cropW / 2;
        cropY = centerY - cropH / 2;
        _clampMove();
    }

    function resizeFromCorner(corner, mouseX, mouseY, origX, origY, origW, origH, offX, offY) {
        let anchorX = 0;
        let anchorY = 0;
        let sx = 1;
        let sy = 1;

        if (corner === "nw") {
            anchorX = origX + origW;
            anchorY = origY + origH;
            sx = -1;
            sy = -1;
        } else if (corner === "ne") {
            anchorX = origX;
            anchorY = origY + origH;
            sx = 1;
            sy = -1;
        } else if (corner === "sw") {
            anchorX = origX + origW;
            anchorY = origY;
            sx = -1;
            sy = 1;
        } else if (corner === "se") {
            anchorX = origX;
            anchorY = origY;
            sx = 1;
            sy = 1;
        }

        let targetX = mouseX - offX;
        let targetY = mouseY - offY;

        targetX = Math.max(imageX, Math.min(targetX, imageX + imageW));
        targetY = Math.max(imageY, Math.min(targetY, imageY + imageH));

        let rawW = sx * (targetX - anchorX);
        let rawH = sy * (targetY - anchorY);

        const minSize = 20;

        const maxW = sx < 0 ? (anchorX - imageX) : (imageX + imageW - anchorX);
        const maxH = sy < 0 ? (anchorY - imageY) : (imageY + imageH - anchorY);

        let w = Math.max(minSize, Math.min(rawW, maxW));
        let h = Math.max(minSize, Math.min(rawH, maxH));

        if (aspectRatio !== "") {
            const parts = aspectRatio.split(":");
            const ar = parseFloat(parts[0]) / parseFloat(parts[1]);
            if (ar > 0) {
                if (w / h > ar) {
                    h = w / ar;
                } else {
                    w = h * ar;
                }

                if (w > maxW) {
                    w = maxW;
                    h = w / ar;
                }
                if (h > maxH) {
                    h = maxH;
                    w = h * ar;
                }

                w = Math.max(minSize, w);
                h = Math.max(minSize / ar, h);
            }
        }

        cropX = sx < 0 ? (anchorX - w) : anchorX;
        cropY = sy < 0 ? (anchorY - h) : anchorY;
        cropW = w;
        cropH = h;
    }

    function resizeFromEdge(edge, mouseX, mouseY, origX, origY, origW, origH, offX, offY) {
        const minSize = 20;

        if (edge === "n") {
            const anchorY = origY + origH;
            let targetY = mouseY - offY;
            targetY = Math.max(imageY, Math.min(targetY, anchorY - minSize));
            let newH = anchorY - targetY;
            let newW = origW;
            let newX = origX;

            if (aspectRatio !== "") {
                const parts = aspectRatio.split(":");
                const ar = parseFloat(parts[0]) / parseFloat(parts[1]);
                if (ar > 0) {
                    newW = newH * ar;
                    if (newW > imageW) {
                        newW = imageW;
                        newH = newW / ar;
                        targetY = anchorY - newH;
                    }
                    const centerX = origX + origW / 2;
                    newX = Math.max(imageX, Math.min(centerX - newW / 2, imageX + imageW - newW));
                }
            }

            cropX = newX;
            cropY = targetY;
            cropW = newW;
            cropH = newH;
        } else if (edge === "s") {
            const anchorY = origY;
            let targetY = mouseY - offY;
            targetY = Math.min(imageY + imageH, Math.max(targetY, anchorY + minSize));
            let newH = targetY - anchorY;
            let newW = origW;
            let newX = origX;

            if (aspectRatio !== "") {
                const parts = aspectRatio.split(":");
                const ar = parseFloat(parts[0]) / parseFloat(parts[1]);
                if (ar > 0) {
                    newW = newH * ar;
                    if (newW > imageW) {
                        newW = imageW;
                        newH = newW / ar;
                    }
                    const centerX = origX + origW / 2;
                    newX = Math.max(imageX, Math.min(centerX - newW / 2, imageX + imageW - newW));
                }
            }

            cropX = newX;
            cropY = origY;
            cropW = newW;
            cropH = newH;
        } else if (edge === "w") {
            const anchorX = origX + origW;
            let targetX = mouseX - offX;
            targetX = Math.max(imageX, Math.min(targetX, anchorX - minSize));
            let newW = anchorX - targetX;
            let newH = origH;
            let newY = origY;

            if (aspectRatio !== "") {
                const parts = aspectRatio.split(":");
                const ar = parseFloat(parts[0]) / parseFloat(parts[1]);
                if (ar > 0) {
                    newH = newW / ar;
                    if (newH > imageH) {
                        newH = imageH;
                        newW = newH * ar;
                        targetX = anchorX - newW;
                    }
                    const centerY = origY + origH / 2;
                    newY = Math.max(imageY, Math.min(centerY - newH / 2, imageY + imageH - newH));
                }
            }

            cropX = targetX;
            cropY = newY;
            cropW = newW;
            cropH = newH;
        } else if (edge === "e") {
            const anchorX = origX;
            let targetX = mouseX - offX;
            targetX = Math.min(imageX + imageW, Math.max(targetX, anchorX + minSize));
            let newW = targetX - anchorX;
            let newH = origH;
            let newY = origY;

            if (aspectRatio !== "") {
                const parts = aspectRatio.split(":");
                const ar = parseFloat(parts[0]) / parseFloat(parts[1]);
                if (ar > 0) {
                    newH = newW / ar;
                    if (newH > imageH) {
                        newH = imageH;
                        newW = newH * ar;
                    }
                    const centerY = origY + origH / 2;
                    newY = Math.max(imageY, Math.min(centerY - newH / 2, imageY + imageH - newH));
                }
            }

            cropX = origX;
            cropY = newY;
            cropW = newW;
            cropH = newH;
        }
    }

    function applyCrop() {
        const scaleX = srcW / imageW;
        const scaleY = srcH / imageH;
        const px = Math.round((cropX - imageX) * scaleX);
        const py = Math.round((cropY - imageY) * scaleY);
        const pw = Math.round(cropW * scaleX);
        const ph = Math.round(cropH * scaleY);
        pendingCrop = {
            x: Math.max(0, px),
            y: Math.max(0, py),
            w: Math.min(pw, srcW - px),
            h: Math.min(ph, srcH - py)
        };
        promptVisible = true;
    }

    // Dark scrim outside the crop rect (4 rectangles)
    Rectangle { // top
        x: 0; y: 0; width: parent.width; height: cropY
        color: Qt.rgba(0, 0, 0, M3E.scrimOverlay)
    }
    Rectangle { // bottom
        x: 0; y: cropY + cropH; width: parent.width
        height: parent.height - (cropY + cropH)
        color: Qt.rgba(0, 0, 0, M3E.scrimOverlay)
    }
    Rectangle { // left
        x: 0; y: cropY; width: cropX; height: cropH
        color: Qt.rgba(0, 0, 0, M3E.scrimOverlay)
    }
    Rectangle { // right
        x: cropX + cropW; y: cropY
        width: parent.width - (cropX + cropW); height: cropH
        color: Qt.rgba(0, 0, 0, M3E.scrimOverlay)
    }

    // Crop rect border
    Rectangle {
        x: cropX; y: cropY; width: cropW; height: cropH
        color: "transparent"
        border.color: "white"
        border.width: 1.5

        // Rule-of-thirds grid lines
        Repeater {
            model: 2
            delegate: Rectangle {
                x: parent.width * (index + 1) / 3; y: 0
                width: 1; height: parent.height
                color: Qt.rgba(1, 1, 1, 0.35)
            }
        }
        Repeater {
            model: 2
            delegate: Rectangle {
                x: 0; y: parent.height * (index + 1) / 3
                width: parent.width; height: 1
                color: Qt.rgba(1, 1, 1, 0.35)
            }
        }
    }

    // Move crop rect by dragging its center
    MouseArea {
        x: cropX + handleSize; y: cropY + handleSize
        width: cropW - handleSize * 2; height: cropH - handleSize * 2
        cursorShape: Qt.SizeAllCursor
        property real startX: 0; property real startY: 0
        property real origCropX: 0; property real origCropY: 0
        onPressed: mouse => {
            const p = mapToItem(root, mouse.x, mouse.y);
            startX = p.x; startY = p.y;
            origCropX = cropX; origCropY = cropY;
        }
        onPositionChanged: mouse => {
            const p = mapToItem(root, mouse.x, mouse.y);
            cropX = origCropX + (p.x - startX);
            cropY = origCropY + (p.y - startY);
            root._clampMove();
        }
    }

    // Corner handle component
    component CornerHandle: Rectangle {
        id: ch
        property string corner: "nw"
        property int cursorShape: Qt.SizeFDiagCursor
        width: handleSize * 2; height: handleSize * 2
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: handleSize; height: handleSize
            radius: 3
            color: "white"
            border.color: Qt.rgba(0, 0, 0, 0.4)
            border.width: 1
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: ch.cursorShape
            property real offX: 0; property real offY: 0
            property real origX: 0; property real origY: 0
            property real origW: 0; property real origH: 0
            onPressed: mouse => {
                const p = mapToItem(root, mouse.x, mouse.y);
                origX = cropX; origY = cropY; origW = cropW; origH = cropH;
                const anchorX = (ch.corner === "ne" || ch.corner === "se") ? (origX + origW) : origX;
                const anchorY = (ch.corner === "sw" || ch.corner === "se") ? (origY + origH) : origY;
                offX = p.x - anchorX;
                offY = p.y - anchorY;
            }
            onPositionChanged: mouse => {
                const p = mapToItem(root, mouse.x, mouse.y);
                root.resizeFromCorner(ch.corner, p.x, p.y, origX, origY, origW, origH, offX, offY);
            }
        }
    }

    CornerHandle { corner: "nw"; cursorShape: Qt.SizeFDiagCursor; x: cropX - handleSize; y: cropY - handleSize }
    CornerHandle { corner: "ne"; cursorShape: Qt.SizeBDiagCursor; x: cropX + cropW - handleSize; y: cropY - handleSize }
    CornerHandle { corner: "sw"; cursorShape: Qt.SizeBDiagCursor; x: cropX - handleSize; y: cropY + cropH - handleSize }
    CornerHandle { corner: "se"; cursorShape: Qt.SizeFDiagCursor; x: cropX + cropW - handleSize; y: cropY + cropH - handleSize }

    // Edge handle component
    component EdgeHandle: Rectangle {
        id: eh
        property string edge: "n"
        property bool isVertical: edge === "n" || edge === "s"
        width: isVertical ? 40 : 12
        height: isVertical ? 12 : 40
        color: "transparent"

        Rectangle {
            anchors.centerIn: parent
            width: eh.isVertical ? 24 : 5
            height: eh.isVertical ? 5 : 24
            radius: 2.5
            color: "white"
            border.color: Qt.rgba(0, 0, 0, 0.45)
            border.width: 1
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: eh.isVertical ? Qt.SizeVerCursor : Qt.SizeHorCursor
            property real offX: 0; property real offY: 0
            property real origX: 0; property real origY: 0
            property real origW: 0; property real origH: 0
            onPressed: mouse => {
                const p = mapToItem(root, mouse.x, mouse.y);
                origX = cropX; origY = cropY; origW = cropW; origH = cropH;
                offX = eh.edge === "e" ? p.x - (origX + origW) : (eh.edge === "w" ? p.x - origX : 0);
                offY = eh.edge === "s" ? p.y - (origY + origH) : (eh.edge === "n" ? p.y - origY : 0);
            }
            onPositionChanged: mouse => {
                const p = mapToItem(root, mouse.x, mouse.y);
                root.resizeFromEdge(eh.edge, p.x, p.y, origX, origY, origW, origH, offX, offY);
            }
        }
    }

    EdgeHandle { edge: "n"; x: cropX + cropW / 2 - 20; y: cropY - 6 }
    EdgeHandle { edge: "s"; x: cropX + cropW / 2 - 20; y: cropY + cropH - 6 }
    EdgeHandle { edge: "w"; x: cropX - 6; y: cropY + cropH / 2 - 20 }
    EdgeHandle { edge: "e"; x: cropX + cropW - 6; y: cropY + cropH / 2 - 20 }

    // Live dimension badge floating near the crop rect
    Rectangle {
        id: dimBadge
        x: Math.max(8, Math.min(parent.width - width - 8, cropX + cropW / 2 - width / 2))
        y: cropY - height - 10 >= 10 ? (cropY - height - 10) : (cropY + 10)
        implicitWidth: dimText.implicitWidth + 16
        implicitHeight: 24
        radius: 12
        color: Qt.rgba(0, 0, 0, 0.75)
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1
        z: 20

        StyledText {
            id: dimText
            anchors.centerIn: parent
            text: {
                const scaleX = srcW / imageW;
                const scaleY = srcH / imageH;
                const w = Math.round(cropW * scaleX);
                const h = Math.round(cropH * scaleY);
                return w + " × " + h + " px" + (aspectRatio !== "" ? (" • " + aspectRatio) : "");
            }
            font.pixelSize: Theme.fontSizeSmall - 1
            font.weight: Theme.fontWeightBold
            color: "white"
        }
    }


    // Action modal dialog centered on screen
    Item {
        id: doneMenuContainer
        visible: root.promptVisible
        anchors.fill: parent
        z: 100

        // Scrim backdrop (click outside to dismiss)
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.promptVisible = false
            }
        }

        Rectangle {
            id: doneMenuCard
            anchors.centerIn: parent
            width: 300
            height: doneMenuCol.implicitHeight + 24
            radius: 16
            color: Theme.surfaceContainerHigh
            border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeCard)
            border.width: 1

            // Swallow clicks inside the card
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: {}
            }

            ColumnLayout {
                id: doneMenuCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 6

                component ActionRow: Rectangle {
                    id: actionItem
                    property string iconName: ""
                    property string label: ""
                    property bool isRecommended: false
                    signal actionTriggered()

                    Layout.fillWidth: true
                    implicitHeight: 40
                    radius: 8
                    color: itemMouse.containsMouse
                        ? Theme.surfaceContainerHighest
                        : (isRecommended ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        DIcon {
                            name: actionItem.iconName
                            size: 20
                            color: actionItem.isRecommended ? Theme.primary : Theme.surfaceText
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: actionItem.label
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: actionItem.isRecommended ? Theme.fontWeightBold : Theme.fontWeightMedium
                            color: Theme.surfaceText
                        }

                        Rectangle {
                            visible: actionItem.isRecommended
                            implicitHeight: 18
                            implicitWidth: recText.implicitWidth + 8
                            radius: 4
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.25)
                            StyledText {
                                id: recText
                                anchors.centerIn: parent
                                text: "Rec"
                                font.pixelSize: Theme.fontSizeSmall - 3
                                font.weight: Theme.fontWeightBold
                                color: Theme.primary
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.promptVisible = false;
                            if (root.pendingCrop) {
                                actionItem.actionTriggered();
                            }
                        }
                    }
                }

                ActionRow {
                    iconName: "copy_all"
                    label: "Save Copy (_crop)"
                    isRecommended: true
                    onActionTriggered: root.saveCopyRequested(root.pendingCrop.x, root.pendingCrop.y, root.pendingCrop.w, root.pendingCrop.h)
                }

                ActionRow {
                    iconName: "content_copy"
                    label: "Copy to Clipboard"
                    onActionTriggered: root.copyRequested(root.pendingCrop.x, root.pendingCrop.y, root.pendingCrop.w, root.pendingCrop.h)
                }

                ActionRow {
                    iconName: "folder_open"
                    label: "Save As..."
                    onActionTriggered: root.saveAsRequested(root.pendingCrop.x, root.pendingCrop.y, root.pendingCrop.w, root.pendingCrop.h)
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.outlineVariant
                    opacity: 0.25
                }

                ActionRow {
                    iconName: "save"
                    label: "Overwrite Original"
                    onActionTriggered: root.cropped(root.pendingCrop.x, root.pendingCrop.y, root.pendingCrop.w, root.pendingCrop.h)
                }

                // Cancel button
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 8
                    color: promptCancelMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                    StyledText {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceVariantText
                    }

                    MouseArea {
                        id: promptCancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.promptVisible = false
                    }
                }
            }
        }
    }
}
