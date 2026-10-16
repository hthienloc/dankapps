import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Common
import qs.DCommon.FileBrowser
import qs.Services as Stub

ShellRoot {
    id: root

    property var accepted: []
    property int acceptCount: 0
    property int rejects: 0
    property string selectedPath: ""
    property int closes: 0
    property QtObject locale: QtObject {
        property bool isRtl: false
        function tr(text, context) {
            return text;
        }
    }
    property QtObject cache: QtObject {
        property var fileBrowserSettings: ({})
        property int saves: 0
        function saveCache() {
            saves++;
        }
    }

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
        Host.cache = cache;
        Host.files = Stub.FilesBackend;
        cache.fileBrowserSettings = {
            "legacy": {
                "sortBy": "modified",
                "sortAscending": false,
                "iconSizeIndex": 2,
                "viewMode": "grid",
                "lastPath": "file:///home/alice/Music"
            }
        };
        pickerLoader.active = true;
    }

    TestCase {
        id: input
        when: false
        name: "file-picker"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 900
        implicitHeight: 640

        Loader {
            id: pickerLoader

            anchors.fill: parent
            active: false
            sourceComponent: FilePicker {
                bucket: "images"
                filters: ["*.png"]
                startPath: "/home/alice/Pictures/sunrise.png"
                onAccepted: paths => {
                    root.accepted = paths;
                    root.acceptCount++;
                }
                onRejected: root.rejects++
            }
        }
    }

    FileBrowserModal {
        id: modal

        browserType: "legacy"
        folderMode: true
        onFileSelected: path => root.selectedPath = path
        onDialogClosed: root.closes++
    }

    function check(value, label) {
        if (!value)
            throw new Error(label);
    }

    function names(picker) {
        const out = [];
        const entries = picker.browser.directory.entries;
        for (let i = 0; i < entries.count; i++)
            out.push(entries.get(i).name);
        return out;
    }

    function run() {
        try {
            const picker = pickerLoader.item;
            const browser = picker.browser;
            input.tryVerify(() => browser.path === "/home/alice/Pictures", 1000, "opens the folder of a file start path");
            input.tryVerify(() => browser.selection.contains("/home/alice/Pictures/sunrise.png"), 1000, "selects the start file");
            check(JSON.stringify(names(picker)) === JSON.stringify(["Wallpapers", "sunrise.png"]), "filters keep folders and matching files: " + names(picker));

            picker.forceActiveFocus();
            browser.focusBody();
            input.keyClick(Qt.Key_H, Qt.ControlModifier);
            input.tryVerify(() => names(picker).includes(".draft.png"), 1000, "Ctrl+H shows hidden files");
            check(cache.fileBrowserSettings.images.showHidden === true, "hidden toggle persists per bucket");

            input.keyClick(Qt.Key_Return);
            check(root.accepted.length === 1 && root.accepted[0] === "/home/alice/Pictures/sunrise.png", "Enter on a file accepts it");

            browser.selection.select("/home/alice/Pictures/Wallpapers");
            input.keyClick(Qt.Key_Return);
            input.tryVerify(() => browser.path === "/home/alice/Pictures/Wallpapers", 1000, "Enter on a folder opens it");
            input.keyClick(Qt.Key_Backspace);
            input.tryVerify(() => browser.path === "/home/alice/Pictures", 1000, "Backspace goes up");
            input.keyClick(Qt.Key_Left, Qt.AltModifier);
            input.tryVerify(() => browser.path === "/home/alice/Pictures/Wallpapers", 1000, "Alt+Left goes back");
            browser.navigate("/home/alice/Pictures");
            input.tryVerify(() => browser.path === "/home/alice/Pictures", 1000, "navigate");

            picker.setSort("size", true);
            input.tryVerify(() => names(picker)[0] === "Wallpapers" && names(picker)[1] === "sunrise.png" && names(picker)[2] === ".draft.png", 1000, "size sort keeps folders first");
            check(cache.fileBrowserSettings.images.sortKey === "size" && cache.fileBrowserSettings.images.sortDesc === true, "sort persists");
            picker.sortControl.directionToggled();
            check(picker.sortKey === "size" && !picker.sortDescending, "the trailing half toggles the direction only");
            picker.sortControl.sortKeySelected("name");
            check(picker.sortKey === "name" && !picker.sortDescending, "choosing a key keeps the direction");
            picker.setSort("size", true);

            picker.createFolder("Screenshots");
            input.tryVerify(() => browser.path === "/home/alice/Pictures/Screenshots", 1000, "new folder opens");
            browser.back();
            input.tryVerify(() => names(picker).includes("Screenshots"), 1000, "new folder listed through a watch batch");
            check(JSON.stringify(names(picker)) === JSON.stringify(["Wallpapers", "Screenshots", "sunrise.png", ".draft.png"]), "batch inserts at the sorted index: " + names(picker));

            picker.renameItem("/home/alice/Pictures/Screenshots", "Captures");
            input.tryVerify(() => names(picker).includes("Captures") && !names(picker).includes("Screenshots"), 1000, "rename updates the listing");
            picker.trashItems(["/home/alice/Pictures/Captures"]);
            input.tryVerify(() => !names(picker).includes("Captures"), 1000, "trash removes from the listing");
            picker.renameItem("/home/alice/Pictures/sunrise.png", "Wallpapers");
            check(picker._error !== "", "rename onto an existing name reports an error");

            picker.startPath = "";
            picker.mode = "save";
            picker.defaultName = "notes.png";
            picker.reset();
            input.tryVerify(() => browser.path === "/home/alice/Pictures", 1000, "save mode restores the last folder");
            check(picker.viewMode === "list" && picker.sortKey === "size", "reset restores the saved view and sort");
            picker.acceptCurrent();
            check(root.accepted[0] === "/home/alice/Pictures/notes.png", "save to a new name accepts the joined path");
            browser.selection.select("/home/alice/Pictures/sunrise.png");
            picker._focusStart();
            picker.fileName = "typed.png";
            const acceptsBefore = root.acceptCount;
            input.keyClick(Qt.Key_Return);
            check(root.acceptCount === acceptsBefore + 1 && root.accepted[0] === "/home/alice/Pictures/typed.png" && picker._overwriteTarget === "", "Enter in the name field accepts the typed name once");
            picker.fileName = "sunrise.png";
            picker.acceptCurrent();
            check(picker._overwriteTarget === "/home/alice/Pictures/sunrise.png", "save over an existing file asks first");
            picker._overwriteTarget = "";
            picker.fileName = "Wallpapers";
            picker.acceptCurrent();
            input.tryVerify(() => browser.path === "/home/alice/Pictures/Wallpapers", 1000, "save onto a folder name opens the folder");

            picker.mode = "openFolder";
            picker.reset();
            input.tryVerify(() => browser.path === "/home/alice/Pictures/Wallpapers", 1000, "folder mode opens the last folder");
            picker.acceptCurrent();
            check(root.accepted[0] === "/home/alice/Pictures/Wallpapers", "folder mode accepts the current folder");
            browser.up();
            input.tryVerify(() => browser.path === "/home/alice/Pictures", 1000, "up");
            input.tryVerify(() => browser.directory.count > 0, 1000, "listed");
            browser.selection.select("/home/alice/Pictures/Wallpapers");
            picker.acceptCurrent();
            check(root.accepted[0] === "/home/alice/Pictures/Wallpapers", "folder mode accepts the selected folder");

            picker.mode = "open";
            picker.multiple = true;
            picker.filters = [];
            picker.reset();
            input.tryVerify(() => browser.directory.count > 3, 1000, "unfiltered listing");
            browser.focusBody();
            input.keyClick(Qt.Key_A, Qt.ControlModifier);
            check(browser.selection.count === browser.directory.count, "Ctrl+A selects everything");
            picker.acceptCurrent();
            check(root.accepted.length > 1 && root.accepted.every(path => !path.endsWith("/Wallpapers")), "multiple accepts files only");

            browser.editPath();
            for (const char of "/home/alice/Documents")
                input.keyClick(char);
            input.keyClick(Qt.Key_Return);
            input.tryVerify(() => browser.path === "/home/alice/Documents" && !browser.editingPath, 1000, "a typed path opens without a resolver");

            browser.editPath();
            input.keyClick(Qt.Key_Escape);
            check(!browser.editingPath && browser.body.activeFocus && root.rejects === 0, "Escape leaves path editing and returns focus to the list");
            input.keyClick(Qt.Key_Escape);
            check(root.rejects === 1, "Escape rejects");

            modal.open();
            input.tryVerify(() => modal.content !== null, 1000, "compat modal loads its picker");
            const legacy = modal.content;
            check(legacy.mode === "openFolder", "folderMode maps to openFolder");
            input.tryVerify(() => legacy.browser.path === "/home/alice/Music", 1000, "legacy lastPath is used");
            check(legacy.viewMode === "grid" && legacy.sortKey === "mtime" && legacy.sortDescending && legacy.gridZoom === 2, "legacy settings translate");
            legacy.acceptCurrent();
            check(root.selectedPath === "/home/alice/Music", "fileSelected carries a plain path");
            input.tryVerify(() => !modal.visible && root.closes === 1, 1000, "compat modal closes after accepting");
            const legacyRecord = cache.fileBrowserSettings.legacy;
            check(legacyRecord.sortBy === undefined && legacyRecord.sortKey === "mtime" && legacyRecord.sortDesc === true && legacyRecord.gridZoom === 2, "legacy keys are translated before they are dropped: " + JSON.stringify(legacyRecord));

            console.log("PASS file picker navigation, filters, hidden files, save, folder mode, operations, persistence and compat modal");
            Qt.quit();
        } catch (error) {
            console.error(error, error.stack);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 50
        running: true
        onTriggered: root.run()
    }
}
