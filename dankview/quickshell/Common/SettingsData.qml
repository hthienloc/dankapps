pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common

Singleton {
    id: root

    enum AnimationSpeed {
        None,
        Short,
        Medium,
        Long,
        Custom
    }

    enum TextRenderType {
        Qt,
        Native,
        Curve
    }

    enum TextRenderQuality {
        Default,
        Low,
        Normal,
        High,
        VeryHigh
    }

    property bool popoutElevationEnabled: true
    property int textRenderType: SettingsData.TextRenderType.Qt
    property int textRenderQuality: SettingsData.TextRenderQuality.Default

    readonly property string configDir: {
        const xdg = Quickshell.env("XDG_CONFIG_HOME");
        const base = (xdg && xdg !== "") ? xdg : Quickshell.env("HOME") + "/.config";
        return base + "/dankview";
    }
    readonly property string settingsPath: configDir + "/ui-settings.json"

    // Theme configuration
    property alias themeMode: adapter.themeMode
    property alias colorSource: adapter.colorSource
    property alias presetTheme: adapter.presetTheme
    property alias customThemeFile: adapter.customThemeFile
    // 0 (square) … 100; 50 keeps the Material shape scale
    property alias radiusStrength: adapter.radiusStrength
    // base transition length in ms, 0 disables animations
    property alias animationDuration: adapter.animationDuration
    property alias reduceMotion: adapter.reduceMotion
    // 0 smooth, 1 balanced, 2 playful
    property alias springBounce: adapter.springBounce
    property alias enableRippleEffects: adapter.enableRippleEffects
    property alias fontWeight: adapter.fontWeight
    property alias fontScale: adapter.fontScale
    property alias focusRingEnabled: adapter.focusRingEnabled
    property alias focusRingWidth: adapter.focusRingWidth
    property alias focusRingColor: adapter.focusRingColor

    // Viewer preferences
    property alias autoHideControls: adapter.autoHideControls
    property alias showCheckerboard: adapter.showCheckerboard

    // Gallery preferences
    property alias galleryLandingPage: adapter.galleryLandingPage
    property alias galleryCropThumbnails: adapter.galleryCropThumbnails
    readonly property string galleryThumbnailLayout: {
        const layout = adapter.galleryThumbnailLayout;
        if (layout === "crop" || layout === "fit" || layout === "masonry")
            return layout;
        return adapter.galleryCropThumbnails ? "crop" : "fit";
    }

    function setGalleryThumbnailLayout(layout) {
        if (layout !== "crop" && layout !== "fit" && layout !== "masonry")
            return;
        adapter.galleryThumbnailLayout = layout;
        adapter.galleryCropThumbnails = layout === "crop";
    }

    Component.onCompleted: {
        Paths.mkdir(configDir);
    }

    FileView {
        id: settingsFile
        path: root.settingsPath
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        watchChanges: true
        printErrors: false

        property bool _loaded: false
        property bool _selfWrite: false

        onLoaded: _loaded = true
        onLoadFailed: _loaded = true
        onFileChanged: {
            if (_selfWrite) {
                _selfWrite = false;
                return;
            }
            reload();
        }
        onAdapterUpdated: {
            if (!_loaded)
                return;
            _selfWrite = true;
            writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string themeMode: "auto"
            property string colorSource: "auto"
            property string presetTheme: "blue"
            property string customThemeFile: ""
            property int radiusStrength: 50
            property int animationDuration: 250
            property bool reduceMotion: false
            property int springBounce: 1
            property bool enableRippleEffects: true
            property int fontWeight: 400
            property real fontScale: 1.0
            property bool focusRingEnabled: true
            property real focusRingWidth: 1.5
            property string focusRingColor: "primary"
            property bool autoHideControls: true
            property bool showCheckerboard: true
            property string galleryLandingPage: "gallery"
            property bool galleryCropThumbnails: true
            property string galleryThumbnailLayout: ""
        }
    }
}
