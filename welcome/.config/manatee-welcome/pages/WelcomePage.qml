import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root
    signal advance()

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 560)
        spacing: 28

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 96
            implicitHeight: 96

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.accentSoft
                border.color: Theme.accentMuted
                border.width: 1
            }
            Image {
                anchors.centerIn: parent
                width: 64
                height: 64
                source: Qt.resolvedUrl("../assets/logo.svg")
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: parent.children[1].status !== Image.Ready
                text: "\U0001F40B"
                font.pixelSize: 48
            }
        }

        Text {
            text: "Welcome to " + DistroFacts.name
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 34
            font.weight: Font.DemiBold
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            text: DistroFacts.tagline
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
        }

        PrimaryButton {
            text: "Get Started"
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            implicitWidth: 200
            onClicked: root.advance()
        }
    }

    Repeater {
        model: 3
        delegate: Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -120
            color: "transparent"
            border.color: Theme.accentSoft
            border.width: 1
            z: -1
            radius: width / 2

            property real phase: index / 3
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0; to: 0.35; duration: 1800 + index * 200; easing.type: Easing.OutCubic }
                NumberAnimation { from: 0.35; to: 0; duration: 1800 + index * 200; easing.type: Easing.InCubic }
            }
            NumberAnimation on width {
                loops: Animation.Infinite
                from: 80; to: 220 + index * 30; duration: 3600 + index * 300
                easing.type: Easing.OutCubic
            }
            NumberAnimation on height {
                loops: Animation.Infinite
                from: 80; to: 220 + index * 30; duration: 3600 + index * 300
                easing.type: Easing.OutCubic
            }
        }
    }
}
