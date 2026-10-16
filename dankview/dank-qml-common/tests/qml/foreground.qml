import QtQuick
import qs.DCommon.Widgets
import qs.DCommon.Common

Item {
    id: root
    width: 800
    height: 600
    property QtObject theme: QtObject {
        property real radiusStrength: 50
        property int currentAnimationSpeed: 0
        property bool foregroundLayers: true
        property real foregroundLayerTransparency: 1
        property bool floatingWindowForegroundLayers: true
        property real floatingWindowForegroundTransparency: 1
    }
    Item {
        id: popup
    }
    Item {
        id: floating
        property bool isFloatingWindowSurface: true
    }
    Item {
        id: connected
        parent: floating
        property bool isFloatingWindowSurface: false
    }
    Component {
        id: fieldFactory
        DTextField {
            width: 200
        }
    }
    Component {
        id: cardFactory
        DCard {
            width: 200
            height: 100
        }
    }
    Component {
        id: rowFactory
        DListItem {
            width: 200
        }
    }
    Component {
        id: groupFactory
        DCollapsibleSection {
            width: 200
            title: "Group"
        }
    }
    function equal(actual, expected, name) {
        if (Math.abs(actual - expected) < 0.005)
            return;
        throw new Error(name + ": " + actual + " != " + expected);
    }
    function run() {
        let cases = 0;
        try {
            for (const globalEnabled of [false, true]) {
                for (const windowEnabled of [false, true]) {
                    for (const globalOpacity of [0, 0.25, 1]) {
                        for (const windowOpacity of [0, 0.6, 1]) {
                            theme.foregroundLayers = globalEnabled;
                            theme.foregroundLayerTransparency = globalOpacity;
                            theme.floatingWindowForegroundLayers = windowEnabled;
                            theme.floatingWindowForegroundTransparency = windowOpacity;
                            for (const host of [popup, floating, connected]) {
                                const expected = host === floating ? (windowEnabled ? windowOpacity : 0) : (globalEnabled ? globalOpacity : 0);
                                for (const factory of [fieldFactory, cardFactory, rowFactory]) {
                                    const item = factory.createObject(host);
                                    equal(item.color.a, expected, "painted alpha");
                                    if (factory === fieldFactory) {
                                        equal(item.normalBorderColor.a, 1, "field border stays visible");
                                        item.backgroundColor = Qt.rgba(0.2, 0.3, 0.4, 0.5);
                                        equal(item.color.a, expected * 0.5, "custom background alpha");
                                    }
                                    if (factory === rowFactory) {
                                        item.isSelected = true;
                                        equal(item.color.a, 1, "selection stays visible");
                                        equal(item.contentColor.a, 1, "text stays visible");
                                    }
                                    item.destroy();
                                    cases++;
                                }
                            }
                        }
                    }
                }
            }
            const moved = cardFactory.createObject(popup);
            theme.foregroundLayers = false;
            theme.floatingWindowForegroundLayers = true;
            theme.floatingWindowForegroundTransparency = 0.6;
            equal(moved.color.a, 0, "popup before reparent");
            moved.parent = floating;
            equal(moved.color.a, 0.6, "floating after reparent");
            const group = groupFactory.createObject(floating);
            if (!group)
                throw new Error("collapsible creation failed");
            group.destroy();
            moved.destroy();
            console.log("PASS " + cases + " foreground component cases and reparenting");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }
    Component.onCompleted: {
        Style.theme = theme;
        Qt.callLater(run);
    }
}
