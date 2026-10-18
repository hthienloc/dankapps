pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

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
    property bool inspectorOpen: false
    property bool isFullscreen: Quickshell.env("DPLAY_FULLSCREEN") === "1"
    property bool uiLocked: false
    property string lastTrashedPath: ""
    
    // Playback state bindings (driven by VideoCanvas / MediaPlayer)
    property bool isPlaying: false
    property real position: 0 // in ms
    property real duration: 0 // in ms
    property real volume: 1.0
    property bool isMuted: false
    property real playbackRate: 1.0

    readonly property string dplayBin: Quickshell.env("DPLAY_BIN") || "dplay"

    onInspectorOpenChanged: {
        if (inspectorOpen && currentFilePath && (!currentMeta || currentMeta.filePath !== currentFilePath)) {
            fetchMetadata();
        }
    }

    onCurrentFilePathChanged: {
        currentMeta = ({});
        if (inspectorOpen && currentFilePath) {
            fetchMetadata();
        }
    }

    Component.onCompleted: {
        const initVid = Quickshell.env("DPLAY_INITIAL_VIDEO");
        if (initVid) {
            root.fileList = [initVid];
            root.currentIndex = 0;
            loadDirectoryFor(initVid);
        }
    }

    function loadDirectoryFor(filePath) {
        listProc.command = [dplayBin, "-list", filePath];
        listProc.running = true;
    }

    function fetchMetadata() {
        if (!currentFilePath) return;
        infoProc.command = [dplayBin, "-info", currentFilePath];
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
                        const current = root.currentFilePath;
                        root.fileList = data.files;
                        let foundIdx = -1;
                        if (current) {
                            foundIdx = data.files.indexOf(current);
                        }
                        if (foundIdx >= 0) {
                            root.currentIndex = foundIdx;
                        } else if (data.currentIndex >= 0 && data.currentIndex < data.files.length) {
                            root.currentIndex = data.currentIndex;
                        } else {
                            root.currentIndex = 0;
                        }
                    }
                } catch (e) {
                    console.warn("Failed to parse video list JSON:", e);
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

    signal openFileDialogRequested()

    Process {
        id: trashProc
        running: false
        command: []
        onExited: exitCode => {
            if (exitCode === 0) {
                root.showToast("Moved video to trash (U to undo)");
                removeCurrentFromList();
            } else {
                root.showToast("Failed to move video to trash", true);
            }
        }
    }

    Process {
        id: restoreProc
        running: false
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                const restoredPath = text.trim();
                if (restoredPath.length > 0) {
                    root.showToast("Restored video: " + restoredPath.split("/").pop());
                    root.loadDirectoryFor(restoredPath);
                } else {
                    root.showToast("No video to restore", true);
                }
            }
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.showToast("Failed to restore video", true);
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

    function openFileDialog() {
        openFileDialogRequested();
    }

    function toggleLockUI() {
        uiLocked = !uiLocked;
        if (uiLocked) {
            inspectorOpen = false;
        }
    }

    function nextVideo() {
        if (fileList.length <= 1) return;
        currentIndex = (currentIndex + 1) % fileList.length;
    }

    function prevVideo() {
        if (fileList.length <= 1) return;
        currentIndex = (currentIndex - 1 + fileList.length) % fileList.length;
    }

    function togglePlay() {
        isPlaying = !isPlaying;
    }

    function toggleMute() {
        isMuted = !isMuted;
    }

    function setVolume(v) {
        volume = Math.max(0.0, Math.min(1.0, v));
        if (volume > 0 && isMuted) {
            isMuted = false;
        }
    }

    function seekRelative(deltaMs) {
        const target = Math.max(0, Math.min(duration, position + deltaMs));
        position = target;
    }

    function toggleInspector() {
        inspectorOpen = !inspectorOpen;
    }

    function toggleFullscreen() {
        isFullscreen = !isFullscreen;
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

    function showToast(message, isError) {
        const method = isError ? "error" : "info";
        Quickshell.execDetached([
            "dms", "ipc", "call", "toast", method, message
        ]);
    }

    function moveToTrash() {
        if (!currentFilePath) return;
        lastTrashedPath = currentFilePath;
        trashProc.command = ["gio", "trash", currentFilePath];
        trashProc.running = true;
    }

    function undoTrash() {
        restoreProc.command = lastTrashedPath ? [dplayBin, "-restore", lastTrashedPath] : [dplayBin, "-restore"];
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

    function formatTime(ms) {
        if (isNaN(ms) || ms < 0) return "0:00";
        const totalSecs = Math.floor(ms / 1000);
        const hours = Math.floor(totalSecs / 3600);
        const minutes = Math.floor((totalSecs % 3600) / 60);
        const seconds = totalSecs % 60;

        const secStr = seconds < 10 ? "0" + seconds : "" + seconds;
        if (hours > 0) {
            const minStr = minutes < 10 ? "0" + minutes : "" + minutes;
            return hours + ":" + minStr + ":" + secStr;
        }
        return minutes + ":" + secStr;
    }
}
