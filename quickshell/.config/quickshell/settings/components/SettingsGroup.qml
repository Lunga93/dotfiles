import QtQuick
import QtQuick.Controls
import Quickshell

Column {
    id: root
    property string header: ""
    property alias spacing: col.spacing

    width: parent.width

    Text {
        text: root.header
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.6
        textFormat: Text.PlainText
        leftPadding: 16
        rightPadding: 16
        topPadding: 12
        bottomPadding: 8
        visible: root.header !== ""
    }

    Rectangle {
        width: parent.width
        height: childrenRect.height
        radius: Theme.radiusCard
        color: Theme.surfaceElev
        border.color: Theme.border
        border.width: 1
        clip: true

        Column {
            id: col
            width: parent.width
        }
    }
}
