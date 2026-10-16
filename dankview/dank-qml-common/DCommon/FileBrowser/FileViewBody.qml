pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common
import qs.DCommon.Widgets

FocusScope {
    id: body

    required property var directory
    required property SelectionModel selection

    property string viewMode: "list"
    property int gridZoom: 1
    property int listZoom: 1
    property var listColumns: ["size", "modified"]
    property var columnWidths: ({})
    property string sortKey: "name"
    property bool sortDescending: false
    property bool showHidden: false
    property bool multiSelect: true
    property bool dragEnabled: true
    property bool dropEnabled: true
    property bool showSelectionFooter: true
    property bool escapeClearsSelection: true
    property string emptyText: I18n.tr("This folder is empty", "empty directory placeholder")
    property color surfaceColor: "transparent"
    property color chipColor: Style.chipSurface
    property Component header: null
    property string renamingPath: ""
    property var cutSet: ({})
    property var childCounts: ({})
    property bool singleClickActivates: false
    property bool typeAheadEnabled: true
    property string typeAheadMode: "jump"
    property bool countFolders: true
    property string homePath: ""
    property string nameHighlight: ""
    property bool filtering: false
    property bool previewOpen: true
    property bool previewKeys: false
    property var directoryPool: null
    property bool slowListing: false
    property real _lastActivation: 0

    readonly property var view: viewLoader.item
    readonly property bool columnsMode: viewMode === "columns" && directoryPool !== null
    readonly property bool columnsScroll: header !== null && viewMode === "list"
    readonly property int zoom: viewMode === "grid" ? gridZoom : listZoom
    readonly property var iconSizes: FileBrowserMetrics.iconSizesFor(viewMode)
    readonly property real iconSize: iconSizes[Math.max(0, Math.min(iconSizes.length - 1, zoom))]
    readonly property var fittingColumns: {
        let available = width - iconSize - FileBrowserMetrics.listRowPadding * 3 - FileBrowserMetrics.nameColumnMinWidth;
        const kept = [];
        for (const id of listColumns) {
            const needed = columnWidthFor(id) + FileBrowserMetrics.columnGap;
            if (needed > available)
                break;
            available -= needed;
            kept.push(id);
        }
        return kept;
    }
    readonly property bool listing: directory.loading && directory.count === 0
    readonly property bool empty: !directory.loading && directory.error === "" && directory.count === 0
    readonly property var dragScrollTarget: dragScrollTargetFor(FileDragHover.area)
    readonly property real dragScrollDirection: {
        const target = dragScrollTarget;
        if (!target)
            return 0;
        const y = target.mapFromItem(null, FileDragHover.point.x, FileDragHover.point.y).y;
        const margin = Math.min(FileBrowserMetrics.dragScrollEdge, target.height / 2);
        if (y < margin)
            return target.contentY > target.originY ? -Math.min(1, (margin - y) / margin) : 0;
        if (y > target.height - margin)
            return target.contentY < target.originY + target.contentHeight - target.height ? Math.min(1, (y - target.height + margin) / margin) : 0;
        return 0;
    }

    signal activateRequested(var entry)
    signal itemMenuRequested(int index, real pointX, real pointY, int modifiers)
    signal backgroundMenuRequested(real pointX, real pointY)
    signal columnsMenuRequested(real pointX, real pointY)
    signal itemsDropped(string dest, var drop)
    signal dragRequested(var paths)
    signal renameRequested(string path, string name)
    signal openRequested(string path)
    signal tabRequested(string path)
    signal revealRequested(string path)
    signal focusRequested
    signal sortRequested(string key)
    signal zoomRequested(string viewMode, int level)
    signal columnResizeRequested(string id, real width)
    signal previewKeyRequested(string action, int step)
    signal directoryReplaced
    signal filterRequested(string text)
    signal filterFocusRequested

    function focusBody() {
        forceActiveFocus();
    }

    function entryAt(index) {
        return index >= 0 && index < directory.count ? directory.entries.get(index) : null;
    }

    function cursorIndex() {
        return selection.cursorPath === "" ? -1 : directory.indexOfPath(selection.cursorPath);
    }

    function cursorEntry() {
        return entryAt(cursorIndex());
    }

    function previewEntry() {
        if (selection.count === 0)
            return null;
        const target = selection.contains(selection.cursorPath) ? selection.cursorPath : selection.paths[0];
        return entryAt(directory.indexOfPath(target));
    }

    function selectionInViewOrder() {
        const found = [];
        if (selection.count === 0)
            return found;
        for (let i = 0; i < directory.count; i++) {
            const entry = directory.entries.get(i);
            if (selection.contains(entry.path))
                found.push(entry);
        }
        return found;
    }

    function selectedEntries() {
        if (selection.count === 0)
            return [];
        if (selection.count === 1) {
            const entry = entryAt(directory.indexOfPath(selection.paths[0]));
            return entry ? [entry] : [];
        }
        const found = new Map();
        for (let i = 0; i < directory.count; i++) {
            const entry = directory.entries.get(i);
            if (selection.contains(entry.path))
                found.set(entry.path, entry);
        }
        return selection.paths.map(selected => found.get(selected)).filter(entry => entry !== undefined);
    }

    function beginRename(target) {
        renamingPath = target;
    }

    function finishRename(target, name) {
        renamingPath = "";
        focusBody();
        if (target !== "")
            renameRequested(target, name);
    }

    function scrollOffset() {
        const target = view?.activeList ?? view;
        return target ? target.contentY - target.originY : 0;
    }

    function scrollTo(offset) {
        const target = view?.activeList ?? view;
        if (!target)
            return;
        if (typeof target.forceLayout === "function")
            target.forceLayout();
        target.contentY = target.originY + Math.max(0, Math.min(offset, target.contentHeight - target.height));
    }

    function enterCursor() {
        const entry = cursorEntry();
        if (entry?.isDir)
            openRequested(entry.path);
    }

    function leaveColumn() {
        if (FilePaths.parentOf(directory.path) === "")
            return;
        revealRequested(directory.path);
    }

    function cursorRect() {
        const index = cursorIndex();
        if (index < 0 || !view)
            return Qt.rect(0, 0, 0, 0);
        view.revealIndex(index);
        const item = view.itemAtIndex(index);
        if (!item)
            return Qt.rect(0, 0, 0, 0);
        const point = item.mapToItem(body, 0, 0);
        return Qt.rect(point.x, point.y, item.width, item.height);
    }

    function toggleAtCursor() {
        if (selection.cursorPath === "")
            return;
        selection.keyboardCursor = true;
        if (multiSelect) {
            selection.toggle(selection.cursorPath);
            return;
        }
        selection.select(selection.cursorPath);
    }

    function forwardItemMenu(source, index, pointX, pointY, modifiers) {
        const entry = entryAt(index);
        if (entry && !selection.contains(entry.path))
            selection.select(entry.path);
        const point = source.mapToItem(body, pointX, pointY);
        itemMenuRequested(index, point.x, point.y, modifiers);
    }

    function columnWidthFor(id) {
        return columnWidths[id] ?? FileColumns.specFor(id)?.width ?? FileBrowserMetrics.columnMinWidth;
    }

    function zoomBy(step) {
        const level = Math.max(0, Math.min(iconSizes.length - 1, zoom + step));
        if (level === zoom)
            return;
        zoomRequested(viewMode, level);
    }

    function reveal(targets, extend) {
        const present = [].concat(targets).filter(path => directory.indexOfPath(path) >= 0);
        if (present.length === 0)
            return [];
        if (!extend) {
            selection.select(present[0]);
            const index = directory.indexOfPath(present[0]);
            if (columnsMode)
                view?.revealIndex(index);
            else
                view?.positionViewAtIndex(index, ListView.Center);
        }
        for (const path of present)
            selection.add(path);
        return present;
    }

    function activate(index) {
        const entry = entryAt(index);
        if (!entry)
            return;
        const now = Date.now();
        if (singleClickActivates && now - _lastActivation < FileBrowserMetrics.activationDebounce)
            return;
        _lastActivation = now;
        selection.select(entry.path);
        activateRequested(entry);
    }

    function middleClick(index) {
        const entry = entryAt(index);
        if (entry?.isDir)
            tabRequested(entry.path);
    }

    function click(index, modifiers) {
        focusRequested();
        const entry = entryAt(index);
        if (!entry)
            return;
        selection.keyboardCursor = false;
        if (!multiSelect) {
            selection.select(entry.path);
            return;
        }
        if (singleClickActivates && modifiers === Qt.NoModifier) {
            activate(index);
            return;
        }
        if ((modifiers & Qt.ShiftModifier) !== 0) {
            selection.extendTo(directory.entries, index);
            return;
        }
        if ((modifiers & Qt.ControlModifier) !== 0) {
            selection.toggle(entry.path);
            return;
        }
        selection.select(entry.path);
    }

    function moveTo(target, modifiers) {
        view?.revealIndex(target);
        selection.keyboardCursor = true;
        if (multiSelect && (modifiers & Qt.ShiftModifier) !== 0) {
            selection.extendTo(directory.entries, target);
            return;
        }
        selection.select(directory.entries.get(target).path);
    }

    function moveCursor(step, modifiers) {
        if (directory.count === 0)
            return;
        const current = cursorIndex();
        moveTo(Math.max(0, Math.min(directory.count - 1, current < 0 ? 0 : current + step)), modifiers);
    }

    function jumpTo(index, modifiers) {
        if (directory.count === 0)
            return;
        moveTo(Math.max(0, Math.min(directory.count - 1, index)), modifiers);
    }

    function pageStep() {
        if (viewMode === "grid")
            return Math.max(1, Math.floor(view.height / view.cellHeight)) * view.columnsPerRow;
        return Math.max(1, Math.floor(view.height / view.rowPitch));
    }

    function typeAheadTarget(count, nameAt, current, prefix, text) {
        const repeated = prefix !== "" && Array.from(prefix).every(letter => letter === text);
        const needle = repeated ? text : prefix + text;
        const start = repeated && current >= 0 ? current + 1 : 0;
        for (let step = 0; step < count; step++) {
            const index = (start + step) % count;
            if (nameAt(index).toLowerCase().startsWith(needle))
                return index;
        }
        return -1;
    }

    function typeAhead(text) {
        if (typeAheadMode === "filter") {
            typeAheadTimer.prefix = "";
            filterRequested(text);
            return;
        }
        const letter = text.toLowerCase();
        const target = typeAheadTarget(directory.count, index => directory.entries.get(index).name, cursorIndex(), typeAheadTimer.prefix, letter);
        typeAheadTimer.prefix += letter;
        typeAheadTimer.restart();
        if (target >= 0)
            jumpTo(target, Qt.NoModifier);
    }

    function springLoad(index) {
        const entry = entryAt(index);
        if (entry?.isDir)
            openRequested(entry.path);
    }

    function dragScrollTargetFor(area) {
        if (area?.scrollView)
            return ownsItem(area.scrollView) ? area.scrollView : null;
        for (let item = area; item; item = item.parent) {
            if (typeof item.indicesIn !== "function")
                continue;
            return ownsItem(item) ? item : null;
        }
        return null;
    }

    function ownsItem(item) {
        for (let current = item; current; current = current.parent) {
            if (current === body)
                return true;
        }
        return false;
    }

    function requestCounts(first, last) {
        if (!countFolders || viewMode !== "list" || !fittingColumns.includes("size"))
            return;
        const wanted = [];
        for (let i = first; i <= Math.min(last, directory.count - 1); i++) {
            const entry = entryAt(i);
            if (!entry?.isDir || childCounts[entry.path] !== undefined)
                continue;
            wanted.push(entry.path);
        }
        if (wanted.length === 0 || !directory.backend)
            return;
        directory.backend.count(wanted, showHidden, result => {
            if (result.error)
                return;
            const merged = Object.assign({}, body.childCounts);
            for (const path in result.counts || ({})) {
                const count = result.counts[path];
                merged[path] = count.code ? -1 : count.count;
            }
            body.childCounts = merged;
        });
    }

    function selectedBytes() {
        let total = 0;
        for (const entry of selectedEntries()) {
            if (entry.size < 0)
                return -1;
            total += entry.size;
        }
        return total;
    }

    function startDrag(index) {
        const entry = entryAt(index);
        if (!entry)
            return;
        if (!selection.contains(entry.path))
            selection.select(entry.path);
        dragRequested(selection.paths.slice());
    }

    function settleNow() {
        settle.stop();
        if (!view || columnsMode)
            return;
        const range = view.visibleRange();
        directory.requestThumbnails(range[0], range[1]);
        requestCounts(range[0], range[1]);
        if (range[1] >= directory.count - 1)
            directory.loadMore();
    }

    onViewModeChanged: renamingPath = ""
    function resetScroll() {
        const target = view?.activeList ?? view;
        if (!target || columnsMode)
            return;
        if (target.savedY !== undefined)
            target.savedY = target.originY;
        target.positionViewAtBeginning();
    }

    onDirectoryChanged: {
        selection.clear();
        renamingPath = "";
        childCounts = ({});
        if (!columnsMode)
            scrollReset.restart();
        directoryReplaced();
    }
    onListingChanged: {
        if (listing) {
            skeletonDelay.restart();
            return;
        }
        skeletonDelay.stop();
        slowListing = false;
    }
    Component.onCompleted: {
        if (listing)
            skeletonDelay.start();
    }

    Connections {
        target: body.directory

        function onPathReset() {
            body.selection.clear();
            body.renamingPath = "";
            body.childCounts = ({});
            body.view?.positionViewAtBeginning();
        }

        function onListed() {
            body.selection.prune(body.directory.entries);
            body.settleNow();
        }
    }

    Timer {
        id: scrollReset

        interval: 0
        onTriggered: body.resetScroll()
    }

    Timer {
        id: skeletonDelay

        interval: FileBrowserMetrics.skeletonDelay
        onTriggered: body.slowListing = body.listing
    }

    Timer {
        id: typeAheadTimer

        property string prefix: ""

        interval: FileBrowserMetrics.typeAheadInterval
        onTriggered: prefix = ""
    }

    Timer {
        id: settle

        interval: FileBrowserMetrics.settleInterval
        onTriggered: body.settleNow()
    }

    FrameAnimation {
        running: body.dragScrollTarget !== null && body.dragScrollDirection !== 0
        onTriggered: {
            const target = body.dragScrollTarget;
            const maximum = target.originY + Math.max(0, target.contentHeight - target.height);
            const next = Math.max(target.originY, Math.min(maximum, target.contentY + body.dragScrollDirection * FileBrowserMetrics.listRowHeight * FileBrowserMetrics.dragScrollRowsPerSecond * frameTime));
            if (next === target.contentY)
                return;
            target.contentY = next;
            FileDragHover.scrolled = true;
        }
    }

    Keys.onPressed: event => handleKey(event)

    function previewKey(event) {
        const alt = (event.modifiers & Qt.AltModifier) !== 0;
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        const shift = (event.modifiers & Qt.ShiftModifier) !== 0;
        switch (event.key) {
        case Qt.Key_Space:
            if (alt)
                return "";
            if (shift)
                return "step";
            return ctrl || event.isAutoRepeat ? "" : "toggle";
        case Qt.Key_PageUp:
        case Qt.Key_PageDown:
            return alt && !ctrl && !shift ? "scroll" : "";
        case Qt.Key_Left:
        case Qt.Key_Right:
        case Qt.Key_0:
            return alt && ctrl && !shift ? "resize" : "";
        default:
            return "";
        }
    }

    function previewStep(event) {
        switch (event.key) {
        case Qt.Key_Space:
            return (event.modifiers & Qt.ControlModifier) !== 0 ? -1 : 1;
        case Qt.Key_PageUp:
        case Qt.Key_Left:
            return -1;
        case Qt.Key_0:
            return 0;
        default:
            return 1;
        }
    }

    function handleKey(event) {
        const modifiers = event.modifiers;
        const columns = view?.columnsPerRow ?? 1;
        const preview = previewKeys ? previewKey(event) : "";
        if (preview !== "") {
            previewKeyRequested(preview, previewStep(event));
            event.accepted = true;
            return;
        }
        if ((modifiers & Qt.AltModifier) !== 0)
            return;
        switch (event.key) {
        case Qt.Key_Down:
            moveCursor(columns, modifiers);
            break;
        case Qt.Key_Up:
            if (typeAheadMode === "filter" && filtering && modifiers === Qt.NoModifier && cursorIndex() < columns) {
                filterFocusRequested();
                break;
            }
            moveCursor(-columns, modifiers);
            break;
        case Qt.Key_Right:
            if (columnsMode) {
                enterCursor();
                break;
            }
            moveCursor(viewMode === "grid" ? 1 : columns, modifiers);
            break;
        case Qt.Key_Left:
            if (columnsMode) {
                leaveColumn();
                break;
            }
            moveCursor(viewMode === "grid" ? -1 : -columns, modifiers);
            break;
        case Qt.Key_Home:
            jumpTo(0, modifiers);
            break;
        case Qt.Key_End:
            jumpTo(directory.count - 1, modifiers);
            break;
        case Qt.Key_PageDown:
            moveCursor(pageStep(), modifiers);
            break;
        case Qt.Key_PageUp:
            moveCursor(-pageStep(), modifiers);
            break;
        case Qt.Key_Space:
            if (previewKeys && event.isAutoRepeat && (modifiers & Qt.ControlModifier) === 0)
                break;
            toggleAtCursor();
            break;
        case Qt.Key_Escape:
            if (!escapeClearsSelection || selection.empty)
                return;
            selection.clear();
            break;
        case Qt.Key_Backspace:
            if (typeAheadTimer.prefix !== "") {
                typeAheadTimer.prefix = "";
                break;
            }
            openRequested("..");
            break;
        case Qt.Key_Slash:
        case Qt.Key_Question:
            // Left to the host: search and help, never a name prefix.
            return;
        default:
            if (!typeAheadEnabled || (modifiers !== Qt.NoModifier && modifiers !== Qt.ShiftModifier))
                return;
            if (event.text === "" || event.text.charCodeAt(0) < 0x20)
                return;
            typeAhead(event.text);
        }
        event.accepted = true;
    }

    WheelHandler {
        acceptedModifiers: Qt.ControlModifier
        onWheel: event => body.zoomBy(event.angleDelta.y > 0 ? 1 : -1)
    }

    component ViewBackground: FileViewBackground {
        selection: body.selection
        dropPath: body.directory.path
        onCleared: {
            body.focusRequested();
            body.selection.clear();
        }
        onContextMenuRequested: (pointX, pointY) => {
            const point = view.mapToItem(body, pointX, pointY);
            body.backgroundMenuRequested(point.x, point.y);
        }
        onDropped: drop => body.itemsDropped(body.directory.path, drop)
    }

    Component {
        id: listComponent

        FileListView {
            id: listView

            selection: body.selection
            iconSize: body.iconSize
            renamingPath: body.renamingPath
            cutSet: body.cutSet
            childCounts: body.childCounts
            columnIds: body.fittingColumns
            storedWidths: body.columnWidths
            singleClickActivates: body.singleClickActivates
            nameHighlight: body.nameHighlight
            multiSelect: body.multiSelect
            dragEnabled: body.dragEnabled
            dropEnabled: body.dropEnabled
            model: body.directory.entries
            header: body.columnsScroll ? scrollingHeader : body.header
            onItemClicked: (index, modifiers) => body.click(index, modifiers)
            onItemActivated: index => body.activate(index)
            onItemMiddleClicked: index => body.middleClick(index)
            onItemContextMenu: (index, pointX, pointY, modifiers) => body.forwardItemMenu(listView, index, pointX, pointY, modifiers)
            onItemDragStarted: index => body.startDrag(index)
            onItemDropped: (index, drop) => body.itemsDropped(body.entryAt(index).path, drop)
            onItemSpringLoaded: index => body.springLoad(index)
            onRenameSubmitted: (target, name) => body.finishRename(target, name)
            onRenameCancelled: body.finishRename("", "")
            onContentYChanged: settle.restart()
            onCountChanged: settle.restart()

            ViewBackground {
                view: listView
            }
        }
    }

    Component {
        id: columnsComponent

        FileColumnsView {
            body: body
        }
    }

    Component {
        id: gridComponent

        FileGridView {
            id: gridView

            selection: body.selection
            iconSize: body.iconSize
            renamingPath: body.renamingPath
            cutSet: body.cutSet
            singleClickActivates: body.singleClickActivates
            nameHighlight: body.nameHighlight
            multiSelect: body.multiSelect
            dragEnabled: body.dragEnabled
            dropEnabled: body.dropEnabled
            model: body.directory.entries
            header: body.header
            onItemClicked: (index, modifiers) => body.click(index, modifiers)
            onItemActivated: index => body.activate(index)
            onItemMiddleClicked: index => body.middleClick(index)
            onItemContextMenu: (index, pointX, pointY, modifiers) => body.forwardItemMenu(gridView, index, pointX, pointY, modifiers)
            onItemDragStarted: index => body.startDrag(index)
            onItemDropped: (index, drop) => body.itemsDropped(body.entryAt(index).path, drop)
            onItemSpringLoaded: index => body.springLoad(index)
            onRenameSubmitted: (target, name) => body.finishRename(target, name)
            onRenameCancelled: body.finishRename("", "")
            onContentYChanged: settle.restart()
            onCountChanged: settle.restart()

            ViewBackground {
                view: gridView
            }
        }
    }

    component ColumnHeader: FileColumnHeader {
        id: columns

        columnIds: body.fittingColumns
        widths: body.columnWidths
        sortKey: body.sortKey
        sortDescending: body.sortDescending
        nameIndent: body.iconSize + FileBrowserMetrics.listRowPadding * 2
        backgroundColor: body.surfaceColor
        onSortRequested: key => body.sortRequested(key)
        onColumnsMenuRequested: (pointX, pointY) => {
            const point = columns.mapToItem(body, pointX, pointY);
            body.columnsMenuRequested(point.x, point.y);
        }
        onColumnResized: (id, width) => body.columnResizeRequested(id, width)
    }

    Component {
        id: scrollingHeader

        Column {
            width: parent?.width ?? 0

            Loader {
                width: parent.width
                sourceComponent: body.header
            }

            ColumnHeader {
                width: parent.width
            }
        }
    }

    ColumnHeader {
        id: columnHeader

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: body.viewMode === "list" && !body.columnsScroll
        height: visible ? implicitHeight : 0
    }

    Loader {
        id: viewLoader

        anchors.top: columnHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        sourceComponent: body.viewMode === "grid" ? gridComponent : (body.columnsMode ? columnsComponent : listComponent)
    }

    LoadingSkeleton {
        anchors.fill: viewLoader
        anchors.topMargin: body.view?.headerItem?.height ?? 0
        visible: body.slowListing && !body.columnsMode
        rowHeight: body.viewMode === "grid" ? body.iconSize : FileBrowserMetrics.listRowHeightFor(body.iconSize)
    }

    StyledText {
        anchors.centerIn: viewLoader
        visible: body.empty && body.emptyText !== "" && !body.columnsMode
        text: body.emptyText
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeLarge
    }

    StyledText {
        anchors.centerIn: viewLoader
        width: viewLoader.width - Style.spacingL * 2
        visible: body.directory.error !== ""
        text: FileFormat.listingError(body.directory.errorCode)
        color: Style.surfaceVariantText
        font.pixelSize: Style.fontSizeLarge
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    SelectionFooter {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Style.spacingM
        visible: body.showSelectionFooter && body.selection.count > 1
        width: Math.min(implicitWidth, body.width - Style.spacingL * 2)
        count: body.selection.count
        bytes: body.selectedBytes()
        onCleared: body.selection.clear()
    }
}
