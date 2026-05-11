import QtQuick
import ".."

Item {
    id: root
    property string text: "Back"
    signal clicked()

    implicitWidth: Math.max(120, label.implicitWidth + 32)
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusControl
        color: mouse.pressed
               ? Theme.surfacePressed
               : mouse.containsMouse
                 ? Theme.surfaceHover
                 : "transparent"
        border.color: Theme.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.durationFast } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.Medium
        color: Theme.textPrimary
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
