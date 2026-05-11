import QtQuick
import QtQuick.Controls
import ".."

Item {
    id: root
    property string text: "Continue"
    signal clicked()

    implicitWidth: Math.max(140, label.implicitWidth + 36)
    implicitHeight: 40

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: Theme.radiusControl
        color: mouse.pressed
               ? Qt.darker(Theme.primary, 1.10)
               : mouse.containsMouse
                 ? Qt.lighter(Theme.primary, 1.08)
                 : Theme.primary
        opacity: root.enabled ? 1.0 : 0.45

        Behavior on color   { ColorAnimation { duration: Theme.durationFast } }
        Behavior on opacity { NumberAnimation { duration: Theme.durationFast } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.weight: Font.Medium
        color: Theme.background
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.enabled) root.clicked()
    }

    transform: Translate {
        y: mouse.containsMouse && !mouse.pressed ? -1 : 0
        Behavior on y { NumberAnimation { duration: Theme.durationFast } }
    }
}
