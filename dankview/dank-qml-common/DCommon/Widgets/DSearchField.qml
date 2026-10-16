import QtQuick
import qs.DCommon.Common

DTextField {
    cornerRadius: Style.fullRadius(width, height)
    normalBorderColor: Style.outlineVariant
    focusedBorderColor: Style.focusRingWidth > 0 ? Style.focusRingColor : normalBorderColor
    borderWidth: Style.outlineWidth
    focusedBorderWidth: Math.max(borderWidth, Style.focusRingWidth)
    placeholderColor: Style.surfaceTextSecondary
    leftIconName: "search"
    hidePlaceholderOnFocus: false
    showClearButton: true
}
