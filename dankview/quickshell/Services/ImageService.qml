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
    property string galleryTab: "gallery" // "gallery" | "albums"
    property string selectedCategory: "All"
    property string searchQuery: ""
    property string searchQueryDebounced: ""
    property bool searchActive: false
    property var galleryData: null

    Timer {
        id: searchDebounce
        interval: 180
        repeat: false
        onTriggered: root.searchQueryDebounced = (root.searchQuery || "").toLowerCase().trim()
    }
    onSearchQueryChanged: searchDebounce.restart()
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

    function saveFavorites() {
        saveFavProc.command = [
            "sh", "-c",
            'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"',
            "saveFav",
            favFilePath,
            JSON.stringify(galleryFavorites, null, 2)
        ];
        saveFavProc.running = true;
    }

    readonly property var galleryCategories: {
        const raw = (galleryData && galleryData.categories) ? galleryData.categories : ["All"];
        const list = [];
        for (let i = 0; i < raw.length; i++) {
            list.push(raw[i]);
            if (raw[i] === "All") {
                list.push("Favorites");
            }
        }
        if (list.indexOf("Favorites") === -1) {
            list.push("Favorites");
        }
        return list;
    }

    readonly property var favoriteImages: {
        if (!galleryData || !galleryData.allImages) return [];
        return galleryData.allImages.filter(img => !!galleryFavorites[img.path]);
    }
    readonly property int favoriteCount: favoriteImages.length

    readonly property var favoritesAlbum: ({
        name: "Favorites",
        path: "",
        isPinned: true,
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

    function removePathsFromGalleryData(paths) {
        if (!galleryData || !paths || paths.length === 0) return;
        const pathSet = {};
        for (let i = 0; i < paths.length; i++) pathSet[paths[i]] = true;

        const newAll = (galleryData.allImages || []).filter(img => !pathSet[img.path]);
        const newGroups = [];
        const oldGroups = galleryData.groups || [];
        for (let gi = 0; gi < oldGroups.length; gi++) {
            const g = oldGroups[gi];
            const newImgs = (g.images || []).filter(img => !pathSet[img.path]);
            if (newImgs.length > 0) {
                newGroups.push({ dateGroup: g.dateGroup, images: newImgs });
            }
        }
        const activeCats = { "All": true };
        for (let i = 0; i < newAll.length; i++) {
            if (newAll[i].category) activeCats[newAll[i].category] = true;
        }
        const newCategories = (galleryData.categories || ["All"]).filter(cat => !!activeCats[cat]);
        if (selectedCategory !== "All" && selectedCategory !== "Favorites" && !activeCats[selectedCategory]) {
            selectedCategory = "All";
        }
        galleryData = {
            allImages: newAll,
            albums: galleryData.albums,
            groups: newGroups,
            categories: newCategories
        };
    }

    function trashSelected() {
        const list = gallerySelectedList;
        if (list.length === 0) return;
        batchTrashProc.command = ["gio", "trash"].concat(list);
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
                root.showToast(`Moved ${list.length} to trash`);
                root.clearSelection();
                root.loadGallery();
            } else {
                root.showToast("Failed to delete selected items", true);
            }
        }
    }

    function loadGallery(dirPath) {
        isGalleryLoading = true;
        const cmd = [dviewBin, "-gallery"];
        if (dirPath) cmd.push(dirPath);
        galleryProc.command = cmd;
        galleryProc.running = true;
    }

    function openImageFromGallery(filePath, thumbPath) {
        previewThumbnail = thumbPath || "";
        fileList = [filePath];
        currentIndex = 0;
        galleryMode = false;
        loadDirectoryFor(filePath);
    }

    function backToGallery() {
        galleryMode = true;
        editMode = false;
        cropMode = false;
        previewThumbnail = "";
        if (!galleryData) {
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
            loadGallery();
        }
    }

    Component.onCompleted: {
        const initImg = Quickshell.env("DVIEW_INITIAL_IMAGE");
        if (initImg) {
            loadDirectoryFor(initImg);
            loadGallery();
        } else {
            loadGallery();
        }
    }

    readonly property string dviewBin: Quickshell.env("DVIEW_BIN") || "dview"

    function loadDirectoryFor(filePath) {
        listProc.command = [dviewBin, "-list", filePath];
        listProc.running = true;
    }

    function fetchMetadata() {
        if (!currentFilePath) return;
        infoProc.command = [dviewBin, "-info", currentFilePath];
        infoProc.running = true;
    }

    Process {
        id: listProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (data && data.files && data.files.length > 0) {
                        root.fileList = data.files;
                        root.currentIndex = data.currentIndex >= 0 && data.currentIndex < data.files.length ? data.currentIndex : 0;
                    }
                } catch (e) {
                    console.warn("Failed to parse image list JSON:", e);
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
                try {
                    const data = JSON.parse(text);
                    if (data) {
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
                    try {
                        const data = JSON.parse(text);
                        if (data) {
                            // Precompute lowercased fields for fast search (avoid per-keystroke toLowerCase)
                            if (data.allImages) {
                                for (let i = 0; i < data.allImages.length; i++) {
                                    const img = data.allImages[i]
                                    img._lowerName = (img.name || "").toLowerCase()
                                    img._lowerPath = (img.path || "").toLowerCase()
                                    img._lowerCategory = (img.category || "").toLowerCase()
                                }
                            }
                            if (data.albums) {
                                for (let i = 0; i < data.albums.length; i++) {
                                    const a = data.albums[i]
                                    a._lowerName = (a.name || "").toLowerCase()
                                }
                            }
                            if (data.groups) {
                                for (let gi = 0; gi < data.groups.length; gi++) {
                                    const g = data.groups[gi]
                                    if (g.images) {
                                        for (let ii = 0; ii < g.images.length; ii++) {
                                            const img = g.images[ii]
                                            if (!img._lowerName) img._lowerName = (img.name || "").toLowerCase()
                                            if (!img._lowerPath) img._lowerPath = (img.path || "").toLowerCase()
                                        }
                                    }
                                }
                            }
                            root.galleryData = data;
                        }
                    } catch (e) {
                        console.warn("Failed to parse gallery JSON:", e);
                    }
                }
            }
            onExited: exitCode => {
                root.isGalleryLoading = false;
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
                }
                removeCurrentFromList();
                if (root.currentFilePath) {
                    root.loadGallery();
                }
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
                    root.loadDirectoryFor(restored);
                    root.loadGallery();
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

    function zoomAt(factor, cursorX, cursorY, vpWidth, vpHeight) {
        const oldZoom = zoom;
        const newZoom = Math.max(minZoom, Math.min(maxZoom, oldZoom * factor));
        if (Math.abs(newZoom - oldZoom) < 0.0001) return;

        // Center of viewport relative to cursor
        const cx = cursorX - vpWidth / 2;
        const cy = cursorY - vpHeight / 2;

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
        trashProc.command = ["gio", "trash", currentFilePath];
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
