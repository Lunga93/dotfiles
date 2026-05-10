import QtQuick
import QtQuick.Controls
import Quickshell

Flickable {
    id: root
    contentHeight: pageContent.height
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 8000
    maximumFlickVelocity: 4500

    Column {
        id: pageContent
        width: parent.width
        spacing: 0

        // Header
        Item {
            width: parent.width
            height: 88

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.top: parent.top
                anchors.topMargin: 24
                spacing: 4

                Text {
                    text: "Wallpaper"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Bold
                }
                Text {
                    text: "Browse, schedule, and tune the colors that drive your whole desktop."
                    color: "#8a8175"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }

        // Body
        Column {
            x: 28
            width: parent.width - 56
            spacing: 18
            bottomPadding: 32

            // ── Current wallpaper preview + actions ──
            Rectangle {
                width: parent.width
                radius: 14
                color: "#221c15"
                border.color: "#0e0a06"
                border.width: 1
                height: previewCol.height

                Column {
                    id: previewCol
                    width: parent.width
                    spacing: 0

                    Item {
                        width: parent.width
                        height: 36
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "CURRENT"
                            color: "#6b6258"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.8
                        }
                    }

                    Rectangle {
                        id: previewBox
                        width: parent.width - 32
                        x: 16
                        height: 200
                        radius: 12
                        color: "#0f0b07"
                        clip: true

                        Image {
                            id: previewImage
                            anchors.fill: parent
                            source: SettingsStore.currentWallpaper ? "file://" + SettingsStore.currentWallpaper : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 1200
                            sourceSize.height: 600
                            smooth: true
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        }

                        // Filename overlay
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 32
                            color: Qt.rgba(0, 0, 0, 0.55)

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: {
                                    const p = SettingsStore.currentWallpaper;
                                    if (!p) return "No wallpaper set";
                                    const parts = p.split("/");
                                    return parts[parts.length - 1];
                                }
                                color: "#f5ede0"
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 64

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10

                            Rectangle {
                                width: fetchText.width + 36
                                height: 36
                                radius: 10
                                color: fetchArea.pressed ? Qt.darker(Theme.accent, 1.2) : (fetchArea.containsMouse ? Qt.lighter(Theme.accent, 1.05) : Theme.accent)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                scale: fetchArea.pressed ? 0.96 : 1.0
                                Behavior on scale { NumberAnimation { duration: 100 } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    PhosphorIcon {
                                        name: "image"
                                        size: 15
                                        color: "#1a1105"
                                        weight: "fill"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        id: fetchText
                                        text: "Fetch new"
                                        color: "#1a1105"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: fetchArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: SettingsStore.fetchWallpaper()
                                }
                            }
                        }
                    }
                }
            }

            // ── Library Browser ──
            Rectangle {
                width: parent.width
                radius: 14
                color: "#221c15"
                border.color: "#0e0a06"
                border.width: 1
                height: librarySection.height

                Column {
                    id: librarySection
                    width: parent.width
                    spacing: 0

                    WallpaperLibrary {
                        width: parent.width
                    }

                    Item { width: parent.width; height: 12 }
                }
            }

            // ── Recent ──
            Rectangle {
                width: parent.width
                radius: 14
                color: "#221c15"
                border.color: "#0e0a06"
                border.width: 1
                height: recentSection.height

                Column {
                    id: recentSection
                    width: parent.width
                    spacing: 0

                    RecentHistory {
                        width: parent.width
                    }

                    Item { width: parent.width; height: 12 }
                }
            }

            // ── Wallpaper-Derived Palette ──
            Rectangle {
                width: parent.width
                radius: 14
                color: "#221c15"
                border.color: "#0e0a06"
                border.width: 1
                height: paletteSection.height

                Column {
                    id: paletteSection
                    width: parent.width
                    spacing: 0

                    DerivedPalette {
                        width: parent.width
                    }
                }
            }

            // ── Auto Rotation ──
            Rectangle {
                width: parent.width
                radius: 14
                color: "#221c15"
                border.color: "#0e0a06"
                border.width: 1
                height: rotationSection.height

                Column {
                    id: rotationSection
                    width: parent.width
                    spacing: 0

                    FrequencyPicker {
                        width: parent.width
                    }
                }
            }

            // ── Source Management ──
            Rectangle {
                width: parent.width
                radius: 14
                color: "#221c15"
                border.color: "#0e0a06"
                border.width: 1
                height: sourcesSection.height

                Column {
                    id: sourcesSection
                    width: parent.width
                    spacing: 0

                    SourceManager {
                        width: parent.width
                    }
                }
            }
        }
    }

    // Custom scrollbar
    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 4
        radius: 2
        color: "transparent"

        Rectangle {
            anchors.right: parent.right
            width: parent.width
            radius: 2
            color: Qt.rgba(1, 1, 1, 0.15)
            y: root.contentHeight > 0 ? (root.contentY / root.contentHeight) * parent.height : 0
            height: root.contentHeight > 0 ? Math.max(40, (root.height / root.contentHeight) * parent.height) : 0
            visible: root.contentHeight > root.height
        }
    }
}
