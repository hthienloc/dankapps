import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets
import qs.DCommon.FileBrowser
import "."

FloatingWindow {
    id: window

    title: VideoService.currentFileName ? (VideoService.currentFileName + " — DankVideo") : "DankVideo"
    minimumSize: Qt.size(480, 360)
    implicitWidth: 1050
    implicitHeight: 700
    color: Theme.surfaceContainerLowest
    visible: true

    property bool showOverlays: true

    Timer {
        id: hideOverlaysTimer
        interval: 1500
        repeat: false
        onTriggered: {
            if (!headerHover.hovered && !bottomHover.hovered && !pillHover.hovered && !VideoService.inspectorOpen && VideoService.isPlaying) {
                window.showOverlays = false;
            }
        }
    }

    Item {
        id: rootContent
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            switch (event.key) {
            // Playback & Seeking
            case Qt.Key_Space:
                VideoService.togglePlay();
                event.accepted = true;
                break;
            case Qt.Key_Left:
                VideoService.seekRelative(event.modifiers & Qt.ShiftModifier ? -30000 : -10000);
                event.accepted = true;
                break;
            case Qt.Key_Right:
                VideoService.seekRelative(event.modifiers & Qt.ShiftModifier ? 30000 : 10000);
                event.accepted = true;
                break;
            case Qt.Key_Up:
                VideoService.setVolume(VideoService.volume + 0.05);
                event.accepted = true;
                break;
            case Qt.Key_Down:
                VideoService.setVolume(VideoService.volume - 0.05);
                event.accepted = true;
                break;
            case Qt.Key_M:
                VideoService.toggleMute();
                event.accepted = true;
                break;

            // Navigation
            case Qt.Key_PageUp:
            case Qt.Key_Backspace:
                VideoService.prevVideo();
                event.accepted = true;
                break;
            case Qt.Key_PageDown:
                VideoService.nextVideo();
                event.accepted = true;
                break;

            // File & Clipboard Actions
            case Qt.Key_O:
                VideoService.openFileDialog();
                event.accepted = true;
                break;
            case Qt.Key_C:
                VideoService.copyPathToClipboard();
                event.accepted = true;
                break;
            case Qt.Key_Delete:
            case Qt.Key_D:
                VideoService.moveToTrash();
                event.accepted = true;
                break;
            case Qt.Key_Z:
            case Qt.Key_U:
                VideoService.undoTrash();
                event.accepted = true;
                break;

            // Window & View Controls
            case Qt.Key_F:
            case Qt.Key_F11:
                windowControls.tryToggleMaximize();
                event.accepted = true;
                break;
            case Qt.Key_I:
                VideoService.toggleInspector();
                event.accepted = true;
                break;
            case Qt.Key_K:
            case Qt.Key_Tab:
                VideoService.toggleLockUI();
                event.accepted = true;
                break;

            // Modal & Window Dismiss
            case Qt.Key_Escape:
                if (VideoService.uiLocked) {
                    VideoService.uiLocked = false;
                    window.showOverlays = true;
                    hideOverlaysTimer.restart();
                    event.accepted = true;
                } else if (VideoService.inspectorOpen) {
                    VideoService.inspectorOpen = false;
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

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: {
                if (!VideoService.uiLocked) {
                    window.showOverlays = true;
                    hideOverlaysTimer.restart();
                }
            }
        }

        FloatingWindowControls {
            id: windowControls
            targetWindow: window
        }

        // Window background card with border outline
        Rectangle {
            id: windowFrame
            anchors.fill: parent
            radius: window.maximized ? 0 : Theme.windowRadius
            color: Theme.surfaceContainerLowest
            border.color: Theme.withAlpha(Theme.outlineVariant, 0.4)
            border.width: window.maximized ? 0 : 1
            clip: !window.maximized

            // Main Video Canvas
            VideoCanvas {
                anchors.fill: parent
            }

            // Dismiss inspector when clicking outside it
            MouseArea {
                anchors.fill: parent
                enabled: VideoService.inspectorOpen
                visible: enabled
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: VideoService.inspectorOpen = false
            }

            // Top Header Bar
            VideoHeaderBar {
                id: headerBar
                windowControls: windowControls
                targetWindow: window
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                opacity: !VideoService.uiLocked && (window.showOverlays || VideoService.inspectorOpen) ? 1.0 : 0.0
                visible: opacity > 0
                z: 40

                HoverHandler {
                    id: headerHover
                }

                Behavior on opacity {
                    DAnim {
                        duration: Style.shortDuration
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
                }
            }

            // Floating Quick Actions Pill (Top-Right)
            FloatingActionsPill {
                id: floatingPill
                anchors.top: headerBar.bottom
                anchors.topMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 16
                opacity: !VideoService.uiLocked && window.showOverlays && VideoService.currentFilePath !== "" && !VideoService.inspectorOpen ? 1.0 : 0.0
                visible: opacity > 0
                z: 40

                HoverHandler {
                    id: pillHover
                }

                Behavior on opacity {
                    DAnim {
                        duration: Style.shortDuration
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
                }
            }

            // Bottom Tool Bar
            VideoBottomBar {
                id: bottomBar
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: !VideoService.uiLocked && window.showOverlays && VideoService.currentFilePath !== "" && !VideoService.inspectorOpen ? 1.0 : 0.0
                visible: opacity > 0
                z: 40

                HoverHandler {
                    id: bottomHover
                }

                Behavior on opacity {
                    DAnim {
                        duration: Style.shortDuration
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
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
                visible: VideoService.uiLocked

                Rectangle {
                    id: floatingLockBadge
                    anchors.centerIn: parent
                    width: 40
                    height: 40
                    radius: 20
                    color: lockBadgeMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh
                    opacity: lockBadgeMouse.containsMouse ? 0.95 : 0.0
                    border.color: Theme.withAlpha(Theme.outlineVariant, 0.3)
                    border.width: 1

                    Behavior on opacity {
                        DAnim {
                            duration: Style.shortDuration
                            easing.bezierCurve: Style.expressiveCurves.standard
                        }
                    }

                    DIcon {
                        anchors.centerIn: parent
                        name: "lock_open"
                        size: 20
                        color: Theme.primary
                    }
                }

                MouseArea {
                    id: lockBadgeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        VideoService.toggleLockUI();
                        window.showOverlays = true;
                        hideOverlaysTimer.restart();
                    }
                }
            }

            // Media Inspector Drawer
            MediaInspector {
                id: inspector
                anchors.top: headerBar.bottom
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.rightMargin: VideoService.inspectorOpen ? 0 : -width
                visible: anchors.rightMargin > -width || VideoService.inspectorOpen
                z: 50

                Behavior on anchors.rightMargin {
                    DAnim {
                        duration: Style.shortDuration
                        easing.bezierCurve: Style.expressiveCurves.standard
                    }
                }
            }
        }
    }

    FileBrowserModal {
        id: openVideoModal
        browserTitle: "Open Video"
        browserIcon: "video_library"
        parentModal: window
        fileExtensions: [
            "*.mp4", "*.mkv", "*.webm", "*.mov", "*.avi",
            "*.flv", "*.wmv", "*.ogg", "*.m4v", "*.ts", "*.m2ts"
        ]
        revealPath: VideoService.currentFilePath || ""
        onFileSelected: path => {
            VideoService.loadDirectoryFor(path);
            close();
        }
    }

    Connections {
        target: VideoService
        function onOpenFileDialogRequested() {
            openVideoModal.revealPath = VideoService.currentFilePath || "";
            openVideoModal.open();
        }
    }
}
