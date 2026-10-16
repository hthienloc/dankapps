import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Widgets
import qs.DCommon.Common

ShellRoot {
    id: root

    property QtObject locale: QtObject {
        property bool isRtl: false
    }
    property QtObject settings: QtObject {
        property bool reduceMotion: true
    }
    property int clickedIndex: -1

    Component.onCompleted: {
        Quickshell.watchFiles = false;
        I18n.backend = locale;
        Style.settings = settings;
    }

    TestCase {
        id: input
        when: false
        name: "carousel"
    }

    FloatingWindow {
        id: window
        visible: true
        implicitWidth: 400
        implicitHeight: 200

        DCarousel {
            id: carousel
            x: 20
            y: 20
            width: 320
            height: 112
            preferredItemWidth: width / 2
            model: 12

            delegate: DCarouselItem {
                id: tile
                required property int index
                onClicked: root.clickedIndex = tile.index
            }
        }
    }

    function near(actual, expected, label) {
        if (Math.abs(actual - expected) < 0.5)
            return;
        throw new Error(label + ": " + actual + " != " + expected);
    }

    function mask(index) {
        const item = carousel.itemAtIndex(index).children[0];
        return {
            left: item.mapToItem(carousel, 0, 0).x,
            width: item.width
        };
    }

    function run() {
        try {
            input.tryVerify(() => carousel.itemAtIndex(2) !== null, 5000, "delegates");
            const first = mask(0);
            const small = mask(2);
            near(first.left, 0, "first item flush left");
            near(first.width, carousel.itemWidth, "first item unmasked");
            near(small.left + small.width, carousel.width, "small item flush right");
            const medium = mask(1);
            input.mouseClick(carousel, medium.left + medium.width / 2, carousel.height / 2);
            if (root.clickedIndex !== 1)
                throw new Error("clicked " + root.clickedIndex);
            carousel.contentX = carousel.originX + carousel.contentWidth - carousel.width;
            const last = mask(11);
            near(last.left + last.width, carousel.width, "last item flush right");
            near(last.width, carousel.itemWidth, "last item unmasked");
            console.log("PASS carousel rest and end keylines, masked item clicks");
            Qt.quit();
        } catch (error) {
            console.error(error, error.stack);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 0
        running: true
        onTriggered: root.run()
    }
}
