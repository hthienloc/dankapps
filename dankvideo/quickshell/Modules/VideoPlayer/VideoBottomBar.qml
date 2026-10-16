import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets

Rectangle {
    id: root

    height: 90
    width: Math.min(840, parent.width - 48)
    radius: 24
    color: Qt.rgba(Theme.surfaceContainerHigh.r, Theme.surfaceContainerHigh.g, Theme.surfaceContainerHigh.b, 0.94)
    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.35)
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 14
        anchors.bottomMargin: 12
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        // Scrubber / Seek Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: VideoService.formatTime(VideoService.position)
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceText
            }

            Item {
                id: trackArea
                Layout.fillWidth: true
                height: 20

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: seekMouse.containsMouse ? 6 : 4
                    radius: 3
                    color: Theme.surfaceContainerHighest

                    Behavior on height { NumberAnimation { duration: 100 } }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: VideoService.duration > 0 ? parent.width * Math.max(0, Math.min(1, VideoService.position / VideoService.duration)) : 0
                        radius: 3
                        color: Theme.primary
                    }
                }

                // Handle thumb
                Rectangle {
                    x: (VideoService.duration > 0 ? (trackArea.width - width) * (VideoService.position / VideoService.duration) : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: Theme.primary
                    visible: seekMouse.containsMouse || seekMouse.drag.active
                }

                MouseArea {
                    id: seekMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateSeek(mouse) {
                        if (trackArea.width > 0 && VideoService.duration > 0) {
                            const ratio = Math.max(0, Math.min(1, mouse.x / trackArea.width));
                            VideoService.position = ratio * VideoService.duration;
                        }
                    }

                    onPressed: mouse => updateSeek(mouse)
                    onPositionChanged: mouse => {
                        if (pressed) {
                            updateSeek(mouse);
                        }
                    }
                }
            }

            Text {
                text: VideoService.formatTime(VideoService.duration)
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }

        // Control Buttons
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            // Volume group
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                DActionButton {
                    iconName: VideoService.isMuted || VideoService.volume === 0 ? "volume_off" : (VideoService.volume < 0.5 ? "volume_down" : "volume_up")
                    iconSize: 20
                    iconColor: Theme.surfaceText
                    buttonSize: 36
                    tooltipText: VideoService.isMuted ? "Unmute (M)" : "Mute (M)"
                    tooltipSide: "top"
                    onClicked: VideoService.toggleMute()
                }

                // Volume slider track
                Item {
                    Layout.preferredWidth: 72
                    height: 20
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 4
                        radius: 2
                        color: Theme.surfaceContainerHighest

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (VideoService.isMuted ? 0 : VideoService.volume)
                            radius: 2
                            color: Theme.primary
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => {
                            VideoService.setVolume(mouse.x / width);
                        }
                        onPositionChanged: mouse => {
                            if (pressed) {
                                VideoService.setVolume(mouse.x / width);
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Playback cluster (tight)
            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                // Step Back 10s
                DActionButton {
                    iconName: "replay_10"
                    iconSize: 20
                    iconColor: Theme.surfaceText
                    buttonSize: 36
                    tooltipText: "Back 10s (Left)"
                    tooltipSide: "top"
                    onClicked: VideoService.seekRelative(-10000)
                }

                // Prev Video
                DActionButton {
                    iconName: "skip_previous"
                    iconSize: 22
                    iconColor: Theme.surfaceText
                    buttonSize: 36
                    tooltipText: "Previous Video"
                    tooltipSide: "top"
                    visible: VideoService.fileList.length > 1
                    onClicked: VideoService.prevVideo()
                }

                // Play / Pause main button
                Rectangle {
                    width: 36
                    height: 36
                    radius: 18
                    color: Theme.primary
                    Layout.alignment: Qt.AlignVCenter

                    DIcon {
                        anchors.centerIn: parent
                        name: VideoService.isPlaying ? "pause" : "play_arrow"
                        size: 22
                        color: Theme.primaryText
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: VideoService.togglePlay()
                    }
                }

                // Next Video
                DActionButton {
                    iconName: "skip_next"
                    iconSize: 22
                    iconColor: Theme.surfaceText
                    buttonSize: 36
                    tooltipText: "Next Video"
                    tooltipSide: "top"
                    visible: VideoService.fileList.length > 1
                    onClicked: VideoService.nextVideo()
                }

                // Forward 10s
                DActionButton {
                    iconName: "forward_10"
                    iconSize: 20
                    iconColor: Theme.surfaceText
                    buttonSize: 36
                    tooltipText: "Forward 10s (Right)"
                    tooltipSide: "top"
                    onClicked: VideoService.seekRelative(10000)
                }
            }

            Item { Layout.fillWidth: true }

            // Playback speed badge
            Rectangle {
                height: 30
                width: speedText.implicitWidth + 16
                radius: 15
                Layout.alignment: Qt.AlignVCenter
                color: speedMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow

                Text {
                    id: speedText
                    anchors.centerIn: parent
                    text: VideoService.playbackRate + "x"
                    font.family: Theme.monoFontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    color: Theme.surfaceText
                }

                MouseArea {
                    id: speedMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (VideoService.playbackRate === 1.0) VideoService.playbackRate = 1.25;
                        else if (VideoService.playbackRate === 1.25) VideoService.playbackRate = 1.5;
                        else if (VideoService.playbackRate === 1.5) VideoService.playbackRate = 2.0;
                        else if (VideoService.playbackRate === 2.0) VideoService.playbackRate = 0.5;
                        else VideoService.playbackRate = 1.0;
                    }
                }
            }
        }
    }
}

