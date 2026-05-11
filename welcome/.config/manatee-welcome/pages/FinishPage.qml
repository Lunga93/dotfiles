import QtQuick
import QtQuick.Layouts
import ".."

PageContainer {
    id: root
    headerTitle: "You're all set"
    headerSubtitle: "A few resources for the road. The Welcome screen lives at " +
                    "manatee-welcome \u2014 delete the flag in ~/.local/state/manatee-welcome/ " +
                    "to re-trigger it any time."
    stepIndex: 4
    stepCount: 5
    nextText: "Finish"

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10

        Repeater {
            model: [
                { "title": "Source & install",   "subtitle": DistroFacts.repoUrl, "url": DistroFacts.repoUrl },
                { "title": "Configuration docs", "subtitle": "README on GitHub",  "url": DistroFacts.docsUrl },
                { "title": "Full hotkey list",   "subtitle": "Press Mod+Shift+Escape any time", "url": "" }
            ]
            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: 60
                radius: Theme.radiusControl
                color: hover.containsMouse ? Theme.surfaceHover : Theme.surfaceElev
                border.color: Theme.border
                border.width: 1
                Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: modelData.title
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: modelData.subtitle
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        width: parent.width
                    }
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: modelData.url.length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                    enabled: modelData.url.length > 0
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }
}
