import QtQuick
import Quickshell
import "../../.." // qmldir types

Item {
    id: root

    property string selectedMood: ""
    signal moodSelected(string moodId)
    signal moodDeselected()

    height: 140

    ListView {
        id: listView
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 12
        leftMargin: 0
        rightMargin: 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 6000
        maximumFlickVelocity: 3000
        snapMode: ListView.SnapToItem
        highlightRangeMode: ListView.NoHighlightRange

        model: MoodCatalog.moods

        delegate: MoodTile {
            required property var modelData

            width: 140
            height: 120
            y: 10

            moodId: modelData.id
            moodLabel: modelData.label
            gradientStart: modelData.gradientStart
            gradientEnd: modelData.gradientEnd
            wallpaperCount: MoodCatalog.moodCount(modelData.id)
            selected: root.selectedMood === modelData.id

            opacity: root.selectedMood === "" || root.selectedMood === modelData.id ? 1.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 200 } }

            onClicked: {
                if (root.selectedMood === modelData.id) {
                    root.selectedMood = "";
                    root.moodDeselected();
                } else {
                    root.selectedMood = modelData.id;
                    root.moodSelected(modelData.id);
                }
            }
        }
    }
}
