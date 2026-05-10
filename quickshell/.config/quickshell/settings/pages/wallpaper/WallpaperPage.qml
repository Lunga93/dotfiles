import QtQuick
import QtQuick.Controls
import Quickshell

Flickable {
    id: root
    contentHeight: column.height + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 8000
    maximumFlickVelocity: 4500

    property string selectedMood: SettingsStore.selectedMood || ""

    Component.onCompleted: {
        MoodCatalog.refresh();
    }

    Column {
        id: column
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 72
            Column {
                anchors.left: parent.left; anchors.leftMargin: 28
                anchors.top: parent.top; anchors.topMargin: 20
                spacing: 4
                Text {
                    text: "Wallpaper"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                }
                Text {
                    text: "Browse by mood, schedule rotation, and manage sources."
                    color: "#8a8175"
                    font.family: Theme.fontFamily; font.pixelSize: 12
                }
            }
        }

        Column {
            x: 28
            width: parent.width - 56
            spacing: 16
            bottomPadding: 32

            WallpaperHero {
                id: hero
                width: parent.width
                moodBrowsing: root.selectedMood !== ""
                browseMoodId: root.selectedMood
                browseMoodLabel: {
                    for (let i = 0; i < MoodCatalog.moods.length; i++) {
                        if (MoodCatalog.moods[i].id === root.selectedMood)
                            return MoodCatalog.moods[i].label;
                    }
                    return "";
                }
                browseMoodCount: MoodCatalog.moodCount(root.selectedMood)
                onBackToAll: {
                    root.selectedMood = "";
                    SettingsStore.set("wallpaper", "selected_mood", null);
                }
                onAccentSelected: function(hex) {
                    SettingsStore.setManualAccent(hex);
                }
            }

            MoodGrid {
                id: moodGrid
                width: parent.width
                selectedMood: root.selectedMood
                onMoodSelected: function(moodId) {
                    root.selectedMood = moodId;
                    SettingsStore.set("wallpaper", "selected_mood", moodId);
                }
                onMoodDeselected: {
                    root.selectedMood = "";
                    SettingsStore.set("wallpaper", "selected_mood", null);
                }
            }

            WallpaperGrid {
                id: wallpaperGrid
                width: parent.width
                moodFilter: root.selectedMood
                visible: root.selectedMood !== ""
                height: visible ? implicitHeight : 0
                onWallpaperSelected: function(path) {
                    SettingsStore.setWallpaper(path);
                    root.selectedMood = "";
                    SettingsStore.set("wallpaper", "selected_mood", null);
                }
            }

            Row {
                width: parent.width
                spacing: 16

                ScheduleCard {
                    width: (parent.width - 16) * 0.55
                }

                SourcesCard {
                    width: (parent.width - 16) * 0.45
                }
            }
        }
    }

    Rectangle {
        anchors.right: parent.right; anchors.rightMargin: 4
        anchors.top: parent.top; anchors.bottom: parent.bottom
        width: 4; radius: 2; color: "transparent"

        Rectangle {
            anchors.right: parent.right; width: parent.width; radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)
            y: root.contentHeight > 0 ? (root.contentY / root.contentHeight) * parent.height : 0
            height: root.contentHeight > 0 ? Math.max(40, (root.height / root.contentHeight) * parent.height) : 0
            visible: root.contentHeight > root.height
        }
    }
}
