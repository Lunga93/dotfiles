import QtQuick
import QtQuick.Layouts
import ".."

RowLayout {
    id: root
    property string chord: "Mod+Space"
    spacing: 4

    Repeater {
        model: root.chord.split("+")
        delegate: Rectangle {
            implicitWidth:  Math.max(28, kbd.implicitWidth + 14)
            implicitHeight: 26
            radius: 6
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1

            Text {
                id: kbd
                anchors.centerIn: parent
                text: modelData
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
            }
        }
    }
}
