pragma ComponentBehavior: Bound

import QtQuick
import qs.DCommon.Common

QtObject {
    id: pool

    property var backend: Host.files
    property string activePath: ""
    property var heldPaths: []
    property bool includeHidden: false
    property var filters: []
    property string sortKey: "name"
    property bool sortDesc: false
    property bool dirsFirst: true
    property string nameFilter: ""
    property bool thumbnailsEnabled: true
    property real thumbnailSizeLimit: -1
    property bool networkThumbnails: true

    property var active: null
    property var _models: ({})

    readonly property DirectoryModel empty: DirectoryModel {
        backend: pool.backend
    }

    readonly property Component _modelComponent: Component {
        DirectoryModel {
            backend: pool.backend
            includeHidden: pool.includeHidden
            filters: pool.filters
            sortKey: pool.sortKey
            sortDesc: pool.sortDesc
            dirsFirst: pool.dirsFirst
            nameFilter: path === pool.activePath ? pool.nameFilter : ""
            thumbnailsEnabled: pool.thumbnailsEnabled
            thumbnailSizeLimit: pool.thumbnailSizeLimit
            networkThumbnails: pool.networkThumbnails
            onGone: pool.forget(path)
        }
    }

    readonly property Timer _sweep: Timer {
        interval: 0
        onTriggered: pool._sweepModels()
    }

    function modelFor(path) {
        const existing = _models[path];
        if (existing)
            return existing;
        const created = _modelComponent.createObject(pool, {
            "path": path
        });
        const next = Object.assign({}, _models);
        next[path] = created;
        _models = next;
        _sweep.restart();
        return created;
    }

    function forget(path) {
        const model = _models[path];
        if (!model || path === activePath)
            return;
        const next = Object.assign({}, _models);
        delete next[path];
        _models = next;
        model.destroy();
    }

    function has(path) {
        return _models[path] !== undefined;
    }

    function repageAll() {
        for (const path in _models)
            _models[path].repage();
    }

    function _sync() {
        active = activePath === "" ? empty : modelFor(activePath);
        _sweep.restart();
    }

    function _sweepModels() {
        const keep = ({});
        keep[activePath] = true;
        for (const path of heldPaths)
            keep[path] = true;
        const next = ({});
        let changed = false;
        for (const path in _models) {
            if (keep[path] === true) {
                next[path] = _models[path];
                continue;
            }
            _models[path].destroy();
            changed = true;
        }
        if (changed)
            _models = next;
    }

    onActivePathChanged: _sync()
    onHeldPathsChanged: _sweep.restart()
    Component.onCompleted: _sync()
}
