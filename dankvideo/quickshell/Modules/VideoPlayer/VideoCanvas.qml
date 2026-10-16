import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Item {
    id: root

    clip: true

    readonly property string source: VideoService.currentFilePath ? "file://" + VideoService.currentFilePath : ""
    readonly property bool hasVideo: VideoService.currentFilePath !== ""

    DropArea {
        anchors.fill: parent
        onDropped: drop => {
            if (drop.hasUrls && drop.urls.length > 0) {
                let urlStr = drop.urls[0].toString();
                if (urlStr.startsWith("file://")) {
                    urlStr = decodeURIComponent(urlStr.substring(7));
                }
                if (urlStr) {
                    VideoService.loadDirectoryFor(urlStr);
                    drop.acceptProposedAction();
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceContainerLowest
    }

    MediaPlayer {
        id: player
        videoOutput: videoOutput
        source: root.source
        audioOutput: AudioOutput {
            volume: VideoService.volume
            muted: VideoService.isMuted
        }
        playbackRate: VideoService.playbackRate

        onErrorOccurred: (error, errorString) => {
            console.error("MediaPlayer error:", error, errorString);
            VideoService.showToast("Media error: " + errorString, true);
        }

        onPositionChanged: {
            if (!scrubbing) {
                VideoService.position = position;
            }
        }

        onDurationChanged: {
            VideoService.duration = duration;
        }

        onPlaybackStateChanged: {
            VideoService.isPlaying = (playbackState === MediaPlayer.PlayingState);
        }

        Component.onCompleted: {
            if (root.hasVideo) {
                player.play();
            }
        }
    }

    property bool scrubbing: false

    Connections {
        target: VideoService
        function onIsPlayingChanged() {
            if (VideoService.isPlaying && player.playbackState !== MediaPlayer.PlayingState) {
                player.play();
            } else if (!VideoService.isPlaying && player.playbackState === MediaPlayer.PlayingState) {
                player.pause();
            }
        }
        function onPositionChanged() {
            if (Math.abs(player.position - VideoService.position) > 1000) {
                player.setPosition(VideoService.position);
            }
        }
        function onCurrentFilePathChanged() {
            if (root.hasVideo) {
                player.play();
            }
        }
    }

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        visible: root.hasVideo
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        visible: root.hasVideo
        onClicked: {
            VideoService.togglePlay();
        }
        onDoubleClicked: {
            if (targetWindow) {
                windowControls.tryToggleMaximize();
            }
        }
    }

    // Empty State Browser View
    Item {
        id: emptyState
        anchors.fill: parent
        visible: !root.hasVideo

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 88
                height: 88
                radius: 44
                color: Theme.surfaceContainerHigh
                border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
                border.width: 1

                DIcon {
                    anchors.centerIn: parent
                    name: "video_library"
                    size: 44
                    color: Theme.primary
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Video Open"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Drag and drop a video here, or browse files"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: openBtnRow.implicitWidth + 36
                implicitHeight: 46
                radius: 23
                color: openBtnMouse.containsMouse
                    ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.85)
                    : Theme.primary

                RowLayout {
                    id: openBtnRow
                    anchors.centerIn: parent
                    spacing: 8

                    DIcon {
                        name: "folder_open"
                        size: 20
                        color: Theme.primaryText
                    }

                    Text {
                        text: "Open Video (O)"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.DemiBold
                        color: Theme.primaryText
                    }
                }

                MouseArea {
                    id: openBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: VideoService.openFileDialog()
                }
            }
        }
    }

    // Previous / Next overlay edge buttons
    MouseArea {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 80
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        visible: !VideoService.uiLocked && root.hasVideo && VideoService.fileList.length > 1
        onClicked: VideoService.prevVideo()

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: 22
            color: parent.containsMouse ? Theme.surfaceContainerHigh : "transparent"
            opacity: parent.containsMouse ? 0.9 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            DIcon {
                anchors.centerIn: parent
                name: "chevron_left"
                size: 28
                color: Theme.surfaceText
            }
        }
    }

    MouseArea {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 80
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        visible: !VideoService.uiLocked && root.hasVideo && VideoService.fileList.length > 1 && !VideoService.inspectorOpen
        onClicked: VideoService.nextVideo()

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: 22
            color: parent.containsMouse ? Theme.surfaceContainerHigh : "transparent"
            opacity: parent.containsMouse ? 0.9 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }

            DIcon {
                anchors.centerIn: parent
                name: "chevron_right"
                size: 28
                color: Theme.surfaceText
            }
        }
    }
}
