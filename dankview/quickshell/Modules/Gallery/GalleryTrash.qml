import QtQuick
import QtQuick.Layouts
import qs.Common
import qs.Services
import qs.DCommon.Common
import qs.DCommon.Widgets

Item {
    id: root

    readonly property string query: ImageService.searchQueryDebounced
    readonly property var allTrash: ImageService.trashImages || []

    readonly property var filteredTrash: {
        if (!root.query) return allTrash;
        const q = root.query.toLowerCase();
        return allTrash.filter(item => {
            const name = (item.name || "").toLowerCase();
            const orig = (item.originalPath || "").toLowerCase();
            return name.indexOf(q) !== -1 || orig.indexOf(q) !== -1;
        });
    }

    readonly property var targetTileSizes: [100, 135, 170, 230, 320]
    readonly property int zoomIdx: Math.max(0, Math.min(4, (ImageService.galleryZoomLevel || 3) - 1))
    readonly property int targetTileSize: targetTileSizes[zoomIdx]
    readonly property int columns: Math.max(1, Math.floor((width - 40) / targetTileSize))
    readonly property real tileWidth: Math.floor((width - 40 - (columns - 1) * 10) / columns)

    WheelHandler {
        target: null
        acceptedModifiers: Qt.ControlModifier
        onWheel: (event) => {
            if (event.angleDelta.y > 0) {
                ImageService.galleryZoomLevel = Math.min(5, (ImageService.galleryZoomLevel || 3) + 1);
            } else if (event.angleDelta.y < 0) {
                ImageService.galleryZoomLevel = Math.max(1, (ImageService.galleryZoomLevel || 3) - 1);
            }
            event.accepted = true;
        }
    }

    Connections {
        target: ImageService
        function onScrollToTopRequested() {
            flick.stopMomentum();
            flick.contentY = 0;
            flick.prevContentY = 0;
            flick.accumulatedDown = 0;
            ImageService.searchBarCollapsed = false;
        }
        function onSearchBarCollapsedChanged() {
            if (!ImageService.searchBarCollapsed) {
                flick.prevContentY = flick.contentY;
                flick.accumulatedDown = 0;
            }
        }
    }

    // Scrollable content
    DFlickable {
        id: flick
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        contentWidth: width
        contentHeight: contentCol.implicitHeight + 40
        clip: true

        property real prevContentY: 0
        property real accumulatedDown: 0

        onContentYChanged: {
            if (contentY <= 8) {
                accumulatedDown = 0;
                ImageService.searchBarCollapsed = false;
            } else {
                const delta = contentY - prevContentY;
                if (delta > 0) {
                    accumulatedDown += delta;
                    if (accumulatedDown > 12 && contentY > 20) {
                        if (!ImageService.searchQuery) {
                            ImageService.searchBarCollapsed = true;
                        }
                    }
                } else if (delta < -2) {
                    accumulatedDown = 0;
                }
            }
            prevContentY = contentY;
        }

        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: 20

            // Spacer for floating search bar
            Item {
                Layout.fillWidth: true
                implicitHeight: 64
            }

            // Top Header: Title, Count & Action Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: Style.spacingM

                ColumnLayout {
                    spacing: 2
                    StyledText {
                        text: "Trash"
                        font.pixelSize: Theme.fontSizeLarge + 4
                        font.weight: Theme.fontWeightBold
                        color: Theme.surfaceText
                    }
                    StyledText {
                        text: root.allTrash.length > 0
                            ? (root.allTrash.length + (root.allTrash.length === 1 ? " image in trash" : " images in trash"))
                            : "Trash is empty"
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }
                }

                Item { Layout.fillWidth: true }

                // Empty Trash Button
                Rectangle {
                    visible: root.allTrash.length > 0
                    implicitHeight: Style.buttonHeightS
                    implicitWidth: emptyRow.implicitWidth + Style.spacingL
                    radius: height / 2
                    color: emptyMouse.pressed
                        ? Theme.error
                        : (emptyMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                    border.color: M3E.stroke(Theme.outlineVariant, M3E.strokeSurface)
                    border.width: 1

                    Behavior on color { DColorAnim { duration: M3E.effectsFastMs; easing.bezierCurve: M3E.curveFastEffects } }

                    RowLayout {
                        id: emptyRow
                        anchors.centerIn: parent
                        spacing: Style.spacingS

                        DIcon {
                            name: "delete_sweep"
                            size: Style.iconSizeSmall
                            color: Theme.error
                        }

                        StyledText {
                            text: "Empty Trash"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.fontWeightMedium
                            color: Theme.error
                        }
                    }

                    MouseArea {
                        id: emptyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ImageService.emptyTrash()
                    }
                }
            }

            // Grid of Trashed Images (Reusing GalleryThumbnail with isTrashMode)
            Grid {
                Layout.fillWidth: true
                columns: root.columns
                columnSpacing: 10
                rowSpacing: 10
                visible: root.filteredTrash.length > 0

                Repeater {
                    model: root.filteredTrash

                    delegate: GalleryThumbnail {
                        imageItem: modelData
                        tileSize: root.tileWidth
                        isTrashMode: true
                    }
                }
            }
        }
    }

    // Empty State
    Item {
        anchors.fill: parent
        visible: root.filteredTrash.length === 0 && !ImageService.isTrashLoading

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            DIcon {
                Layout.alignment: Qt.AlignHCenter
                name: root.query !== "" ? "search_off" : "delete_outline"
                size: 48
                color: Theme.surfaceVariantText
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.query !== "" ? ('No results for "' + ImageService.searchQuery + '"') : "Trash is empty"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Theme.fontWeightBold
                color: Theme.surfaceText
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.query !== "" ? "Try a different search term" : "Images moved to trash will appear here"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
            }
        }
    }

    // Loading State
    Item {
        anchors.fill: parent
        visible: ImageService.isTrashLoading && root.allTrash.length === 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12

            DIcon {
                Layout.alignment: Qt.AlignHCenter
                name: "refresh"
                size: 40
                color: Theme.primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: "Loading trash..."
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.surfaceVariantText
            }
        }
    }
}
