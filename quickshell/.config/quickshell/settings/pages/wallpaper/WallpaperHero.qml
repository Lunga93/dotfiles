import QtQuick
import QtQuick.Controls
import Quickshell

Item {
    id: root

    property bool moodBrowsing: false
    property string browseMoodId: ""
    property string browseMoodLabel: ""
    property int browseMoodCount: 0
    signal backToAll()
    signal accentSelected(string hex)

    height: 160

    Row {
        anchors.fill: parent
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 8
        anchors.bottomMargin: 8
        spacing: 16

        Rectangle {
            width: (parent.width - 16) * 0.6
            height: parent.height
            radius: 12
            color: "#0f0b07"
            clip: true

            Image {
                anchors.fill: parent
                source: root.moodBrowsing ? "" : (SettingsStore.currentWallpaper ? "file://" + SettingsStore.currentWallpaper : "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 600
                sourceSize.height: 300
                smooth: true
                opacity: status === Image.Ready && !root.moodBrowsing ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                anchors.fill: parent
                visible: root.moodBrowsing
                gradient: Gradient {
                    GradientStop { position: 0.0; color: (() => { const m = MoodCatalog.moods.find(m => m.id === root.browseMoodId); return m ? m.gradientStart : "#888"; })() }
                    GradientStop { position: 1.0; color: (() => { const m = MoodCatalog.moods.find(m => m.id === root.browseMoodId); return m ? m.gradientEnd : "#444"; })() }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 10
                height: 22
                width: currentText.width + 16
                radius: 11
                color: Qt.rgba(0, 0, 0, 0.6)
                visible: !root.moodBrowsing

                Text {
                    id: currentText
                    anchors.centerIn: parent
                    text: "CURRENT"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 28
                color: Qt.rgba(0, 0, 0, 0.55)
                visible: !root.moodBrowsing

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        const p = SettingsStore.currentWallpaper;
                        if (!p) return "No wallpaper set";
                        return p.split("/").pop();
                    }
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                    width: parent.width - 24
                }
            }
        }

        Rectangle {
            width: (parent.width - 16) * 0.4
            height: parent.height
            radius: 12
            color: "#221c15"
            border.color: "#0e0a06"
            border.width: 1

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Text {
                    text: root.moodBrowsing ? "Browsing mood" : "Now playing"
                    color: "#6b6258"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }

                Text {
                    text: root.moodBrowsing ? root.browseMoodLabel : (SettingsStore.currentWallpaper ? SettingsStore.currentWallpaper.split("/").pop() : "No wallpaper")
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                    width: parent.width
                }

                Text {
                    text: "Palette"
                    color: "#6b6258"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                    anchors.topMargin: 4
                }

                Row {
                    spacing: 6
                    Repeater {
                        model: [
                            Theme.color1, Theme.color2, Theme.color3,
                            Theme.color4, Theme.color5, Theme.color6
                        ]
                        delegate: ColorSwatch {
                            required property color modelData
                            swatchColor: modelData
                            selected: Theme.accent.toString() === modelData.toString()
                            onClicked: SettingsStore.setManualAccent(modelData.toString())
                        }
                    }
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 0
                    width: parent.width
                    spacing: 8

                    PillSelector {
                        options: ["Dynamic", "Manual"]
                        currentIndex: SettingsStore.get("appearance", "accent_mode") === "manual" ? 1 : 0
                        onSelected: function(idx) {
                            SettingsStore.setAccentMode(idx === 0 ? "dynamic" : "manual");
                        }
                    }

                    Rectangle {
                        height: 32
                        width: backText.width + 20
                        radius: 16
                        color: backArea.containsMouse ? "#2c2519" : "transparent"
                        visible: root.moodBrowsing
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Text {
                            id: backText
                            anchors.centerIn: parent
                            text: "\u2190 Back to all"
                            color: "#a89e8e"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: backArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.backToAll()
                        }
                    }
                }
            }
        }
    }
}
