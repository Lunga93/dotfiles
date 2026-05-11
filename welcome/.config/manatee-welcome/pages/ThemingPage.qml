import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

PageContainer {
    id: root
    headerTitle: "Your wallpaper = your theme"
    headerSubtitle: "Every component picks up colors from your wallpaper \u2014 the bar, terminal, buttons, everything."
    stepIndex: 3
    stepCount: 5
    nextText: "Continue"

    readonly property string currentWallpaperPath:
        Quickshell.env("HOME") + "/.config/current_wallpaper"

    property string wallpaperPath: ""
    property bool hasWallpaper: false

    FileView {
        path: root.currentWallpaperPath
        watchChanges: true
        preload: true
        onLoaded: {
            var p = text().trim();
            if (p.length > 0) {
                root.wallpaperPath = p;
                root.hasWallpaper = true;
            }
        }
        onLoadFailed: root.hasWallpaper = false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Rectangle {
            id: previewCard
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: Theme.radiusControl
            clip: true
            color: Theme.surfaceElev

            border.color: Theme.border
            border.width: 1

            Image {
                anchors.fill: parent
                source: root.hasWallpaper ? "file://" + root.wallpaperPath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.height: 360
                visible: root.hasWallpaper && status === Image.Ready
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.40)
                visible: root.hasWallpaper

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "Current Wallpaper"
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.9
                    }

                    Text {
                        text: {
                            if (!root.hasWallpaper) return "";
                            var parts = root.wallpaperPath.split("/");
                            return parts[parts.length - 1];
                        }
                        color: "#ffffff"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.65
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "No wallpaper set"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 14
                visible: !root.hasWallpaper
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            radius: Theme.radiusControl
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.primary
                }
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.secondary
                }
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1
                }
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.accentSoft
                }
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.color1
                }
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.color2
                }
                Rectangle {
                    width: 28; height: 28
                    radius: 6
                    color: Theme.color3
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Live palette"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: Theme.radiusControl
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("manatee-settings://wallpaper")
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    text: "\u2699"
                    color: Theme.textSecondary
                    font.pixelSize: 18
                }

                Column {
                    spacing: 2
                    Text {
                        text: "Open Wallpaper Settings"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        text: "Mod + ,"
                        color: Theme.textSecondary
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "\u2192"
                    color: Theme.textSecondary
                    font.pixelSize: 16
                }
            }
        }

        ColumnLayout {
            spacing: 4
            Text {
                text: "How it works"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
            }
            Text {
                text: "Pick any wallpaper and pywal generates a palette from it. " +
                      "The bar, terminal, notifications, and even this window " +
                      "re-theme themselves on the fly \u2014 no restart needed."
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                lineHeight: 1.5
            }
        }
    }
}
