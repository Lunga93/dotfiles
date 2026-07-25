import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../../.."

Item {
    id: root

    property var iconThemeKeys: ["Adwaita"]
    property var iconThemeLabels: ["Adwaita"]
    property bool themesLoaded: false

    Component.onCompleted: loadThemes()

    Process {
        id: gsettingsProbe
        running: true
        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null | tr -d \"'\" | tr -d '\n'"]
        stdout: SplitParser {
            onRead: function(line) {
                if (line && line !== SettingsStore.iconTheme) {
                    SettingsStore.set("icons", "icon_theme", line);
                    SettingsStore.iconTheme = line;
                }
            }
        }
    }

    function loadThemes() {
        themeScan.start();
    }

    function addTheme(name) {
        if (!name) return;
        const names = root.iconThemeKeys;
        if (names.indexOf(name) === -1) {
            names.push(name);
            root.iconThemeKeys = names;
            root.iconThemeLabels = names;
        }
    }

    function ensureCurrentThemeInList() {
        const cur = SettingsStore.iconTheme;
        if (cur) addTheme(cur);
    }

    function indexOf(arr, value) {
        for (let i = 0; i < arr.length; i++) {
            if (arr[i] === value) return i;
        }
        return 0;
    }

    Process {
        id: themeScan
        command: ["sh", "-c",
            "find /usr/share/icons ~/.local/share/icons ~/.icons " +
            "-maxdepth 2 -name index.theme -not -path '*/hicolor/*' " +
            "2>/dev/null | sed 's|/index.theme||' | xargs -n1 basename | sort -u"]
        stdout: SplitParser {
            onRead: function(line) {
                if (line && line !== "hicolor" && line !== "default" && line !== "locolor") {
                    root.addTheme(line);
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.ensureCurrentThemeInList();
                root.themesLoaded = true;
            }
        }
    }

    component GroupShell: Column {
        id: gs
        property string header: ""
        property string accent: Theme.primary
        default property alias content: inner.data

        width: parent.width

        Row {
            spacing: 8
            leftPadding: 16
            topPadding: 12
            bottomPadding: 8
            visible: gs.header !== ""

            Rectangle {
                width: 3; height: 12; radius: 2
                anchors.verticalCenter: parent.verticalCenter
                color: gs.accent
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: gs.header
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.6
            }
        }

        Rectangle {
            width: parent.width
            height: inner.height
            radius: Theme.radiusCard
            color: Theme.surfaceElev
            border.color: Theme.border
            border.width: 1
            clip: true

            Column {
                id: inner
                width: parent.width
            }
        }
    }

    component LabelRow: Item {
        id: lr
        property string title: ""
        property string description: ""
        property string hint: ""
        default property alias control: controlSlot.data

        width: parent.width
        height: Math.max(60, textCol.height + 28)

        Column {
            id: textCol
            anchors.left: parent.left; anchors.leftMargin: 20
            anchors.right: controlSlot.left; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Text {
                text: lr.title
                color: Theme.textPrimary
                font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium
            }
            Text {
                width: parent.width
                text: lr.description
                color: Theme.textSecondary
                font.family: Theme.fontFamily; font.pixelSize: 11
                visible: lr.description !== ""
                wrapMode: Text.WordWrap
            }
            Text {
                width: parent.width
                text: lr.hint
                color: Theme.textTertiary
                font.family: Theme.fontFamily; font.pixelSize: 10
                font.italic: true
                visible: lr.hint !== ""
                wrapMode: Text.WordWrap
            }
        }

        Item {
            id: controlSlot
            anchors.right: parent.right; anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: childrenRect.width
            height: childrenRect.height
        }
    }

    Flickable {
        id: scroller
        anchors.fill: parent
        contentHeight: column.height + 32
        contentWidth: width
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 8000
        maximumFlickVelocity: 4500

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOff }

        Column {
            id: column
            width: parent.width; spacing: 0

            Item {
                width: parent.width; height: 76
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 28
                    anchors.top: parent.top; anchors.topMargin: 20
                    spacing: 4
                    Text {
                        text: "Icons"
                        color: "#f5ede0"
                        font.family: Theme.fontFamily; font.pixelSize: 24; font.weight: Font.Bold
                    }
                    Text {
                        text: "System-wide icon theme for GTK and Qt applications."
                        color: "#8a8175"
                        font.family: Theme.fontFamily; font.pixelSize: 12
                    }
                }
            }

            Column {
                x: 28; width: parent.width - 56; spacing: 18; bottomPadding: 32

                GroupShell {
                    header: "GLOBAL ICON THEME"
                    accent: Theme.primary

                    LabelRow {
                        title: "Theme"
                        description: root.themesLoaded
                            ? root.iconThemeKeys.length + " themes found"
                            : "Scanning installed themes..."
                        hint: root.indexOf(root.iconThemeKeys, SettingsStore.iconTheme) === 0
                            && SettingsStore.iconTheme
                            && SettingsStore.iconTheme !== root.iconThemeKeys[0]
                            ? "Current: " + SettingsStore.iconTheme
                            : ""

                        PillSelector {
                            options: root.iconThemeLabels
                            currentIndex: root.indexOf(root.iconThemeKeys, SettingsStore.iconTheme)
                            onSelected: function(index) {
                                if (index >= 0 && index < root.iconThemeKeys.length) {
                                    SettingsStore.setGlobalIconTheme(root.iconThemeKeys[index]);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 56
                    radius: Theme.radiusCard
                    color: Qt.rgba(1, 1, 1, 0.025)
                    border.color: Theme.border; border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Install icon themes via pacman or yay. Restart apps to see changes."
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily; font.pixelSize: 11
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width - 32; wrapMode: Text.WordWrap
                    }
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
            y: scroller.contentHeight > 0 ? (scroller.contentY / scroller.contentHeight) * parent.height : 0
            height: scroller.contentHeight > 0
                ? Math.max(40, (scroller.height / scroller.contentHeight) * parent.height) : 0
            visible: scroller.contentHeight > scroller.height
        }
    }
}
