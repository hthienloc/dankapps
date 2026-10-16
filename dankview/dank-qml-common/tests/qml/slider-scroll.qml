import QtQuick
import QtTest
import Quickshell
import qs.DCommon.Common
import qs.DCommon.Widgets

ShellRoot {
    id: root

    TestCase {
        id: input
        when: false
        name: "slider-scroll"
    }

    FloatingWindow {
        visible: true
        implicitWidth: 600
        implicitHeight: 500

        Item {
            id: plain
            width: parent.width
            height: 120

            Item {
                id: sliderHost
                width: 400
                height: slider.height
                y: 24

                DSlider {
                    id: slider
                    width: parent.width
                    value: 50
                    wheelEnabled: true
                }
            }
        }

        DFlickable {
            id: scroll
            y: plain.height
            width: parent.width
            height: 300
            contentHeight: 900

            Item {
                id: scrollBody
                width: scroll.width
                height: 900
            }
        }
    }

    function check(value, label) {
        if (!value)
            throw new Error(label);
    }

    function run() {
        try {
            check(slider.wheelEnabled, "standalone slider accepts wheel input");
            input.mouseWheel(slider, slider.width / 2, slider.height / 2, 0, 120);
            check(slider.value > 50, "standalone wheel adjusts value");
            slider.value = 50;
            sliderHost.parent = scrollBody;
            input.wait(30);
            check(!slider.wheelEnabled, "reparenting under scrolling disables wheel adjustment");
            input.mouseWheel(slider, slider.width / 2, slider.height / 2, 0, -120);
            input.wait(30);
            check(slider.value === 50, "explicit wheelEnabled cannot override scroll-container rule");
            check(scroll.contentY > 0, "wheel over slider scrolls its container");
            scroll.contentY = 0;
            slider.forceActiveFocus();
            input.keyClick(Qt.Key_Right);
            check(slider.value > 50, "keyboard adjustment remains available");
            input.mousePress(slider, slider.width / 2, slider.height / 2);
            input.mouseMove(slider, slider.width * 0.8, slider.height / 2, 30);
            input.mouseRelease(slider, slider.width * 0.8, slider.height / 2);
            check(slider.value > 60, "drag adjustment remains available");
            scroll.contentHeight = scroll.height;
            slider.value = 50;
            input.wait(30);
            input.mouseWheel(slider, slider.width / 2, slider.height / 2, 0, 120);
            check(slider.value > 50, "nonoverflowing scroll container leaves wheel adjustment to the slider");
            sliderHost.parent = plain;
            input.wait(20);
            check(slider.wheelEnabled, "reparenting back restores standalone wheel adjustment");
            console.log("PASS slider scroll containment, reparenting, explicit override, keyboard and dragging");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: root.run()
    }
}
