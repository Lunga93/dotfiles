import QtQuick
import Quickshell

Item {
    id: root

    property string moodId: ""
    property string moodLabel: ""
    property color gradientStart: "#888"
    property color gradientEnd: "#444"
    property int wallpaperCount: 0
    property bool selected: false

    signal clicked()

    width: 140
    height: 120

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 14

        gradient: Gradient {
            GradientStop { position: 0.0; color: root.gradientStart }
            GradientStop { position: 1.0; color: root.gradientEnd }
        }

        Rectangle {
            id: specular
            width: parent.width * 1.5
            height: parent.height * 2
            color: Qt.rgba(1, 1, 1, 0.05)
            rotation: 25
            x: -width
            y: -height * 0.5

            SequentialAnimation on x {
                loops: Animation.Infinite
                running: !root.selected && !hoverArea.containsMouse
                PauseAnimation { duration: 4000 }
                NumberAnimation { from: -width; to: parent.width + width; duration: 2000; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 2000 }
            }
        }

        scale: hoverArea.pressed ? 0.95 : (hoverArea.containsMouse ? 1.03 : 1.0)
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: root.selected ? 2 : 0
            opacity: root.selected ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.moodLabel
                color: root.moodId === "light" ? "#2a2a3a" : "#ffffff"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                font.letterSpacing: -0.2
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Repeater {
                    model: 3
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: Qt.lighter(root.gradientEnd, 1.0 + index * 0.15)
                        opacity: 0.6
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.wallpaperCount > 0 ? root.wallpaperCount + " wallpapers" : ""
                color: root.moodId === "light" ? "#555565" : Qt.rgba(1, 1, 1, 0.55)
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.clicked()
        }
    }

    Behavior on opacity { NumberAnimation { duration: 200 } }
}
