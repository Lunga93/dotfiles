// Text element with bar-default typography. Color defaults to textPrimary
// but is meant to be overridden by callers.

import QtQuick

Text {
    color: Theme.textPrimary
    font.family: Theme.fontFamily
    font.pixelSize: Theme.barFontSize
    font.weight: Font.Medium
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
