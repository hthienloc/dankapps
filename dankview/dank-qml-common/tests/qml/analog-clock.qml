import QtQuick
import qs.DCommon.Widgets
import qs.DCommon.Common

Item {
    id: root
    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: 0
    }
    Component {
        id: clockFactory
        DAnalogClock {
            width: 200
            height: 200
        }
    }
    function equal(actual, expected, name) {
        if (actual === expected || (typeof actual === "number" && Math.abs(actual - expected) < 0.001))
            return;
        throw new Error(name + ": " + actual + " != " + expected);
    }
    function run() {
        let cases = 0;
        try {
            for (const [hours, minutes, seconds, hourAngle, minuteAngle] of [[0, 0, 0, 0, 0], [3, 0, 0, 90, 0], [15, 0, 0, 90, 0], [1, 10, 0, 35, 60], [4, 25, 0, 132.5, 150], [10, 35, 0, 317.5, 210], [2, 20, 30, 70, 123]]) {
                const clock = clockFactory.createObject(root, {
                    hours: hours,
                    minutes: minutes,
                    seconds: seconds
                });
                equal(clock.hourAngle, hourAngle, "hour angle " + hours + ":" + minutes);
                equal(clock.minuteAngle, minuteAngle, "minute angle " + minutes + ":" + seconds);
                clock.destroy();
                cases++;
            }
            console.log("PASS " + cases + " analog clock cases");
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
