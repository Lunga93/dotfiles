import QtQuick
import "."

Item {
    id: root

    property var colors

    width: clockColumn.implicitWidth
    height: clockColumn.implicitHeight

    Column {
        id: clockColumn
        spacing: 2

        Text {
            id: timeText
            anchors.right: parent.right
            font.family: Theme.fontFamily
            font.pixelSize: 32
            font.weight: Font.Light
            color: root.colors ? root.colors.textPrimary : "#f5f5f7"
            text: ""
        }
        Text {
            id: dateText
            anchors.right: parent.right
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Normal
            color: root.colors ? root.colors.textSecondary : "#a6f5f5f7"
            text: ""
        }
    }

    function refresh() {
        const d = new Date();
        timeText.text = Qt.formatDateTime(d, "HH:mm");
        dateText.text = Qt.formatDateTime(d, "dddd, MMMM d");
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()

    opacity: 0
    Component.onDestruction: {}
    Behavior on opacity {
        NumberAnimation { duration: Theme.durationXSlow; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 100
        running: true
        repeat: false
        onTriggered: root.opacity = 1.0
    }
}
