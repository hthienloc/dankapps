import QtQuick
import QtQuick.Layouts
import QtMultimedia
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
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
                border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeControl)
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

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Video Open"
                    font.pixelSize: Theme.fontSizeXLarge
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Drag and drop a video here, or browse files"
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                }
            }

            DButton {
                Layout.alignment: Qt.AlignHCenter
                text: "Open Video (O)"
                iconName: "folder_open"
                onClicked: VideoService.openFileDialog()
            }
        }
    }
}
