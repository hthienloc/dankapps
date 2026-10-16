pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common

// A results list with the DirectoryModel surface FileViewBody reads, fed by
// Host.files.search instead of a watch. Results arrive in batches and are
// appended in daemon order; nothing re-sorts.
QtObject {
    id: root

    property var backend: Host.files
    property string rootPath: ""
    property string query: ""
    property var options: ({})
    property string thumbnailSize: "normal"
    property bool thumbnailsEnabled: true
    property real thumbnailSizeLimit: -1

    property bool active: false
    property bool loading: false
    property string error: ""
    property string errorCode: ""
    property bool truncated: false
    property int unreadable: 0
    property int total: 0
    property int limit: 0
    property string searchId: ""

    readonly property string path: rootPath
    readonly property bool available: backend?.connected === true && typeof backend?.search === "function"
    readonly property ListModel entries: ListModel {}
    readonly property int count: entries.count
    readonly property bool hasMore: false
    readonly property bool pollOnFocus: false
    readonly property string watchId: ""

    property int _firstVisible: -1
    property int _lastVisible: -1
    property var _token: null
    property var _pending: []

    signal listed
    signal pathReset
    signal gone
    signal finished

    readonly property Connections _backendLink: Connections {
        target: root.backend
        ignoreUnknownSignals: true

        function onSearchEvent(data) {
            root._onEvent(data);
        }

        function onConnectedChanged() {
            if (!root.backend.connected && root.loading)
                root._fail("UNAVAILABLE", "file service unavailable");
        }
    }

    Component.onDestruction: cancel()

    function start() {
        cancel();
        entries.clear();
        total = 0;
        truncated = false;
        unreadable = 0;
        error = "";
        errorCode = "";
        active = true;
        pathReset();
        if (rootPath === "")
            return;
        if (!available) {
            _fail("UNAVAILABLE", "file service unavailable");
            return;
        }

        const token = {
            "stale": false
        };
        _token = token;
        _pending = [];
        loading = true;
        backend.search(rootPath, query, options, result => {
            if (token.stale) {
                if (result.searchId)
                    backend.cancelSearch(result.searchId);
                return;
            }
            if (result.error) {
                _fail(result.code || "", result.error);
                return;
            }
            searchId = result.searchId || "";
            limit = result.limit || 0;
            const buffered = _pending;
            _pending = [];
            for (const event of buffered)
                _onEvent(event);
        });
    }

    function cancel() {
        if (_token)
            _token.stale = true;
        _token = null;
        _pending = [];
        if (searchId !== "" && backend)
            backend.cancelSearch(searchId);
        searchId = "";
        loading = false;
    }

    function clear() {
        cancel();
        active = false;
        entries.clear();
        total = 0;
        truncated = false;
        error = "";
        errorCode = "";
        pathReset();
    }

    function refresh() {
        if (active)
            start();
    }

    function loadMore() {
    }

    function indexOfName(name) {
        for (let i = 0; i < entries.count; i++) {
            if (entries.get(i).name === name)
                return i;
        }
        return -1;
    }

    function indexOfPath(target) {
        for (let i = 0; i < entries.count; i++) {
            if (entries.get(i).path === target)
                return i;
        }
        return -1;
    }

    function requestThumbnails(first, last) {
        if (first < 0 || last < first || !thumbnailsEnabled || !available)
            return;
        _firstVisible = first;
        _lastVisible = last;
        const paths = [];
        for (let i = first; i <= Math.min(last, entries.count - 1); i++) {
            const entry = entries.get(i);
            if (!entry.thumbnailable || entry.thumbnail !== "")
                continue;
            if (thumbnailSizeLimit >= 0 && entry.size > thumbnailSizeLimit)
                continue;
            paths.push(entry.path);
        }
        if (paths.length === 0)
            return;
        backend.thumbnails(paths, thumbnailSize, "", result => {
            if (result.error)
                return;
            for (const item of result.results || []) {
                if (!item.thumbnail)
                    continue;
                const index = indexOfPath(item.path);
                if (index >= 0)
                    entries.setProperty(index, "thumbnail", item.thumbnail);
            }
        });
    }

    function _fail(code, message) {
        cancel();
        error = message;
        errorCode = code;
    }

    function _onEvent(data) {
        if (searchId === "" && _token !== null) {
            _pending.push(data);
            return;
        }
        if (data.searchId !== searchId)
            return;
        switch (data.kind) {
        case "results":
            entries.append(Array.from(data.entries || []));
            total = data.count || entries.count;
            listed();
            break;
        case "done":
            total = data.count || entries.count;
            truncated = data.truncated === true;
            unreadable = data.unreadable || 0;
            searchId = "";
            _token = null;
            loading = false;
            listed();
            finished();
            break;
        }
    }
}
