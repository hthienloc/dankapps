pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

DGridView {
    id: grid

    property SelectionModel selection: null
    property real iconSize: FileBrowserMetrics.gridIconSizes[FileBrowserMetrics.defaultGridZoom]
    property string renamingPath: ""
    property var cutSet: ({})
    property bool dragEnabled: true
    property bool dropEnabled: true
    property bool multiSelect: true
    property bool singleClickActivates: false
    property string nameHighlight: ""

    readonly property real minimumCellWidth: iconSize + FileBrowserMetrics.gridTilePadding * 2 + FileBrowserMetrics.gridGap
    readonly property int columnsPerRow: Math.max(1, Math.floor(width / minimumCellWidth))
    readonly property real labelLineHeight: Math.ceil(labelMetrics.lineSpacing)
    readonly property real contentOrigin: headerItem ? headerItem.y + headerItem.height : originY

    signal itemClicked(int index, int modifiers)
    signal itemActivated(int index)
    signal itemMiddleClicked(int index)
    signal itemContextMenu(int index, real pointX, real pointY, int modifiers)
    signal itemDragStarted(int index)
    signal itemDropped(int index, var drop)
    signal itemSpringLoaded(int index)
    signal renameSubmitted(string path, string name)
    signal renameCancelled

    function visibleRange() {
        const first = Math.floor((contentY - contentOrigin) / cellHeight) * columnsPerRow;
        const last = Math.floor((contentY - contentOrigin + height) / cellHeight) * columnsPerRow + columnsPerRow - 1;
        return [Math.max(0, first), Math.min(count - 1, last)];
    }

    function indicesIn(rect) {
        const firstRow = Math.max(0, Math.floor((rect.y - contentOrigin) / cellHeight));
        const lastRow = Math.min(Math.ceil(count / columnsPerRow) - 1, Math.floor((rect.y + rect.height - contentOrigin) / cellHeight));
        const mirrored = effectiveLayoutDirection === Qt.RightToLeft;
        const left = mirrored ? width - rect.x - rect.width : rect.x;
        const right = left + rect.width;
        const firstColumn = Math.max(0, Math.floor(left / cellWidth));
        const lastColumn = Math.min(columnsPerRow - 1, Math.floor(right / cellWidth));
        const tileWidth = cellWidth - FileBrowserMetrics.gridGap;
        const tileHeight = cellHeight - FileBrowserMetrics.gridGap;
        const out = [];
        for (let row = firstRow; row <= lastRow; row++) {
            const top = contentOrigin + row * cellHeight;
            if (top >= rect.y + rect.height || top + tileHeight <= rect.y)
                continue;
            for (let column = firstColumn; column <= lastColumn; column++) {
                const start = column * cellWidth + (mirrored ? FileBrowserMetrics.gridGap : 0);
                if (start >= right || start + tileWidth <= left)
                    continue;
                const index = row * columnsPerRow + column;
                if (index < count)
                    out.push(index);
            }
        }
        return out;
    }

    clip: true
    keyNavigationEnabled: false
    activeFocusOnTab: false
    cellWidth: Math.floor(width / columnsPerRow)
    cellHeight: iconSize + labelLineHeight * 3 + FileBrowserMetrics.gridTileVerticalPadding * 2 + FileBrowserMetrics.gridNameSpacing * 2
    cacheBuffer: Math.max(0, height)
    currentIndex: -1
    reuseItems: true

    FontMetrics {
        id: labelMetrics

        font.family: Style.fontFor("ui")
        font.weight: Style.fontWeightFor("ui")
        font.pixelSize: Style.fontSizeSmall
    }

    delegate: FileTile {
        view: grid
    }
}
