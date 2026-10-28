import QtQuick
import qs.Common

Item {
    id: root

    property var model: []
    property int columns: 1
    property real tileWidth: 160
    property real spacing: 10
    property bool isTrashMode: false
    property real contentHeight: 0

    function relayout() {
        const bottoms = new Array(Math.max(1, columns)).fill(0)
        for (let i = 0; i < tiles.count; i++) {
            const tile = tiles.itemAt(i)
            if (!tile)
                continue

            let shortestColumn = 0
            for (let column = 1; column < bottoms.length; column++) {
                if (bottoms[column] < bottoms[shortestColumn])
                    shortestColumn = column
            }

            tile.masonryColumn = shortestColumn
            tile.masonryY = bottoms[shortestColumn]
            bottoms[shortestColumn] += tile.height + spacing
        }

        let maxHeight = 0
        for (let i = 0; i < bottoms.length; i++)
            maxHeight = Math.max(maxHeight, bottoms[i])
        contentHeight = tiles.count > 0 ? Math.max(0, maxHeight - spacing) : 0
    }

    implicitHeight: contentHeight

    onColumnsChanged: relayoutTimer.restart()
    onSpacingChanged: relayoutTimer.restart()
    onTileWidthChanged: relayoutTimer.restart()
    onModelChanged: relayoutTimer.restart()

    Timer {
        id: relayoutTimer
        interval: 0
        onTriggered: root.relayout()
    }

    Repeater {
        id: tiles
        model: root.model
        onItemAdded: relayoutTimer.restart()
        onItemRemoved: relayoutTimer.restart()

        delegate: GalleryThumbnail {
            required property var modelData
            required property int index

            property real masonryY: 0

            imageItem: modelData
            tileSize: root.tileWidth
            thumbnailLayout: "masonry"
            isTrashMode: root.isTrashMode
            x: masonryColumn * (root.tileWidth + root.spacing)
            y: masonryY

            onHeightChanged: relayoutTimer.restart()
        }
    }
}
