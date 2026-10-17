import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    property var album: null
    property real cardWidth: 176
    property real previewHeight: 176

    width: cardWidth
    height: previewHeight + 36

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            id: previewBox
            Layout.fillWidth: true
            Layout.preferredHeight: root.previewHeight
            radius: M3E.tileRadius(cardMouse.pressed, cardMouse.containsMouse, false)
            clip: true
            color: Theme.surfaceContainerHigh
            border.color: cardMouse.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.5) : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.25)
            border.width: 1

            scale: cardMouse.pressed ? M3E.tilePressScale : (cardMouse.containsMouse ? 1.02 : 1.0)
            Behavior on radius { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }
            Behavior on scale { DAnim { duration: M3E.spatialFastMs; easing.bezierCurve: M3E.curveFastSpatial } }

            // 2x2 Grid of Previews
            Grid {
                anchors.fill: parent
                anchors.margins: 4
                columns: 2
                rows: 2
                spacing: 3

                readonly property real cellW: Math.floor((width - 3) / 2)
                readonly property real cellH: Math.floor((height - 3) / 2)

                Repeater {
                    model: 4
                    delegate: Rectangle {
                        width: parent.cellW
                        height: parent.cellH
                        radius: 8
                        clip: true
                        color: Theme.surfaceContainerLowest

                        readonly property string imgPath: {
                            if (!root.album || !root.album.previews || root.album.previews.length === 0) return "";
                            if (index < root.album.previews.length) {
                                return root.album.previews[index];
                            }
                            // Fallback repeat first preview if fewer than 4
                            return root.album.previews[0] || "";
                        }

                        Image {
                            anchors.fill: parent
                            visible: parent.imgPath !== ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: true
                            source: parent.imgPath !== "" ? ("file://" + parent.imgPath) : ""
                            sourceSize.width: 180
                            sourceSize.height: 180
                        }

                        DIcon {
                            anchors.centerIn: parent
                            visible: parent.imgPath === ""
                            name: (root.album && root.album.isFavorites) ? "favorite" : "image"
                            size: 24
                            color: (root.album && root.album.isFavorites) ? Theme.error : Theme.surfaceVariantText
                            opacity: (root.album && root.album.isFavorites) ? 0.6 : 1.0
                        }
                    }
                }
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.album) {
                        ImageService.selectedCategory = root.album.name;
                        ImageService.galleryTab = "gallery";
                    }
                }
            }
        }

        // Album Title & Count
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                DIcon {
                    visible: Boolean(root.album && root.album.isFavorites)
                    name: "favorite"
                    size: 16
                    color: Theme.error
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.album ? root.album.name : ""
                    font.pixelSize: Theme.fontSizeSmall + 1
                    font.weight: Theme.fontWeightBold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: root.album ? (root.album.totalCount + " photos") : ""
                font.pixelSize: Theme.fontSizeSmall - 1
                color: Theme.surfaceVariantText
                elide: Text.ElideRight
            }
        }
    }
}
