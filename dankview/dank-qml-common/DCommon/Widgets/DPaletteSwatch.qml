import QtQuick
import qs.DCommon.Common

DColorSwatch {
    property color primaryColor: Style.primary

    swatchColor: primaryColor
    secondaryColor: primaryColor
    tertiaryColor: secondaryColor
    ringWidth: 0
}
