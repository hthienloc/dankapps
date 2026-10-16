import QtQuick
import qs.DCommon.Common

Item {
    id: root

    property string imagePath: ""
    property int maxCacheSize: 512
    property int status: isAnimated ? animatedImg.status : staticImg.status
    property int fillMode: Image.PreserveAspectCrop
    // AnimatedImage decodes full-size on the GUI thread and is never cached;
    // disable for thumbnail grids
    property bool animate: true
    property bool asynchronous: true
    property bool _fromCache: false
    property string _originalSource: ""
    property string _cacheTarget: ""

    readonly property bool isRemoteUrl: imagePath.startsWith("http://") || imagePath.startsWith("https://")
    readonly property bool isAnimated: animate && !!imagePath && hasAnimatedExtension(imagePath)
    readonly property string normalizedPath: {
        if (!imagePath)
            return "";
        if (isRemoteUrl)
            return imagePath;
        if (imagePath.startsWith("file://"))
            return imagePath.substring(7);
        return imagePath;
    }

    function hasAnimatedExtension(path) {
        const clean = path.split(/[?#]/)[0].toLowerCase();
        return clean.endsWith(".gif") || clean.endsWith(".webp");
    }

    function djb2Hash(str) {
        if (!str)
            return "";
        let hash = 5381;
        for (let i = 0; i < str.length; i++) {
            hash = ((hash << 5) + hash) + str.charCodeAt(i);
            hash = hash & 0x7FFFFFFF;
        }
        return hash.toString(16).padStart(8, '0');
    }

    readonly property string imageHash: normalizedPath ? djb2Hash(normalizedPath) : ""
    readonly property string cacheFileName: imageHash && !isRemoteUrl && !isAnimated ? `${imageHash}@${maxCacheSize}x${maxCacheSize}.png` : ""
    readonly property string cachePath: cacheFileName ? `${Paths.stringify(Paths.imagecache)}/${cacheFileName}` : ""
    readonly property string encodedImagePath: {
        if (!normalizedPath)
            return "";
        if (isRemoteUrl)
            return normalizedPath;
        return "file://" + normalizedPath.split('/').map(s => encodeURIComponent(s)).join('/');
    }

    AnimatedImage {
        id: animatedImg
        anchors.fill: parent
        visible: root.isAnimated
        asynchronous: root.asynchronous
        fillMode: root.fillMode
        source: root.isAnimated ? root.imagePath : ""
        playing: visible && status === AnimatedImage.Ready
    }

    Image {
        id: staticImg
        anchors.fill: parent
        visible: !root.isAnimated
        asynchronous: root.asynchronous
        fillMode: root.fillMode
        smooth: true

        // cache files are already bounded, and a sourceSize box would cover-scale them into a larger texture
        function loadOriginal() {
            root._fromCache = false;
            sourceSize = Qt.size(root.maxCacheSize, root.maxCacheSize);
            source = root._originalSource;
        }

        onStatusChanged: {
            switch (status) {
            case Image.Error:
                if (!root._fromCache)
                    return;
                loadOriginal();
                return;
            case Image.Ready:
                if (!root._cacheTarget)
                    return;
                if (root._fromCache) {
                    // older builds grabbed at item size under the same file name
                    if (Math.max(implicitWidth, implicitHeight) < root.maxCacheSize)
                        loadOriginal();
                    return;
                }
                if (!visible || width <= 0 || height <= 0 || !Window.window?.visible)
                    return;
                const grabPath = root._cacheTarget;
                const scale = root.maxCacheSize / Math.max(width, height);
                grabToImage(res => {
                    if (grabPath !== root._cacheTarget)
                        return;
                    res.saveToFile(grabPath);
                }, Qt.size(Math.round(width * scale), Math.round(height * scale)));
                return;
            }
        }
    }

    // Derives everything from a local snapshot of imagePath: sibling property
    // bindings (isRemoteUrl, encodedImagePath, ...) are still stale when
    // onImagePathChanged runs, so reading them here routes remote URLs down
    // the local-file branch on the first path change
    function resolveSource() {
        const path = imagePath;
        _fromCache = false;
        _cacheTarget = "";
        if (!path) {
            staticImg.source = "";
            return;
        }
        if (animate && hasAnimatedExtension(path))
            return;
        if (path.startsWith("http://") || path.startsWith("https://")) {
            staticImg.sourceSize = Qt.size(maxCacheSize, maxCacheSize);
            staticImg.source = path;
            return;
        }
        const stripped = path.startsWith("file://") ? path.substring(7) : path;
        const encoded = "file://" + stripped.split('/').map(s => encodeURIComponent(s)).join('/');
        const hash = djb2Hash(stripped);
        if (!hash) {
            staticImg.sourceSize = Qt.size(maxCacheSize, maxCacheSize);
            staticImg.source = encoded;
            return;
        }
        _originalSource = encoded;
        _cacheTarget = `${Paths.stringify(Paths.imagecache)}/${hash}@${maxCacheSize}x${maxCacheSize}.png`;
        _fromCache = true;
        staticImg.sourceSize = undefined;
        staticImg.source = _cacheTarget;
    }

    onImagePathChanged: resolveSource()
    // During creation onImagePathChanged fires before sibling properties (maxCacheSize) initialize
    onCachePathChanged: resolveSource()
}
