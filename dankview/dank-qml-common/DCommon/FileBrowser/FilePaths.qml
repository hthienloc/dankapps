pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtCore
import Quickshell

Singleton {
    readonly property string home: fromUrl(StandardPaths.writableLocation(StandardPaths.HomeLocation))

    function toFileUrl(path) {
        if (!path)
            return "";
        return "file://" + path.split("/").map(segment => encodeURIComponent(segment)).join("/");
    }

    function fromUrl(value) {
        const text = String(value ?? "");
        if (!text.startsWith("file://"))
            return text;
        try {
            return decodeURIComponent(text.substring(7));
        } catch (e) {
            return text.substring(7);
        }
    }

    function expandTilde(path) {
        if (path === "~")
            return home;
        if (path.startsWith("~/"))
            return home + path.substring(1);
        return path;
    }

    function parentOf(path) {
        if (path === "" || path === "/")
            return "";
        const cut = path.lastIndexOf("/");
        return cut <= 0 ? "/" : path.substring(0, cut);
    }

    function baseName(path) {
        return path.substring(path.lastIndexOf("/") + 1);
    }

    function join(directory, name) {
        return directory === "/" ? "/" + name : directory + "/" + name;
    }

    function normalize(path) {
        const absolute = expandTilde(fromUrl(path).trim());
        if (!absolute.startsWith("/"))
            return "";
        const parts = [];
        for (const part of absolute.split("/")) {
            switch (part) {
            case "":
            case ".":
                break;
            case "..":
                parts.pop();
                break;
            default:
                parts.push(part);
            }
        }
        return "/" + parts.join("/");
    }
}
