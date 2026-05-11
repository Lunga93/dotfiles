import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

Item {
    id: root

    property bool moodBrowsing: false
    property string browseMoodId: ""
    property string browseMoodLabel: ""
    property int browseMoodCount: 0
    signal backToAll()
    signal accentSelected(string hex)  // kept for backward-compat

    height: 196

    readonly property var paletteColors: [
        Theme.color1, Theme.color2, Theme.color3,
        Theme.color4, Theme.color5, Theme.color6
    ]
    readonly property bool isManual: SettingsStore.get("appearance", "accent_mode") === "manual"
    readonly property color currentPrimary: Theme.primary
    readonly property color currentSecondary: Theme.secondary
    readonly property color labelMuted:  "#6b6258"
    readonly property color labelDim:    "#8a8175"
    readonly property color labelActive: "#f5ede0"
    readonly property color cardBg:      "#221c15"
    readonly property color cardBorder:  "#0e0a06"
    readonly property color rowDivider:  Qt.rgba(1, 1, 1, 0.04)

    function selectedIndex(target) {
        for (let i = 0; i < paletteColors.length; i++) {
            if (paletteColors[i].toString() === target.toString()) return i;
        }
        return -1;
    }

    Row {
        anchors.fill: parent
        spacing: 16

        // ── Wallpaper preview ────────────────────────────────────
        Rectangle {
            id: previewCard
            width: (parent.width - 16) / 2
            height: parent.height
            radius: 14
            color: "#0f0b07"
            clip: true

            Image {
                anchors.fill: parent
                source: root.moodBrowsing
                    ? ""
                    : (SettingsStore.currentWallpaper
                        ? "file://" + SettingsStore.currentWallpaper + "?v=" + SettingsStore.wallpaperVersion
                        : "")
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: 720
                sourceSize.height: 420
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

            // Top-left status badge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 12
                height: 24
                width: badgeText.width + 18
                radius: 12
                color: Qt.rgba(0, 0, 0, 0.55)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.moodBrowsing ? "BROWSING" : "CURRENT"
                    color: root.labelActive
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.9
                }
            }

            // Top-right back button (only while browsing a mood)
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 12
                height: 24
                width: backText.width + 22
                radius: 12
                color: backArea.containsMouse
                    ? Qt.rgba(0, 0, 0, 0.78)
                    : Qt.rgba(0, 0, 0, 0.55)
                visible: root.moodBrowsing
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    id: backText
                    anchors.centerIn: parent
                    text: "\u2190 All wallpapers"
                    color: root.labelActive
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    font.letterSpacing: 0.3
                }

                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backToAll()
                }
            }

            // Bottom filename / mood-info strip
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 32
                color: Qt.rgba(0, 0, 0, 0.58)

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (root.moodBrowsing) {
                            return root.browseMoodLabel + " · " + root.browseMoodCount + " wallpapers";
                        }
                        const p = SettingsStore.currentWallpaper;
                        if (!p) return "No wallpaper set";
                        return p.split("/").pop();
                    }
                    color: root.labelActive
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideMiddle
                }
            }
        }

        // ── Color scheme picker ──────────────────────────────────
        Rectangle {
            id: schemeCard
            width: (parent.width - 16) / 2
            height: parent.height
            radius: 14
            color: root.cardBg
            border.color: root.cardBorder
            border.width: 1

            Item {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.topMargin: 16
                anchors.bottomMargin: 16

                // Header row: title + mode pill
                Item {
                    id: schemeHeader
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: modePill.height

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "COLOR SCHEME"
                        color: root.labelMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                    }

                    PillSelector {
                        id: modePill
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        options: ["Dynamic", "Manual"]
                        currentIndex: root.isManual ? 1 : 0
                        onSelected: function(idx) {
                            SettingsStore.setAccentMode(idx === 0 ? "dynamic" : "manual");
                        }
                    }
                }

                // Subtle divider between header and rows
                Rectangle {
                    id: headerDivider
                    anchors.top: schemeHeader.bottom
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: root.rowDivider
                }

                // Primary row
                Item {
                    id: primaryRow
                    anchors.top: headerDivider.bottom
                    anchors.topMargin: 14
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PRIMARY"
                        color: root.isManual ? root.labelActive : root.labelDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Repeater {
                            model: root.paletteColors
                            delegate: ColorSwatch {
                                required property color modelData
                                required property int index
                                swatchSize: 30
                                swatchColor: modelData
                                interactive: root.isManual
                                selected: root.selectedIndex(root.currentPrimary) === index
                                onClicked: SettingsStore.setManualPrimary(modelData.toString())
                            }
                        }
                    }
                }

                // Row divider
                Rectangle {
                    id: rowDivider
                    anchors.top: primaryRow.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: root.rowDivider
                }

                // Secondary row
                Item {
                    anchors.top: rowDivider.bottom
                    anchors.topMargin: 10
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 36

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SECONDARY"
                        color: root.isManual ? root.labelActive : root.labelDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                        Behavior on color { ColorAnimation { duration: 160 } }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Repeater {
                            model: root.paletteColors
                            delegate: ColorSwatch {
                                required property color modelData
                                required property int index
                                swatchSize: 30
                                swatchColor: modelData
                                interactive: root.isManual
                                selected: root.selectedIndex(root.currentSecondary) === index
                                onClicked: SettingsStore.setManualSecondary(modelData.toString())
                            }
                        }
                    }
                }
            }
        }
    }
}
