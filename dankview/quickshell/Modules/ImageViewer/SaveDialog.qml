import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import qs.DCommon.FileBrowser
import qs.DCommon.Common as DC

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
        radius: Style.cornerRadiusL
        color: Theme.surfaceContainerHigh
        border.color: M3E.stroke(Theme.outlineVariant, M3E.strokePopup)
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
            anchors.margins: Style.spacingL
            spacing: Style.spacingM

            // Header
            RowLayout {
                Layout.fillWidth: true

                DIcon { name: root.cropRegion ? "crop" : "save"; size: Style.iconSizeMedium; color: Theme.primary }

                StyledText {
                    Layout.fillWidth: true
                    leftPadding: Style.spacingS
                    text: root.cropRegion ? "Save Cropped Image" : "Save As / Export"
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                }

                DActionButton {
                    iconName: "close"; iconSize: Style.chipIconSize; buttonSize: Style.buttonHeightXS
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
                implicitHeight: Style.buttonHeightS
                radius: Style.cornerRadiusS
                color: Theme.surfaceContainerLow
                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Style.spacingM
                    anchors.rightMargin: Style.spacingXS
                    spacing: Style.spacingS

                    StyledText {
                        Layout.fillWidth: true
                        text: root.getDisplayDestPath()
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        elide: Text.ElideMiddle
                    }

                    DActionButton {
                        iconName: "folder_open"
                        iconSize: Style.chipIconSize
                        buttonSize: Style.buttonHeightXXS
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
                spacing: Style.spacingS

                Repeater {
                    model: ["PNG", "JPEG", "WebP"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Style.buttonHeightXS
                        radius: Style.cornerRadiusS
                        color: formatSelector.currentFormat === modelData
                            ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.22)
                            : (fmtMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                        border.color: formatSelector.currentFormat === modelData
                            ? Theme.primary
                            : M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
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
                spacing: Style.spacingXS
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
                    height: Style.buttonHeightXS
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

                DToggle {
                    id: stripToggle
                    checked: false
                    onToggled: (val) => checked = val
                }
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: Style.spacingS

                Item { Layout.fillWidth: true }

                DButton {
                    text: "Cancel"
                    buttonHeight: Style.buttonHeightXS
                    backgroundColor: Theme.surfaceContainerLow
                    textColor: Theme.surfaceText
                    onClicked: root.cancelled()
                }

                DButton {
                    text: "Save"
                    buttonHeight: Style.buttonHeightXS
                    backgroundColor: Theme.primary
                    textColor: Theme.onPrimary
                    onClicked: root._doSave()
                }
            }

            // Spacer at bottom
            Item { implicitHeight: Style.spacingXS }
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

    FileBrowserModal {
        id: saveFileBrowserModal
        saveMode: true
        browserTitle: "Save As"
        browserIcon: "save"
        defaultFileName: {
            const dest = root.getDisplayDestPath();
            const parts = dest.split("/");
            return parts[parts.length - 1];
        }
        revealPath: {
            const dest = root.getDisplayDestPath();
            const idx = dest.lastIndexOf("/");
            return idx > 0 ? dest.substring(0, idx) : "";
        }
        onFileSelected: path => {
            root.customDestPath = path;
            close();
        }
    }

    function openBrowseDialog() {
        saveFileBrowserModal.open();
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
