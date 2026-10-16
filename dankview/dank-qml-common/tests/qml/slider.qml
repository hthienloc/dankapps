import QtQuick
import qs.DCommon.Widgets
import qs.DCommon.Common

Item {
    id: root
    width: 600
    height: 600

    property QtObject theme: QtObject {
        property int radiusStrength: 50
        property int currentAnimationSpeed: 0
    }
    property QtObject locale: QtObject {
        property bool isRtl: false
    }
    Component {
        id: factory
        DSlider {
            width: 400
            showValue: false
        }
    }

    function run() {
        try {
            const formatter = factory.createObject(root, {
                unit: ""
            });
            if (formatter.formatValue(5) !== "5")
                throw new Error("column counts must not show a percentage");
            formatter.decimals = 1;
            formatter.unit = "×";
            if (formatter.formatValue(15) !== "1.5×")
                throw new Error("scroll factors must show their decimal multiplier");
            formatter.unit = "";
            if (formatter.formatValue(-10) !== "-1.0")
                throw new Error("pointer speed must show its signed decimal value");
            formatter.decimals = 0;
            formatter.unit = "px";
            if (formatter.formatValue(-12) !== "-12px")
                throw new Error("size offsets must show pixels");
            formatter.destroy();
            console.log("PASS slider units, signed values and decimal formatting");
            Qt.quit();
        } catch (error) {
            console.error(error);
            Qt.exit(1);
        }
    }

    Component.onCompleted: {
        Style.theme = theme;
        I18n.backend = locale;
        Qt.callLater(run);
    }
}
