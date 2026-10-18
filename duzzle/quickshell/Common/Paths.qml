pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import QtCore

Singleton {
    id: root

    readonly property url home: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
    readonly property url xdgCache: StandardPaths.standardLocations(StandardPaths.GenericCacheLocation)[0]
    readonly property url cache: `${xdgCache}/duzzle`

    function stringify(path): string {
        if (!path)
            return "";
        return path.toString().replace(/%20/g, " ");
    }

    function expandTilde(path: string): string {
        if (!path || !path.startsWith("~"))
            return path || "";
        return strip(root.home) + path.substring(1);
    }

    function shortenHome(path: string): string {
        if (!path)
            return "";
        return path.replace(strip(root.home), "~");
    }

    function strip(path): string {
        if (!path)
            return "";
        return stringify(path).replace("file://", "");
    }

    function toFileUrl(path: string): string {
        return path.startsWith("file://") ? path : "file://" + path;
    }

    function mkdir(path: url): void {
        Quickshell.execDetached(["mkdir", "-p", strip(path)]);
    }

    Component.onCompleted: mkdir(cache)
}
