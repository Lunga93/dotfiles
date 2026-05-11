import QtQuick
import QtQuick.Layouts
import ".."

PageContainer {
    id: root
    headerTitle: "What's inside " + DistroFacts.name
    headerSubtitle: DistroFacts.summary
    stepIndex: 1
    stepCount: 5

    GridLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        columns: 2
        columnSpacing: 16
        rowSpacing: 16

        Repeater {
            model: DistroFacts.components
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 96
                radius: Theme.radiusControl
                color: Theme.surfaceElev
                border.color: Theme.border
                border.width: 1

                Rectangle {
                    id: badge
                    width: 40; height: 40
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    radius: width / 2
                    color: Theme.accentSoft
                    Text {
                        anchors.centerIn: parent
                        text: modelData.name.substring(0, 1)
                        color: Theme.primary
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }
                }

                Column {
                    anchors.left: badge.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: modelData.name
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: modelData.blurb
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        width: parent.width
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
