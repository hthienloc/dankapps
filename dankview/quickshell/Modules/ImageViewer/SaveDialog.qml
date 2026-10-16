import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Widgets

// Modal "Save As / Export" sheet.
// Emits saved(destPath) on success, cancelled() on dismiss.
Rectangle {
    id: root

    signal saved(string destPath)
    signal cancelled()

    // Input path to convert from (may be a cropped temp file)
    property string sourcePath: ImageService.currentFilePath

    // Optional crop region { x: int, y: int, w: int, h: int }
    property var cropRegion: null

    // Optional user-selected destination path (via Browse...)
    property string customDestPath: ""

    color: Qt.rgba(0, 0, 0, 0.55)

    // Block input to canvas behind
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: root.cancelled()
    }

    // Sheet card
    Rectangle {
        anchors.centerIn: parent
        width: 420
        radius: 16
        color: Theme.surfaceContainerHigh
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
        border.width: 1
        implicitHeight: sheetCol.implicitHeight + 32

        // Swallow clicks so they don't close the dialog
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {}
        }

        ColumnLayout {
            id: sheetCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 14

            // Header
            RowLayout {
                Layout.fillWidth: true

                DIcon { name: root.cropRegion ? "crop" : "save"; size: 20; color: Theme.primary }

                StyledText {
                    Layout.fillWidth: true
                    leftPadding: 8
                    text: root.cropRegion ? "Save Cropped Image" : "Save As / Export"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }

                DActionButton {
                    iconName: "close"; iconSize: 18; buttonSize: 32
                    iconColor: Theme.surfaceText
                    onClicked: root.cancelled()
                }
            }

            // Destination row
            StyledText {
                text: "Destination"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: 8
                color: Theme.surfaceContainerLow
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 8

                    StyledText {
                        Layout.fillWidth: true
                        text: root.getDisplayDestPath()
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        elide: Text.ElideMiddle
                    }

                    DActionButton {
                        iconName: "folder_open"
                        iconSize: 18
                        buttonSize: 28
                        iconColor: Theme.primary
                        tooltipText: "Browse Destination..."
                        tooltipSide: "top"
                        onClicked: root.openBrowseDialog()
                    }
                }
            }

            // Format selector
            StyledText {
                text: "Format"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: ["PNG", "JPEG", "WebP"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: 8
                        color: formatSelector.currentFormat === modelData
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
                            : (fmtMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                        border.color: formatSelector.currentFormat === modelData
                            ? Theme.primary
                            : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
                        border.width: 1

                        StyledText {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: formatSelector.currentFormat === modelData ? Theme.primary : Theme.surfaceText
                        }

                        MouseArea {
                            id: fmtMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: formatSelector.currentFormat = modelData
                        }
                    }
                }

                // Invisible singleton to hold selection state
                Item { id: formatSelector; property string currentFormat: "PNG" }
            }

            // Quality slider (lossy only)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: formatSelector.currentFormat !== "PNG"

                RowLayout {
                    Layout.fillWidth: true
                    StyledText {
                        text: "Quality"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                    Item { Layout.fillWidth: true }
                    StyledText {
                        text: qualitySlider.value + "%"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceText
                    }
                }

                DSlider {
                    id: qualitySlider
                    Layout.fillWidth: true
                    height: 36
                    minimum: 10
                    maximum: 100
                    step: 1
                    value: 90
                    unit: "%"
                }
            }

            // Metadata strip toggle
            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    Layout.fillWidth: true
                    text: "Strip metadata"
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                }

                Rectangle {
                    id: stripToggle
                    property bool checked: false
                    width: 40; height: 24; radius: 12
                    color: checked ? Theme.primary : Theme.surfaceContainerHighest
                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }

                    Rectangle {
                        width: 18; height: 18; radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        x: stripToggle.checked ? parent.width - width - 3 : 3
                        color: "white"
                        Behavior on x { NumberAnimation { duration: Theme.shortDuration } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: stripToggle.checked = !stripToggle.checked
                    }
                }
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item { Layout.fillWidth: true }

                // Cancel
                Rectangle {
                    implicitWidth: 80; implicitHeight: 36; radius: 18
                    color: cancelMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.4)
                    border.width: 1
                    StyledText {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightMedium
                        color: Theme.surfaceText
                    }
                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelled()
                    }
                }

                // Save
                Rectangle {
                    implicitWidth: 90; implicitHeight: 36; radius: 18
                    color: saveMouse.containsMouse
                        ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.85)
                        : Theme.primary
                    StyledText {
                        anchors.centerIn: parent
                        text: "Save"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Theme.fontWeightBold
                        color: Theme.primaryText
                    }
                    MouseArea {
                        id: saveMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._doSave()
                    }
                }
            }

            // Spacer at bottom
            Item { implicitHeight: 4 }
        }
    }

    function _extFor(fmt) {
        if (fmt === "JPEG") return "jpg";
        if (fmt === "WebP") return "webp";
        return "png";
    }

    function getDefaultDestPath() {
        const src = root.sourcePath;
        if (!src) return "";
        const ext = _extFor(formatSelector.currentFormat);
        const lastDot = src.lastIndexOf(".");
        const base = lastDot > 0 ? src.substring(0, lastDot) : src;
        const suffix = root.cropRegion ? "_crop" : "_export";
        return base + suffix + "." + ext;
    }

    function getDisplayDestPath() {
        const ext = _extFor(formatSelector.currentFormat);
        if (customDestPath && customDestPath.length > 0) {
            const lastDot = customDestPath.lastIndexOf(".");
            if (lastDot > 0) {
                return customDestPath.substring(0, lastDot) + "." + ext;
            }
            return customDestPath + "." + ext;
        }
        return getDefaultDestPath();
    }

    function openBrowseDialog() {
        const defaultName = root.getDisplayDestPath();
        browseProc.command = [
            "sh", "-c",
            'zenity --file-selection --save --confirm-overwrite --title="Save As" --filename="$1" 2>/dev/null || kdialog --getsavefilename "$1" 2>/dev/null',
            "browseProc",
            defaultName
        ];
        browseProc.running = true;
    }

    Process {
        id: browseProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const picked = text.trim();
                if (picked.length > 0) {
                    root.customDestPath = picked;
                }
            }
        }
    }

    function _doSave() {
        const src = root.sourcePath;
        if (!src) return;

        let dest = root.getDisplayDestPath();
        if (!dest) return;

        const quality = formatSelector.currentFormat === "PNG" ? "" : String(Math.round(qualitySlider.value));

        root.saved(dest);

        let cmd = ["magick", src];
        if (root.cropRegion && root.cropRegion.w > 0 && root.cropRegion.h > 0) {
            cmd.push("-crop", root.cropRegion.w + "x" + root.cropRegion.h + "+" + root.cropRegion.x + "+" + root.cropRegion.y);
            cmd.push("+repage");
        }
        if (quality !== "") {
            cmd.push("-quality", quality);
        }
        if (stripToggle.checked) {
            cmd.push("-strip");
        }
        cmd.push(dest);
        saveProc.targetDest = dest;
        saveProc.command = cmd;
        saveProc.running = true;
    }

    Process {
        id: saveProc
        property string targetDest: ""
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                const fileName = targetDest.split("/").pop();
                ImageService.showToast("Saved to " + fileName);
                ImageService.loadDirectoryFor(targetDest);
            } else {
                ImageService.showToast("Save failed", true);
            }
        }
    }
}
