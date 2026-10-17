pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.DCommon.Common as DCommon

Singleton {
    id: root

    readonly property bool connected: requestSocket.linkUp && subscribeSocket.linkUp && hasFilesCap
    property bool hasFilesCap: false
    property string socketPath: ""
    property var userDirs: []
    property int refCount: 0

    readonly property var capabilities: ({
        "mkdir": true,
        "rename": true,
        "trash": true,
        "search": true
    })

    signal watchEvent(var data)

    property var pendingRequests: ({})
    property int requestIdCounter: 0

    function addRef() {
        refCount++;
    }

    function removeRef() {
        refCount = Math.max(0, refCount - 1);
    }

    Process {
        id: socketFinder
        command: [
            "sh", "-c",
            'if [ -n "$DMS_SOCKET" ] && [ -S "$DMS_SOCKET" ]; then echo "$DMS_SOCKET"; exit 0; fi; for s in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/danklinux*.sock; do if [ -S "$s" ]; then echo "$s"; exit 0; fi; done'
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path.length > 0) {
                    root.socketPath = path;
                    requestSocket.connected = true;
                    subscribeSocket.connected = true;
                }
            }
        }
    }

    Component.onCompleted: {
        socketFinder.running = true;
    }

    onConnectedChanged: {
        if (connected) {
            refreshUserDirs();
        }
    }

    DCommon.DSocket {
        id: requestSocket
        path: root.socketPath
        connected: false

        onConnectionStateChanged: {
            if (!linkUp) {
                root.hasFilesCap = false;
                root.failPendingRequests();
            }
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0)
                    return;

                let msg;
                try {
                    msg = JSON.parse(line);
                } catch (e) {
                    return;
                }

                if (msg.capabilities && Array.isArray(msg.capabilities)) {
                    if (msg.capabilities.includes("files")) {
                        root.hasFilesCap = true;
                    }
                    return;
                }

                if (msg.id !== undefined && root.pendingRequests[msg.id]) {
                    const cb = root.pendingRequests[msg.id];
                    delete root.pendingRequests[msg.id];
                    cb(msg);
                }
            }
        }
    }

    DCommon.DSocket {
        id: subscribeSocket
        path: root.socketPath
        connected: false

        onConnectionStateChanged: {
            if (linkUp) {
                sendSubscribeRequest();
            }
        }

        parser: SplitParser {
            onRead: line => {
                if (!line || line.length === 0)
                    return;

                let msg;
                try {
                    msg = JSON.parse(line);
                } catch (e) {
                    return;
                }

                if (msg.result?.service === "files" && msg.result?.data) {
                    root.watchEvent(msg.result.data);
                } else if (msg.event === "files" && msg.data) {
                    root.watchEvent(msg.data);
                }
            }
        }
    }

    function sendSubscribeRequest() {
        subscribeSocket.send({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "subscribe",
            "params": {
                "services": ["files"]
            }
        });
    }

    function failPendingRequests() {
        const cbs = pendingRequests;
        pendingRequests = ({});
        for (const id in cbs) {
            cbs[id]({ "error": "Disconnected" });
        }
    }

    function sendRequest(method, params, callback) {
        if (!requestSocket.linkUp) {
            if (callback)
                callback({ "error": "Not connected" });
            return;
        }
        const id = ++requestIdCounter;
        if (callback) {
            pendingRequests[id] = callback;
        }
        requestSocket.send({
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params || {}
        });
    }

    function refreshUserDirs() {
        _send("files.userDirs", null, result => {
            if (result.error)
                return;
            root.userDirs = result.dirs || [];
        });
    }

    function watch(path, options, callback) {
        _send("files.watch", Object.assign({
            "path": path
        }, _options(options)), callback);
    }

    function page(watchId, options, callback) {
        _send("files.list", Object.assign({
            "watchId": watchId
        }, _options(options)), callback);
    }

    function unwatch(watchId) {
        if (!watchId)
            return;
        _send("files.unwatch", { "watchId": watchId }, null);
    }

    function stat(path, callback) {
        _send("files.stat", { "path": path }, callback);
    }

    function count(paths, includeHidden, callback) {
        _send("files.count", {
            "paths": paths,
            "includeHidden": includeHidden === true
        }, callback);
    }

    function thumbnails(paths, size, watchId, callback) {
        const params = {
            "paths": paths,
            "size": size || "normal"
        };
        if (watchId)
            params.watchId = watchId;
        _send("files.thumbnail", params, callback);
    }

    function mkdir(path, callback) {
        _send("files.mkdir", { "path": path }, callback);
    }

    function rename(path, name, callback) {
        _send("files.rename", {
            "path": path,
            "name": name
        }, callback);
    }

    function trash(paths, callback) {
        _send("files.trash", { "paths": paths }, callback);
    }

    function list(path, options, callback) {
        _send("files.list", Object.assign({
            "path": path
        }, _options(options)), callback);
    }

    function preview(path, maxBytes, callback) {
        _send("files.preview", {
            "path": path,
            "maxBytes": maxBytes || 8192
        }, callback);
    }

    function imageSize(path, callback) {
        _send("files.imageSize", { "path": path }, callback);
    }

    function _options(options) {
        const opts = options || {};
        const params = {};
        if (opts.includeHidden !== undefined)
            params.includeHidden = opts.includeHidden;
        if (opts.filters !== undefined)
            params.filters = opts.filters;
        if (opts.sortKey)
            params.sort = opts.sortKey;
        if (opts.sortDesc !== undefined)
            params.desc = opts.sortDesc;
        if (opts.dirsFirst !== undefined)
            params.dirsFirst = opts.dirsFirst;
        if (opts.limit)
            params.limit = opts.limit;
        if (opts.cursor)
            params.cursor = opts.cursor;
        return params;
    }

    function _send(method, params, callback) {
        sendRequest(method, params, response => {
            if (!callback)
                return;
            if (response.error) {
                callback({
                    "error": response.error,
                    "code": response.code || ""
                });
                return;
            }
            callback(response.result || {});
        });
    }
}
