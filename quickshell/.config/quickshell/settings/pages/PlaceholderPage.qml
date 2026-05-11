import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

Item {
    id: root

    Column {
        anchors.centerIn: parent
        spacing: 16
        width: 360

        Rectangle {
            width: 80
            height: 80
            radius: 40
            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
            anchors.horizontalCenter: parent.horizontalCenter

            PhosphorIcon {
                anchors.centerIn: parent
                name: "gear"
                size: 36
                color: Theme.accent
                weight: "duotone"
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Coming Soon"
            color: "#f5ede0"
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: "This settings page will be available in a future update."
            color: "#8a8175"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
