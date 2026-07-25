import QtQuick
import "../../.." // qmldir types (bar components, Theme, SettingsStore)

Item {
    id: root
    clip: true

    // Wallpaper backdrop
    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: SettingsStore.currentWallpaper
            ? "file://" + SettingsStore.currentWallpaper + "?v=" + SettingsStore.wallpaperVersion
            : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }

    Rectangle {
        anchors.fill: parent
        visible: !SettingsStore.currentWallpaper
        color: "#1a1408"
    }

    // Mock bar using actual BarGradient + SettingsStore opacity
    Item {
        id: bar
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 38

        // Bar surface — same opacity + color as real bar
        Rectangle {
            id: surface
            anchors.fill: parent
            color: Qt.rgba(Theme.background.r, Theme.background.g, Theme.background.b,
                           SettingsStore.topBarBgOpacity)
            radius: Theme.radiusPill
        }

        // Gradient overlay — reuse the real BarGradient component
        BarGradient { anchors.fill: parent }

        // Workspace dots (left)
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Rectangle {
                width: 8; height: 8; radius: 4
                color: Theme.foreground
                anchors.verticalCenter: parent.verticalCenter
            }
            Repeater {
                model: 3
                delegate: Rectangle {
                    required property int index
                    width: 6; height: 6; radius: 3
                    color: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.45)
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Center app label
        Text {
            anchors.centerIn: parent
            text: "manatee"
            color: Theme.foreground
            font.family: SettingsStore.topBarFontFamily || Theme.fontFamily
            font.pixelSize: 13
            font.weight: {
                switch (SettingsStore.topBarFontWeight) {
                    case "light": return Font.Light;
                    case "medium": return Font.Medium;
                    default: return Font.Normal;
                }
            }
        }

        // Right: clock + power (matches real bar segments)
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: new Date().toLocaleTimeString(Qt.locale(), "hh:mm")
                color: Theme.foreground
                font.family: SettingsStore.topBarFontFamily || Theme.fontFamily
                font.pixelSize: 13
                font.weight: {
                    switch (SettingsStore.topBarFontWeight) {
                        case "light": return Font.Light;
                        case "medium": return Font.Medium;
                        default: return Font.Normal;
                    }
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "⏻"
                color: Theme.foreground
                font.family: Theme.fontMono
                font.pixelSize: 14
            }
        }
    }
}
