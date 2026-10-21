pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Common as DC

Singleton {
    id: root

    property var fileList: []
    property int currentIndex: 0
    readonly property string currentFilePath: fileList.length > 0 && currentIndex >= 0 && currentIndex < fileList.length ? fileList[currentIndex] : ""
    readonly property string currentFileName: {
        if (!currentFilePath) return "";
        const parts = currentFilePath.split("/");
        return parts[parts.length - 1];
    }

    property var currentMeta: ({})
    readonly property real minZoom: 0.25
    readonly property real maxZoom: 30.0
    property real zoom: 1.0
    property real fitScale: 1.0
    property int rotation: 0
    readonly property int normalizedRotation: ((rotation % 360) + 360) % 360
    property bool resettingTransform: false
    property bool flipH: false
    property bool flipV: false
    property var undoStack: []
    property var redoStack: []
    readonly property bool canUndo: undoStack.length > 0
    readonly property bool canRedo: redoStack.length > 0
    property bool isAnimated: false
    property bool isPlaying: true
    property int currentFrame: 0
    property int frameCount: 1
    property bool inspectorOpen: false
    property bool editMode: false
    property bool cropMode: false
    property bool saveMode: false
    property bool isFullscreen: Quickshell.env("DVIEW_FULLSCREEN") === "1"
    property bool uiLocked: false
    property real panX: 0
    property real panY: 0

    // Gallery State
    property bool galleryMode: currentFilePath === ""
    property string galleryTab: "gallery" // "gallery" (Timeline) | "albums"
    property bool settingsOpen: false
    property bool sidebarCollapsed: true
    property bool albumsEditMode: false
    property var _albumsConfigSnapshot: null
    property string selectedCategory: "All"
    property string searchQuery: ""
    property string searchQueryDebounced: ""
    property bool searchActive: false
    property bool searchBarCollapsed: false

    // Process Execution & Navigation Lifecycle Guards
    property int _navToken: 0
    property int _activeListToken: 0
    property int _activeInfoToken: 0

    // Filter & Sort Settings
    property string filterMediaType: "All"
    property string filterLocation: "Anywhere"
    property string filterDateAdded: "All"
    property string filterSortOrder: "Newest first"
    property bool filterFavoritesOnly: false
    property bool filterIncludeHidden: false
    property int galleryZoomLevel: 3

    readonly property bool hasActiveFilters: {
        return (filterMediaType !== "All" && filterMediaType !== "All Items") ||
               (filterDateAdded !== "All" && filterDateAdded !== "Any time") ||
               filterSortOrder !== "Newest first" ||
               filterIncludeHidden;
    }

    function resetFilters() {
        filterMediaType = "All";
        filterLocation = "Anywhere";
        filterDateAdded = "All";
        filterSortOrder = "Newest first";
        filterFavoritesOnly = false;
        filterIncludeHidden = false;
        galleryZoomLevel = 3;
    }

    property var galleryData: null
    property var _rawGalleryData: null

    onGalleryTabChanged: {
        searchBarCollapsed = false;
        if (galleryTab !== "albums" && albumsEditMode) cancelEditAlbums();
    }
    onGalleryModeChanged: {
        if (!galleryMode && albumsEditMode) cancelEditAlbums();
        if (!galleryMode) settingsOpen = false;
    }

    Timer {
        id: searchDebounce
        interval: 180
        repeat: false
        onTriggered: root.searchQueryDebounced = (root.searchQuery || "").toLowerCase().trim()
    }
    onSearchQueryChanged: {
        searchDebounce.restart()
        if (searchQuery !== "") searchBarCollapsed = false
    }
    onSelectedCategoryChanged: searchBarCollapsed = false
    onSearchActiveChanged: {
        if (!searchActive) {
            searchDebounce.stop()
            searchQueryDebounced = ""
        }
    }
    property var galleryFavorites: ({})
    property var gallerySelectedFiles: ({})
    property bool isGalleryLoading: false
    property string previewThumbnail: ""

    readonly property string favFilePath: SettingsData.configDir + "/favorites.json"
    readonly property string albumsFilePath: SettingsData.configDir + "/albums.json"
    readonly property string recentsFilePath: SettingsData.configDir + "/recents.json"

    property var recentImages: []

    property var albumsConfig: ({
        addedFolders: [],
        removedFolders: [],
        quickAccess: null,
        albumOrder: []
    })

    FileView {
        id: albumsFileView
        path: root.albumsFilePath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                const text = albumsFileView.text();
                if (text) {
                    const data = JSON.parse(text);
                    if (data && typeof data === "object") {
                        root.albumsConfig = {
                            addedFolders: Array.isArray(data.addedFolders) ? data.addedFolders : [],
                            removedFolders: Array.isArray(data.removedFolders) ? data.removedFolders : [],
                            quickAccess: Array.isArray(data.quickAccess) ? data.quickAccess : null,
                            albumOrder: Array.isArray(data.albumOrder) ? data.albumOrder : []
                        };
                    }
                }
            } catch (e) {
                console.warn("Failed to parse albums.json:", e);
            }
        }
    }

    Process {
        id: saveAlbumsProc
        running: false
        command: []
    }

    Timer {
        id: saveAlbumsDebounce
        interval: 200
        repeat: false
        onTriggered: {
            if (!saveAlbumsProc.running) {
                saveAlbumsProc.command = [
                    "sh", "-c",
                    'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"',
                    "saveAlbums",
                    albumsFilePath,
                    JSON.stringify(albumsConfig, null, 2)
                ];
                saveAlbumsProc.running = true;
            }
        }
    }

    function saveAlbumsConfig() {
        saveAlbumsDebounce.restart();
    }

    FileView {
        id: favFileView
        path: root.favFilePath
        blockLoading: false
        onLoaded: {
            try {
                const text = favFileView.text();
                if (text) {
                    const data = JSON.parse(text);
                    if (data && typeof data === "object") {
                        root.galleryFavorites = data;
                    }
                }
            } catch (e) {
                console.warn("Failed to parse favorites.json:", e);
            }
        }
    }

    Process {
        id: saveFavProc
        running: false
        command: []
    }

    Timer {
        id: saveFavDebounce
        interval: 200
        repeat: false
        onTriggered: {
            if (!saveFavProc.running) {
                saveFavProc.command = [
                    "sh", "-c",
                    'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"',
                    "saveFav",
                    favFilePath,
                    JSON.stringify(galleryFavorites, null, 2)
                ];
                saveFavProc.running = true;
            }
        }
    }

    function saveFavorites() {
        saveFavDebounce.restart();
    }

    FileView {
        id: recentsFileView
        path: root.recentsFilePath
        blockLoading: false
        printErrors: false
        onLoaded: {
            try {
                const text = recentsFileView.text();
                if (text) {
                    const data = JSON.parse(text);
                    if (Array.isArray(data)) {
                        root.recentImages = data;
                    }
                }
            } catch (e) {
                console.warn("Failed to parse recents.json:", e);
            }
        }
    }

    Process {
        id: saveRecentsProc
        running: false
        command: []
    }

    Timer {
        id: saveRecentsDebounce
        interval: 250
        repeat: false
        onTriggered: {
            if (!saveRecentsProc.running) {
                saveRecentsProc.command = [
                    "sh", "-c",
                    'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"',
                    "saveRecents",
                    recentsFilePath,
                    JSON.stringify(recentImages, null, 2)
                ];
                saveRecentsProc.running = true;
            }
        }
    }

    function saveRecents() {
        saveRecentsDebounce.restart();
    }

    function recordRecentImage(filePath, thumbPath) {
        if (!filePath) return;
        if (root.recentImages && root.recentImages.length > 0 && root.recentImages[0] && root.recentImages[0].path === filePath) {
            return;
        }
        let thumb = thumbPath || "";
        if (!thumb && galleryData && galleryData.allImages) {
            const found = galleryData.allImages.find(img => img.path === filePath);
            if (found && found.thumbnail) {
                thumb = found.thumbnail;
            }
        }
        const name = filePath.split("/").pop() || "";
        const list = (root.recentImages || []).filter(item => item && item.path !== filePath);
        list.unshift({
            path: filePath,
            thumbnail: thumb,
            name: name
        });
        if (list.length > 20) {
            list.length = 20;
        }
        root.recentImages = list;
        saveRecents();
    }

    function clearRecentImages() {
        root.recentImages = [];
        saveRecents();
    }

    function removeRecentImage(path) {
        root.recentImages = (root.recentImages || []).filter(item => item && item.path !== path);
        saveRecents();
    }

    function isAlbumRemoved(albumOrName, folderPath) {
        const rem = (albumsConfig && Array.isArray(albumsConfig.removedFolders)) ? albumsConfig.removedFolders : [];
        if (rem.length === 0) return false;
        const name = typeof albumOrName === "object" ? (albumOrName.name || "") : (albumOrName || "");
        const rawP = typeof albumOrName === "object" ? (albumOrName.path || "") : (folderPath || "");
        const p = rawP.replace(/\/+$/, "");

        for (let i = 0; i < rem.length; i++) {
            const r = (rem[i] || "").replace(/\/+$/, "");
            if (!r) continue;
            if (name !== "" && r === name) return true;
            if (p !== "" && (r === p || p.startsWith(r + "/"))) return true;
        }
        return false;
    }

    function isPathRemoved(filePath, category) {
        const rem = (albumsConfig && Array.isArray(albumsConfig.removedFolders)) ? albumsConfig.removedFolders : [];
        if (rem.length === 0) return false;
        if (category && rem.indexOf(category) !== -1) return true;
        if (!filePath) return false;
        const cleanFile = filePath.replace(/\/+$/, "");
        for (let i = 0; i < rem.length; i++) {
            const r = (rem[i] || "").replace(/\/+$/, "");
            if (!r) continue;
            if (r.startsWith("/")) {
                if (cleanFile === r || cleanFile.startsWith(r + "/")) {
                    return true;
                }
            } else if (category === r) {
                return true;
            }
        }
        return false;
    }

    readonly property var managedAlbums: {
        const raw = (galleryData && galleryData.albums) ? galleryData.albums : [];
        const cfg = albumsConfig || {};
        const qaList = Array.isArray(cfg.quickAccess) ? cfg.quickAccess : null;

        const result = [];
        for (let i = 0; i < raw.length; i++) {
            const a = raw[i];
            if (isAlbumRemoved(a)) continue;
            const inQA = qaList !== null ? (qaList.indexOf(a.name) !== -1) : !!a.isPinned;
            result.push({
                name: a.name,
                path: a.path || "",
                isPinned: inQA,
                isQuickAccess: inQA,
                isFavorites: false,
                totalCount: a.totalCount || 0,
                previews: a.previews || [],
                _lowerName: a._lowerName || (a.name || "").toLowerCase()
            });
        }
        return result;
    }

    readonly property var quickAccessFolderAlbums: {
        const cfg = albumsConfig || {};
        const qaList = Array.isArray(cfg.quickAccess) ? cfg.quickAccess : [];
        const list = managedAlbums.filter(a => a.isQuickAccess);
        list.sort((a, b) => {
            const ia = qaList.indexOf(a.name);
            const ib = qaList.indexOf(b.name);
            if (ia !== -1 && ib !== -1) return ia - ib;
            if (ia !== -1) return -1;
            if (ib !== -1) return 1;
            return (a.name || "").localeCompare(b.name || "");
        });
        return list;
    }

    readonly property var folderAlbums: {
        const cfg = albumsConfig || {};
        const orderList = Array.isArray(cfg.albumOrder) ? cfg.albumOrder : [];
        const list = managedAlbums.filter(a => !a.isQuickAccess);
        list.sort((a, b) => {
            const ia = orderList.indexOf(a.name);
            const ib = orderList.indexOf(b.name);
            if (ia !== -1 && ib !== -1) return ia - ib;
            if (ia !== -1) return -1;
            if (ib !== -1) return 1;
            return (a.name || "").localeCompare(b.name || "");
        });
        return list;
    }

    readonly property bool hasRemovedFolders: {
        const rem = (albumsConfig && Array.isArray(albumsConfig.removedFolders)) ? albumsConfig.removedFolders : [];
        return rem.length > 0;
    }

    readonly property var galleryCategories: {
        const list = ["All"];
        const qa = quickAccessFolderAlbums;
        for (let i = 0; i < qa.length; i++) {
            const name = qa[i].name;
            if (name && list.indexOf(name) === -1) {
                list.push(name);
            }
        }
        if (selectedCategory && selectedCategory !== "All" && selectedCategory !== "Favorites" && list.indexOf(selectedCategory) === -1) {
            list.push(selectedCategory);
        }
        return list;
    }

    function startEditAlbums() {
        _albumsConfigSnapshot = {
            addedFolders: (albumsConfig.addedFolders || []).slice(),
            removedFolders: (albumsConfig.removedFolders || []).slice(),
            quickAccess: Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : quickAccessFolderAlbums.map(a => a.name),
            albumOrder: (albumsConfig.albumOrder || []).slice()
        };
        albumsEditMode = true;
    }

    function confirmEditAlbums() {
        albumsEditMode = false;
        _albumsConfigSnapshot = null;
        saveAlbumsConfig();
        showToast("Saved album layout");
    }

    function cancelEditAlbums() {
        if (_albumsConfigSnapshot) {
            albumsConfig = _albumsConfigSnapshot;
            _albumsConfigSnapshot = null;
            loadGallery();
        }
        albumsEditMode = false;
    }

    function toggleQuickAccess(albumName) {
        if (!albumName || albumName === "Favorites") return;
        const currentQA = quickAccessFolderAlbums.map(a => a.name);
        const idx = currentQA.indexOf(albumName);
        if (idx !== -1) {
            currentQA.splice(idx, 1);
        } else {
            currentQA.push(albumName);
        }
        albumsConfig = {
            addedFolders: (albumsConfig.addedFolders || []).slice(),
            removedFolders: (albumsConfig.removedFolders || []).slice(),
            quickAccess: currentQA,
            albumOrder: (albumsConfig.albumOrder || []).slice()
        };
        if (!albumsEditMode) saveAlbumsConfig();
    }

    function reorderAlbum(sourceName, targetIndexOrName, targetInQuickAccess) {
        if (!sourceName || sourceName === "Favorites") return;
        const qaList = quickAccessFolderAlbums.map(a => a.name);
        const fList = folderAlbums.map(a => a.name);
        const sourceInQA = qaList.indexOf(sourceName) !== -1;

        let toIdx = 0;
        if (typeof targetIndexOrName === "number") {
            toIdx = targetIndexOrName;
        } else if (typeof targetIndexOrName === "string" && targetIndexOrName) {
            toIdx = targetInQuickAccess ? qaList.indexOf(targetIndexOrName) : fList.indexOf(targetIndexOrName);
            if (toIdx === -1) toIdx = targetInQuickAccess ? qaList.length : fList.length;
        } else {
            toIdx = targetInQuickAccess ? qaList.length : fList.length;
        }

        if (targetInQuickAccess) {
            toIdx = Math.max(0, Math.min(qaList.length, toIdx));
            if (sourceInQA) {
                const fromIdx = qaList.indexOf(sourceName);
                if (fromIdx === -1) return;
                if (fromIdx === toIdx || fromIdx === toIdx - 1) return;
                qaList.splice(fromIdx, 1);
                const insertIdx = toIdx > fromIdx ? toIdx - 1 : toIdx;
                qaList.splice(insertIdx, 0, sourceName);
            } else {
                const fIdx = fList.indexOf(sourceName);
                if (fIdx !== -1) fList.splice(fIdx, 1);
                qaList.splice(toIdx, 0, sourceName);
            }
        } else {
            toIdx = Math.max(0, Math.min(fList.length, toIdx));
            if (!sourceInQA) {
                const fromIdx = fList.indexOf(sourceName);
                if (fromIdx === -1) return;
                if (fromIdx === toIdx || fromIdx === toIdx - 1) return;
                fList.splice(fromIdx, 1);
                const insertIdx = toIdx > fromIdx ? toIdx - 1 : toIdx;
                fList.splice(insertIdx, 0, sourceName);
            } else {
                const qIdx = qaList.indexOf(sourceName);
                if (qIdx !== -1) qaList.splice(qIdx, 1);
                const existingFIdx = fList.indexOf(sourceName);
                if (existingFIdx !== -1) fList.splice(existingFIdx, 1);
                fList.splice(toIdx, 0, sourceName);
            }
        }

        albumsConfig = {
            addedFolders: (albumsConfig.addedFolders || []).slice(),
            removedFolders: (albumsConfig.removedFolders || []).slice(),
            quickAccess: qaList,
            albumOrder: fList
        };
        if (!albumsEditMode) saveAlbumsConfig();
    }

    function addAlbumFolder(folderPath) {
        if (!folderPath) return;
        const cleanPath = folderPath.replace(/\/+$/, "");
        if (!cleanPath) return;
        const parts = cleanPath.split("/");
        const folderName = parts[parts.length - 1] || cleanPath;

        const added = (albumsConfig.addedFolders || []).slice();
        if (added.indexOf(cleanPath) === -1) {
            added.push(cleanPath);
        }
        const removed = (albumsConfig.removedFolders || []).filter(item => item !== cleanPath && item !== folderName);
        const order = (albumsConfig.albumOrder || []).slice();
        if (order.indexOf(folderName) === -1) {
            order.push(folderName);
        }
        albumsConfig = {
            addedFolders: added,
            removedFolders: removed,
            quickAccess: Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : null,
            albumOrder: order
        };
        if (_albumsConfigSnapshot) {
            _albumsConfigSnapshot = {
                addedFolders: added.slice(),
                removedFolders: removed.slice(),
                quickAccess: Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : null,
                albumOrder: order.slice()
            };
        }
        saveAlbumsConfig();
        applyGalleryFilters();
        loadGallery();
        showToast("Added folder " + folderName);
    }

    function removeAlbumFolder(album) {
        if (!album || album.isFavorites) return;
        const cleanPath = (album.path || "").replace(/\/+$/, "");
        const folderName = album.name || "";

        const added = (albumsConfig.addedFolders || []).filter(p => p !== cleanPath);
        const removed = (albumsConfig.removedFolders || []).slice();
        if (cleanPath && removed.indexOf(cleanPath) === -1) removed.push(cleanPath);
        if (folderName && removed.indexOf(folderName) === -1) removed.push(folderName);

        let qa = Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : quickAccessFolderAlbums.map(a => a.name);
        qa = qa.filter(n => n !== folderName);

        if (selectedCategory === folderName) {
            selectedCategory = "All";
        }

        albumsConfig = {
            addedFolders: added,
            removedFolders: removed,
            quickAccess: qa,
            albumOrder: (albumsConfig.albumOrder || []).filter(n => n !== folderName)
        };
        if (_albumsConfigSnapshot) {
            _albumsConfigSnapshot = {
                addedFolders: added.slice(),
                removedFolders: removed.slice(),
                quickAccess: qa.slice(),
                albumOrder: (albumsConfig.albumOrder || []).slice()
            };
        }
        saveAlbumsConfig();
        applyGalleryFilters();
        loadGallery();
        showToast("Removed folder " + (folderName || cleanPath));
    }

    function removeAddedFolder(folderPath) {
        if (!folderPath) return;
        const cleanPath = folderPath.replace(/\/+$/, "");
        const parts = cleanPath.split("/");
        const folderName = parts[parts.length - 1] || cleanPath;

        const added = (albumsConfig.addedFolders || []).filter(p => p !== cleanPath);
        const removed = (albumsConfig.removedFolders || []).slice();
        if (cleanPath && removed.indexOf(cleanPath) === -1) removed.push(cleanPath);

        let qa = Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : [];
        qa = qa.filter(n => n !== folderName);

        if (selectedCategory === folderName) {
            selectedCategory = "All";
        }

        albumsConfig = {
            addedFolders: added,
            removedFolders: removed,
            quickAccess: qa,
            albumOrder: (albumsConfig.albumOrder || []).filter(n => n !== folderName)
        };
        if (_albumsConfigSnapshot) {
            _albumsConfigSnapshot = {
                addedFolders: added.slice(),
                removedFolders: removed.slice(),
                quickAccess: qa.slice(),
                albumOrder: (albumsConfig.albumOrder || []).slice()
            };
        }
        saveAlbumsConfig();
        applyGalleryFilters();
        loadGallery();
        showToast("Removed folder " + folderName);
    }

    function restoreRemovedFolders() {
        albumsConfig = {
            addedFolders: (albumsConfig.addedFolders || []).slice(),
            removedFolders: [],
            quickAccess: Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : null,
            albumOrder: (albumsConfig.albumOrder || []).slice()
        };
        if (_albumsConfigSnapshot) {
            _albumsConfigSnapshot = {
                addedFolders: (albumsConfig.addedFolders || []).slice(),
                removedFolders: [],
                quickAccess: Array.isArray(albumsConfig.quickAccess) ? albumsConfig.quickAccess.slice() : null,
                albumOrder: (albumsConfig.albumOrder || []).slice()
            };
        }
        saveAlbumsConfig();
        applyGalleryFilters();
        loadGallery();
        showToast("Restored default folders");
    }

    signal openAddFolderDialogRequested()

    function openAddFolderDialog() {
        openAddFolderDialogRequested();
    }

    readonly property var favoriteImages: {
        if (!galleryData || !galleryData.allImages) return [];
        return galleryData.allImages.filter(img => !!galleryFavorites[img.path] && !isAlbumRemoved(img.category, ""));
    }
    readonly property int favoriteCount: favoriteImages.length

    readonly property var favoritesAlbum: ({
        name: "Favorites",
        path: "",
        isPinned: true,
        isQuickAccess: true,
        isFavorites: true,
        totalCount: root.favoriteCount,
        previews: root.favoriteImages.slice(0, 4).map(img => img.thumbnail || img.path)
    })

    function toggleFavorite(filePath) {
        const favs = Object.assign({}, galleryFavorites);
        if (favs[filePath]) {
            delete favs[filePath];
        } else {
            favs[filePath] = true;
        }
        galleryFavorites = favs;
        saveFavorites();
    }

    function isFavorite(filePath) {
        return !!galleryFavorites[filePath];
    }

    function removeFavorites(paths) {
        if (!paths || paths.length === 0) return;
        const favs = Object.assign({}, galleryFavorites);
        let changed = false;
        for (let i = 0; i < paths.length; i++) {
            if (favs[paths[i]]) {
                delete favs[paths[i]];
                changed = true;
            }
        }
        if (changed) {
            galleryFavorites = favs;
            saveFavorites();
        }
    }

    function toggleSelect(filePath) {
        const sel = Object.assign({}, gallerySelectedFiles);
        if (sel[filePath]) {
            delete sel[filePath];
        } else {
            sel[filePath] = true;
        }
        gallerySelectedFiles = sel;
    }

    function isSelected(filePath) {
        return !!gallerySelectedFiles[filePath];
    }

    readonly property int gallerySelectedCount: Object.keys(gallerySelectedFiles).length
    readonly property var gallerySelectedList: Object.keys(gallerySelectedFiles)
    readonly property bool isAllSelected: {
        if (!galleryData || !galleryData.allImages || galleryData.allImages.length === 0) return false;
        const cat = selectedCategory;
        let count = 0;
        for (let i = 0; i < galleryData.allImages.length; i++) {
            const img = galleryData.allImages[i];
            if (!cat || cat === "All" || img.category === cat) {
                count++;
                if (!gallerySelectedFiles[img.path]) return false;
            }
        }
        return count > 0;
    }

    function clearSelection() {
        gallerySelectedFiles = ({});
    }

    function selectAll() {
        if (!galleryData || !galleryData.allImages) return;
        const cat = selectedCategory;
        const matching = [];
        for (let i = 0; i < galleryData.allImages.length; i++) {
            const img = galleryData.allImages[i];
            if (!cat || cat === "All" || img.category === cat) {
                matching.push(img.path);
            }
        }
        if (matching.length === 0) return;

        // If all matching items are already selected, deselect them
        let allSelected = matching.length <= gallerySelectedCount;
        if (allSelected) {
            for (let i = 0; i < matching.length; i++) {
                if (!gallerySelectedFiles[matching[i]]) {
                    allSelected = false;
                    break;
                }
            }
        }

        if (allSelected) {
            clearSelection();
        } else {
            const sel = {};
            for (let i = 0; i < matching.length; i++) {
                sel[matching[i]] = true;
            }
            gallerySelectedFiles = sel;
        }
    }

    function toggleFavoriteSelected() {
        const list = gallerySelectedList;
        if (list.length === 0) return;
        const favs = Object.assign({}, galleryFavorites);
        // Check if all are already favorite
        let allFav = true;
        for (let i = 0; i < list.length; i++) {
            if (!favs[list[i]]) {
                allFav = false;
                break;
            }
        }
        for (let i = 0; i < list.length; i++) {
            if (allFav) {
                delete favs[list[i]];
            } else {
                favs[list[i]] = true;
            }
        }
        galleryFavorites = favs;
        saveFavorites();
        showToast(allFav ? "Removed from favorites" : `Added ${list.length} to favorites`);
    }

    readonly property var mimeTypes: ({
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "webp": "image/webp",
        "svg": "image/svg+xml",
        "gif": "image/gif",
        "bmp": "image/bmp",
        "avif": "image/avif",
        "heic": "image/heic",
        "heif": "image/heif",
        "jxl": "image/jxl",
        "tif": "image/tiff",
        "tiff": "image/tiff",
        "ico": "image/x-icon"
    })

    function getMimeType(filePath) {
        if (!filePath) return "image/png";
        const lastDot = filePath.lastIndexOf(".");
        const ext = lastDot > 0 ? filePath.substring(lastDot + 1).toLowerCase() : "";
        return mimeTypes[ext] || "image/png";
    }

    function copySingleImageToClipboard(filePath) {
        if (!filePath) return;
        copyProc.command = [
            "sh", "-c",
            'exec dms cl copy -t "$1" < "$2"',
            "copyProc",
            getMimeType(filePath),
            filePath
        ];
        copyProc.running = true;
    }

    function copySelectedFiles() {
        const list = gallerySelectedList;
        if (list.length === 0) return;
        if (list.length === 1) {
            copySingleImageToClipboard(list[0]);
        } else {
            // Copy list of paths separated by newline
            copyPathProc.command = ["dms", "cl", "copy", list.join("\n")];
            copyPathProc.running = true;
        }
        showToast(`Copied ${list.length} item${list.length > 1 ? "s" : ""}`);
    }

    function openSelectedWith() {
        const list = gallerySelectedList;
        if (list.length === 0) return;
        for (let i = 0; i < Math.min(list.length, 10); i++) {
            Quickshell.execDetached(["xdg-open", list[i]]);
        }
    }

    function applyGalleryFilters() {
        if (!_rawGalleryData) return;
        const rawAll = _rawGalleryData.allImages || [];
        const newAll = rawAll.filter(img => !root.isPathRemoved(img.path, img.category));

        const pathSet = {};
        for (let i = 0; i < newAll.length; i++) {
            pathSet[newAll[i].path] = true;
        }

        const newGroups = [];
        const rawGroups = _rawGalleryData.groups || [];
        for (let gi = 0; gi < rawGroups.length; gi++) {
            const g = rawGroups[gi];
            const newImgs = (g.images || []).filter(img => !!pathSet[img.path]);
            if (newImgs.length > 0) {
                newGroups.push({ dateGroup: g.dateGroup, images: newImgs });
            }
        }

        const rawAlbums = _rawGalleryData.albums || [];
        const newAlbums = rawAlbums.filter(alb => !root.isAlbumRemoved(alb.name, alb.path));

        const activeCats = { "All": true };
        for (let i = 0; i < newAll.length; i++) {
            if (newAll[i].category) activeCats[newAll[i].category] = true;
        }
        const newCategories = (_rawGalleryData.categories || ["All"]).filter(cat => !!activeCats[cat]);

        if (selectedCategory !== "All" && selectedCategory !== "Favorites" && !activeCats[selectedCategory]) {
            selectedCategory = "All";
        }

        root.galleryData = {
            allImages: newAll,
            albums: newAlbums,
            groups: newGroups,
            categories: newCategories
        };
    }

    function removePathsFromGalleryData(paths) {
        if (!paths || paths.length === 0) return;
        const pathSet = {};
        for (let i = 0; i < paths.length; i++) pathSet[paths[i]] = true;

        if (_rawGalleryData && _rawGalleryData.allImages) {
            _rawGalleryData.allImages = _rawGalleryData.allImages.filter(img => !pathSet[img.path]);
            if (_rawGalleryData.groups) {
                const newRawGroups = [];
                for (let i = 0; i < _rawGalleryData.groups.length; i++) {
                    const g = _rawGalleryData.groups[i];
                    const newImgs = (g.images || []).filter(img => !pathSet[img.path]);
                    if (newImgs.length > 0) newRawGroups.push({ dateGroup: g.dateGroup, images: newImgs });
                }
                _rawGalleryData.groups = newRawGroups;
            }
        }
        applyGalleryFilters();
    }

    function trashSelected() {
        const list = gallerySelectedList;
        if (list.length === 0) return;
        batchTrashProc.command = ["dms", "trash", "put"].concat(list);
        batchTrashProc.running = true;
    }

    Process {
        id: batchTrashProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                const list = root.gallerySelectedList.slice();
                root.removeFavorites(list);
                root.removePathsFromGalleryData(list);
                for (let i = 0; i < list.length; i++) {
                    root.removeRecentImage(list[i]);
                }
                root.showToast(`Moved ${list.length} to trash`);
                root.clearSelection();
                root.loadGallery();
            } else {
                root.showToast("Failed to delete selected items", true);
            }
        }
    }

    property bool _galleryReloadPending: false

    function loadGallery(dirPath) {
        if (galleryProc.running || isGalleryLoading) {
            _galleryReloadPending = true;
            return;
        }
        _galleryReloadPending = false;
        isGalleryLoading = true;

        const cmd = [dviewBin, "-gallery"];
        const removed = (albumsConfig && Array.isArray(albumsConfig.removedFolders)) ? albumsConfig.removedFolders : [];
        const excludePaths = removed.filter(p => p && p.startsWith("/"));
        if (excludePaths.length > 0) {
            cmd.push("-exclude=" + excludePaths.join(","));
        }

        cmd.push(dirPath || "");

        const added = (albumsConfig && Array.isArray(albumsConfig.addedFolders)) ? albumsConfig.addedFolders : [];
        for (let i = 0; i < added.length; i++) {
            if (added[i] && excludePaths.indexOf(added[i]) === -1) {
                cmd.push(added[i]);
            }
        }
        galleryProc.command = cmd;
        galleryProc.running = true;
    }

    function openImageFromGallery(filePath, thumbPath) {
        _navToken++;
        previewThumbnail = thumbPath || "";
        fileList = [filePath];
        currentIndex = 0;
        galleryMode = false;
        Qt.callLater(() => {
            recordRecentImage(filePath, thumbPath);
        });
        loadDirectoryFor(filePath);
    }

    function backToGallery() {
        _navToken++;
        galleryMode = true;
        editMode = false;
        cropMode = false;
        previewThumbnail = "";
        if (!galleryData && !isGalleryLoading && !galleryProc.running) {
            loadGallery();
        }
    }

    function togglePlayback() {
        isPlaying = !isPlaying;
    }

    function pushHistory() {
        const state = { rotation: root.rotation, flipH: root.flipH, flipV: root.flipV };
        var u = root.undoStack.slice();
        u.push(state);
        root.undoStack = u;
        root.redoStack = [];
    }

    function undoTransform() {
        if (undoStack.length === 0) return;
        const currentState = { rotation: root.rotation, flipH: root.flipH, flipV: root.flipV };
        var r = root.redoStack.slice();
        r.push(currentState);
        root.redoStack = r;

        var u = root.undoStack.slice();
        const prev = u.pop();
        root.undoStack = u;

        root.rotation = prev.rotation;
        root.flipH = prev.flipH;
        root.flipV = prev.flipV;
    }

    function redoTransform() {
        if (redoStack.length === 0) return;
        const currentState = { rotation: root.rotation, flipH: root.flipH, flipV: root.flipV };
        var u = root.undoStack.slice();
        u.push(currentState);
        root.undoStack = u;

        var r = root.redoStack.slice();
        const next = r.pop();
        root.redoStack = r;

        root.rotation = next.rotation;
        root.flipH = next.flipH;
        root.flipV = next.flipV;
    }

    onCurrentFilePathChanged: {
        resetTransform();
        editMode = false;
        cropMode = false;
        if (currentFilePath) {
            galleryMode = false;
            fetchMetadata();
        } else {
            galleryMode = true;
            currentMeta = ({});
            if (!galleryData && !isGalleryLoading && !galleryProc.running) {
                loadGallery();
            }
        }
    }

    Component.onCompleted: {
        const initImg = Quickshell.env("DVIEW_INITIAL_IMAGE");
        if (initImg) {
            _navToken++;
            fileList = [initImg];
            currentIndex = 0;
            galleryMode = false;
            recordRecentImage(initImg, "");
            loadDirectoryFor(initImg);
            fetchMetadata();
        } else {
            galleryMode = true;
            loadGallery();
        }
    }

    readonly property string dviewBin: Quickshell.env("DVIEW_BIN") || "dview"

    function loadDirectoryFor(filePath) {
        _navToken++;
        _activeListToken = _navToken;
        listProc.command = [dviewBin, "-list", filePath];
        listProc.running = true;
    }

    function fetchMetadata() {
        if (!currentFilePath || galleryMode) return;
        _activeInfoToken = _navToken;
        infoProc.command = [dviewBin, "-info", currentFilePath];
        infoProc.running = true;
    }

    Process {
        id: listProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._activeListToken !== root._navToken || !text || text.trim() === "") {
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    if (data && data.files && data.files.length > 0 && root._activeListToken === root._navToken) {
                        root.fileList = data.files;
                        root.currentIndex = data.currentIndex >= 0 && data.currentIndex < data.files.length ? data.currentIndex : 0;
                        root.galleryMode = false;
                    }
                } catch (e) {
                    console.warn("Failed to parse image list JSON:", e);
                }
            }
        }
        onExited: exitCode => {
            if (root._activeListToken !== root._navToken) return;
            if (exitCode !== 0 && root.currentFilePath) {
                const deadPath = root.currentFilePath;
                root.removeRecentImage(deadPath);
                root.showToast("File no longer exists", true);
                root.removeCurrentFromList();
                if (!root.currentFilePath) {
                    root.galleryMode = true;
                }
            }
        }
    }

    Process {
        id: infoProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.galleryMode || root._activeInfoToken !== root._navToken || !text || text.trim() === "") {
                    return;
                }
                try {
                    const data = JSON.parse(text);
                    if (data && !root.galleryMode && root._activeInfoToken === root._navToken) {
                        root.currentMeta = data;
                    }
                } catch (e) {
                    console.warn("Failed to parse metadata JSON:", e);
                }
            }
        }
    }

    Process {
        id: galleryProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                root.isGalleryLoading = false;
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (data) {
                        root._rawGalleryData = data;
                        root.applyGalleryFilters();
                        if (root.recentImages && root.recentImages.length > 0 && data.allImages) {
                            const thumbMap = {};
                            for (let i = 0; i < data.allImages.length; i++) {
                                const img = data.allImages[i];
                                if (img.path && img.thumbnail) {
                                    thumbMap[img.path] = img.thumbnail;
                                }
                            }
                            let updated = false;
                            const list = root.recentImages.map(item => {
                                if (!item.thumbnail && thumbMap[item.path]) {
                                    updated = true;
                                    return { path: item.path, thumbnail: thumbMap[item.path], name: item.name };
                                }
                                return item;
                            });
                            if (updated) {
                                root.recentImages = list;
                                root.saveRecents();
                            }
                        }
                    }
                } catch (e) {
                    console.warn("Failed to parse gallery JSON:", e);
                }
            }
        }
        onExited: exitCode => {
            root.isGalleryLoading = false;
            if (root._galleryReloadPending) {
                root._galleryReloadPending = false;
                root.loadGallery();
            }
        }
    }

        Process {
            id: trashProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("Moved to trash (Ctrl+Z to undo)");
                if (root.lastTrashedPath) {
                    root.removePathsFromGalleryData([root.lastTrashedPath]);
                    root.removeRecentImage(root.lastTrashedPath);
                }
                removeCurrentFromList();
            } else {
                root.showToast("Failed to move image to trash", true);
            }
        }
    }

    Process {
        id: restoreProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const restored = text.trim();
                if (restored.length > 0) {
                    root.showToast("Restored from trash");
                    root.recordRecentImage(restored, "");
                    root.loadDirectoryFor(restored);
                    if (root.galleryMode) {
                        root.loadGallery();
                    }
                } else {
                    root.showToast("Nothing to undo", true);
                }
            }
        }
    }

    Process {
        id: copyProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("Image copied to clipboard");
            } else {
                root.showToast("Failed to copy image to clipboard", true);
            }
        }
    }

    Process {
        id: copyPathProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("File path copied to clipboard");
            } else {
                root.showToast("Failed to copy path", true);
            }
        }
    }

    Process {
        id: wallpaperProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("Wallpaper set");
            } else {
                root.showToast("Failed to set wallpaper", true);
            }
        }
    }

    Process {
        id: printProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("Sent to printer");
            } else {
                root.showToast("Print failed — no printer available", true);
            }
        }
    }

    Process {
        id: annotateProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.showToast("Failed to launch Quick Capture", true);
            }
        }
    }

    function nextImage() {
        if (fileList.length <= 1) return;
        currentIndex = (currentIndex + 1) % fileList.length;
    }

    function prevImage() {
        if (fileList.length <= 1) return;
        currentIndex = (currentIndex - 1 + fileList.length) % fileList.length;
    }

    function jumpToIndex(idx) {
        if (idx >= 0 && idx < fileList.length) {
            currentIndex = idx;
        }
    }

    function rotateClockwise() {
        pushHistory();
        rotation += 90;
    }

    function rotateCounterClockwise() {
        pushHistory();
        rotation -= 90;
    }

    function toggleFlipHorizontal() {
        pushHistory();
        flipH = !flipH;
    }

    function toggleFlipVertical() {
        pushHistory();
        flipV = !flipV;
    }

    signal openFileDialogRequested()

    function openFileDialog() {
        openFileDialogRequested();
    }

    function zoomAt(factor, cursorX, cursorY, vpWidth, vpHeight, topInset, bottomInset) {
        const oldZoom = zoom;
        const newZoom = Math.max(minZoom, Math.min(maxZoom, oldZoom * factor));
        if (Math.abs(newZoom - oldZoom) < 0.0001) return;

        // Center of viewport relative to cursor
        const cx = cursorX - vpWidth / 2;
        const cy = cursorY - (vpHeight + (topInset || 0) - (bottomInset || 0)) / 2;

        // Shift pan so that the image pixel under cursor stays under cursor
        panX = (panX - cx) * (newZoom / oldZoom) + cx;
        panY = (panY - cy) * (newZoom / oldZoom) + cy;
        zoom = newZoom;
    }

    function zoomIn() {
        zoom = Math.min(zoom * 1.25, maxZoom);
    }

    function zoomOut() {
        zoom = Math.max(zoom / 1.25, minZoom);
    }

    function fitToWindow() {
        zoom = 1.0;
        panX = 0;
        panY = 0;
    }

    function actualSize() {
        panX = 0;
        panY = 0;
        if (fitScale > 0) {
            zoom = 1.0 / fitScale;
        } else {
            zoom = 1.0;
        }
    }

    function resetZoom() {
        fitToWindow();
    }

    function resetTransform() {
        resettingTransform = true;
        undoStack = [];
        redoStack = [];
        zoom = 1.0;
        rotation = 0;
        flipH = false;
        flipV = false;
        panX = 0;
        panY = 0;
        resettingTransform = false;
    }

    function closeOtherOverlays(except) {
        if (except !== "inspector") inspectorOpen = false;
        if (except !== "edit" && except !== "crop") {
            editMode = false;
            cropMode = false;
        }
        if (except !== "save") saveMode = false;
    }

    function toggleInspector() {
        inspectorOpen = !inspectorOpen;
        if (inspectorOpen) closeOtherOverlays("inspector");
    }

    function toggleFullscreen() {
        isFullscreen = !isFullscreen;
    }

    function toggleLockUI() {
        uiLocked = !uiLocked;
        if (uiLocked) closeOtherOverlays("none");
    }

    function copyToClipboard() {
        if (!currentFilePath) return;
        copySingleImageToClipboard(currentFilePath);
    }

    function copyPathToClipboard() {
        if (!currentFilePath) return;
        copyPathProc.command = ["dms", "cl", "copy", currentFilePath];
        copyPathProc.running = true;
    }

    function openContainingFolder() {
        if (!currentFilePath) return;
        const dir = currentMeta.directory || currentFilePath.substring(0, currentFilePath.lastIndexOf("/"));
        Quickshell.execDetached(["xdg-open", dir]);
    }

    function setAsWallpaper() {
        if (!currentFilePath) return;
        wallpaperProc.command = ["dms", "ipc", "call", "wallpaper", "set", currentFilePath];
        wallpaperProc.running = true;
    }

    function printImage() {
        if (!currentFilePath) return;
        printProc.command = ["lp", currentFilePath];
        printProc.running = true;
    }

    function annotateImage() {
        if (!currentFilePath) return;
        annotateProc.command = ["dms", "ipc", "call", "quickCapture", "openImage", currentFilePath, "edit"];
        annotateProc.running = true;
    }

    function toggleEditMode() {
        if (!currentFilePath) return;
        editMode = !editMode;
        if (!editMode && cropMode) {
            cropMode = false;
        }
        if (editMode) closeOtherOverlays("edit");
    }

    function toggleCropMode() {
        if (!currentFilePath) return;
        cropMode = !cropMode;
        if (cropMode) {
            editMode = true;
            closeOtherOverlays("crop");
        }
    }

    function openSaveDialog() {
        if (!currentFilePath) return;
        saveMode = !saveMode;
        if (saveMode) closeOtherOverlays("save");
    }

    property int reloadToken: 0
    property string lastCropCopyDest: ""

    // Called by CropOverlay to overwrite original image
    function executeCrop(x, y, w, h) {
        cropMode = false;
        cropProc.command = [
            "magick", currentFilePath,
            "-crop", w + "x" + h + "+" + x + "+" + y,
            "+repage", currentFilePath
        ];
        cropProc.running = true;
    }

    // Called by CropOverlay to save copy in same directory with _crop suffix
    function saveCropCopy(x, y, w, h) {
        cropMode = false;
        if (!currentFilePath) return;

        const lastDot = currentFilePath.lastIndexOf(".");
        let dest = "";
        if (lastDot > 0) {
            dest = currentFilePath.substring(0, lastDot) + "_crop" + currentFilePath.substring(lastDot);
        } else {
            dest = currentFilePath + "_crop";
        }

        lastCropCopyDest = dest;
        cropCopyProc.command = [
            "magick", currentFilePath,
            "-crop", w + "x" + h + "+" + x + "+" + y,
            "+repage", dest
        ];
        cropCopyProc.running = true;
    }

    Process {
        id: cropCopyProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                const fileName = root.lastCropCopyDest.split("/").pop();
                root.showToast("Saved copy as " + fileName);
                root.loadDirectoryFor(root.lastCropCopyDest);
            } else {
                root.showToast("Failed to save crop copy", true);
            }
        }
    }

    // Called by CropOverlay to copy cropped image to clipboard without saving a file
    function copyCropToClipboard(x, y, w, h) {
        cropMode = false;
        if (!currentFilePath) return;

        const cropGeom = `${Math.round(w)}x${Math.round(h)}+${Math.round(x)}+${Math.round(y)}`;
        copyCropProc.command = [
            "sh", "-c",
            'exec magick "$1" -crop "$2" +repage png:- | dms cl copy -t image/png',
            "copyCropProc",
            currentFilePath,
            cropGeom
        ];
        copyCropProc.running = true;
    }

    Process {
        id: copyCropProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("Cropped image copied to clipboard");
            } else {
                root.showToast("Failed to copy to clipboard", true);
            }
        }
    }

    Process {
        id: cropProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.reloadToken++;
                root.fetchMetadata();
                root.showToast("Image cropped and saved");
            } else {
                root.showToast("Crop failed", true);
            }
        }
    }

    function showToast(message, isError) {
        const method = isError ? "error" : "info";
        Quickshell.execDetached([
            "dms", "ipc", "call", "toast", method, message
        ]);
    }

    property string lastTrashedPath: ""

    function moveToTrash() {
        if (!currentFilePath) return;
        lastTrashedPath = currentFilePath;
        removeFavorites([currentFilePath]);
        removeRecentImage(currentFilePath);
        trashProc.command = ["dms", "trash", "put", currentFilePath];
        trashProc.running = true;
    }

    function undoTrash() {
        restoreProc.command = lastTrashedPath ? [dviewBin, "-restore", lastTrashedPath] : [dviewBin, "-restore"];
        restoreProc.running = true;
    }

    function removeCurrentFromList() {
        const list = root.fileList.slice();
        list.splice(root.currentIndex, 1);
        root.fileList = list;
        if (root.currentIndex >= list.length) {
            root.currentIndex = Math.max(0, list.length - 1);
        }
    }
}
