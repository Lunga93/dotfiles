import QtQuick
import Quickshell
import "../../.." // qmldir types

Item {
    id: root

    property string selectedMood: ""
    signal moodSelected(string moodId)
    signal moodDeselected()

    height: 140

    Row {
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: MoodCatalog.moods

            delegate: MoodTile {
                required property var modelData

                moodId: modelData.id
                moodLabel: modelData.label
                gradientStart: modelData.gradientStart
                gradientEnd: modelData.gradientEnd
                wallpaperCount: MoodCatalog.moodCount(modelData.id)
                selected: root.selectedMood === modelData.id

                Binding {
                    target: parent
                    property: "opacity"
                    value: root.selectedMood === "" || root.selectedMood === modelData.id ? 1.0 : 0.35
                }

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
}
