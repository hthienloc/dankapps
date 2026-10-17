import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    height: 92
    width: Math.min(680, parent.width - 48)
    radius: Style.cornerRadiusXL
    color: Style.withAlpha(Style.surfaceContainerHigh, 0.95)
    border.color: Qt.rgba(Style.outlineVariant.r, Style.outlineVariant.g, Style.outlineVariant.b, 0.30)
    border.width: 1

    ElevationShadow {
        anchors.fill: parent
        z: -1
        targetRadius: parent.radius
        targetColor: parent.color
        level: Style.elevationLevel2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: 10
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 6

        // Scrubber / Seek Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            StyledText {
                text: VideoService.formatTime(VideoService.position)
                font.family: Theme.monoFontFamily
                font.pixelSize: Style.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            Item {
                id: trackArea
                Layout.fillWidth: true
                height: 24

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: seekMouse.containsMouse || seekMouse.drag.active ? 8 : 4
                    radius: height / 2
                    color: Theme.surfaceContainerHighest

                    Behavior on height {
                        DAnim {
                            duration: Style.shortDuration
                            easing.bezierCurve: Style.expressiveCurves.standard
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: VideoService.duration > 0 ? parent.width * Math.max(0, Math.min(1, VideoService.position / VideoService.duration)) : 0
                        radius: parent.radius
                        color: Theme.primary
                    }
                }

                // Handle thumb
                Rectangle {
                    x: (VideoService.duration > 0 ? (trackArea.width - width) * (VideoService.position / VideoService.duration) : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: seekMouse.containsMouse || seekMouse.drag.active ? 16 : 10
                    height: width
                    radius: width / 2
                    color: Theme.primary
                    border.color: Theme.surfaceContainerLowest
                    border.width: 2
                    visible: seekMouse.containsMouse || seekMouse.drag.active

                    Behavior on width {
                        DAnim {
                            duration: Style.shortDuration
                            easing.bezierCurve: Style.expressiveCurves.standard
                        }
                    }
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

            StyledText {
                text: VideoService.formatTime(VideoService.duration)
                font.family: Theme.monoFontFamily
                font.pixelSize: Style.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
            }
        }

        // Control Buttons
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 42

            // Left cluster: Volume
            RowLayout {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                DActionButton {
                    iconName: VideoService.isMuted || VideoService.volume === 0 ? "volume_off" : (VideoService.volume < 0.5 ? "volume_down" : "volume_up")
                    iconSize: 20
                    buttonSize: Style.buttonHeightS
                    iconColor: Theme.surfaceText
                    tooltipText: VideoService.isMuted ? "Unmute (M)" : "Mute (M)"
                    tooltipSide: "top"
                    onClicked: VideoService.toggleMute()
                }

                // Volume slider track
                Item {
                    Layout.preferredWidth: 72
                    height: 24
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.width >= 500

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: volMouse.containsMouse ? 6 : 4
                        radius: height / 2
                        color: Theme.surfaceContainerHighest

                        Behavior on height {
                            DAnim {
                                duration: Style.shortDuration
                                easing.bezierCurve: Style.expressiveCurves.standard
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * (VideoService.isMuted ? 0 : VideoService.volume)
                            radius: parent.radius
                            color: Theme.primary
                        }
                    }

                    MouseArea {
                        id: volMouse
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

            // Playback cluster (strictly centered)
            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                // Step Back 10s
                DActionButton {
                    iconName: "replay_10"
                    iconSize: 20
                    buttonSize: Style.buttonHeightS
                    iconColor: Theme.surfaceText
                    tooltipText: "Back 10s (Left)"
                    tooltipSide: "top"
                    onClicked: VideoService.seekRelative(-10000)
                }

                // Prev Video
                DActionButton {
                    iconName: "skip_previous"
                    iconSize: 22
                    buttonSize: Style.buttonHeightS
                    iconColor: Theme.surfaceText
                    tooltipText: "Previous Video (PageUp)"
                    tooltipSide: "top"
                    visible: VideoService.fileList.length > 1
                    onClicked: VideoService.prevVideo()
                }

                // Play / Pause main button — M3E shape-morphing button (circle when paused -> squircle when playing/pressed)
                Rectangle {
                    width: 44
                    height: 44
                    radius: playMouse.pressed ? M3E.pressRadiusS : (VideoService.isPlaying && !playMouse.containsMouse ? M3E.pressRadiusM : 22)
                    scale: playMouse.pressed ? M3E.iconBtnPressScale : (playMouse.containsMouse ? 1.05 : 1.0)
                    color: playMouse.containsMouse ? Theme.primaryContainer : Theme.primary
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on radius {
                        DAnim {
                            duration: M3E.spatialFastMs
                            easing.bezierCurve: M3E.curveFastSpatial
                        }
                    }

                    Behavior on scale {
                        DAnim {
                            duration: M3E.spatialFastMs
                            easing.bezierCurve: M3E.curveFastSpatial
                        }
                    }

                    Behavior on color {
                        DColorAnim {
                            duration: M3E.effectsFastMs
                            easing.bezierCurve: M3E.curveFastEffects
                        }
                    }

                    DIcon {
                        anchors.centerIn: parent
                        name: VideoService.isPlaying ? "pause" : "play_arrow"
                        size: 24
                        filled: true
                        color: playMouse.containsMouse ? Theme.onPrimaryContainer : Theme.onPrimary
                    }

                    MouseArea {
                        id: playMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: VideoService.togglePlay()
                    }
                }

                // Next Video
                DActionButton {
                    iconName: "skip_next"
                    iconSize: 22
                    buttonSize: Style.buttonHeightS
                    iconColor: Theme.surfaceText
                    tooltipText: "Next Video (PageDown)"
                    tooltipSide: "top"
                    visible: VideoService.fileList.length > 1
                    onClicked: VideoService.nextVideo()
                }

                // Forward 10s
                DActionButton {
                    iconName: "forward_10"
                    iconSize: 20
                    buttonSize: Style.buttonHeightS
                    iconColor: Theme.surfaceText
                    tooltipText: "Forward 10s (Right)"
                    tooltipSide: "top"
                    onClicked: VideoService.seekRelative(10000)
                }
            }

            // Right cluster: Playback speed chip (M3E morphing chip)
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitHeight: Style.buttonHeightXS - 4
                implicitWidth: Math.max(54, speedText.implicitWidth + 16)
                radius: speedMouse.pressed ? M3E.pressRadiusXS : height / 2
                scale: speedMouse.pressed ? M3E.iconBtnPressScale : 1.0
                color: VideoService.playbackRate !== 1.0
                    ? Theme.secondaryContainer
                    : (speedMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerLow)
                border.color: Theme.withAlpha(Theme.outlineVariant, 0.25)
                border.width: VideoService.playbackRate !== 1.0 ? 0 : 1

                Behavior on radius {
                    DAnim {
                        duration: M3E.spatialFastMs
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }

                Behavior on scale {
                    DAnim {
                        duration: M3E.spatialFastMs
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }

                Behavior on color {
                    DColorAnim {
                        duration: M3E.effectsFastMs
                        easing.bezierCurve: M3E.curveFastEffects
                    }
                }

                StyledText {
                    id: speedText
                    anchors.centerIn: parent
                    text: VideoService.playbackRate + "x"
                    font.family: Theme.monoFontFamily
                    font.pixelSize: Style.fontSizeSmall
                    font.weight: Font.Medium
                    color: VideoService.playbackRate !== 1.0 ? Theme.onSecondaryContainer : Theme.surfaceText
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
