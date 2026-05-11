import QtQuick
import QtQuick.Controls
import Quickshell
import "../../.." // qmldir types

Rectangle {
    id: root
    width: parent.width
    height: childrenRect.height
    radius: 14
    color: "#221c15"
    border.color: "#0e0a06"
    border.width: 1

    signal frequencyChanged(string freq)

    readonly property string currentFrequency: SettingsStore.get("wallpaper", "frequency") || "daily"

    function applyFrequency(freq: string): void {
        SettingsStore.set("wallpaper", "frequency", freq);
        root.frequencyChanged(freq);
        let cmd = "";
        if (freq === "off") {
            cmd = "systemctl --user disable --now daily-wallpaper.timer";
        } else if (freq === "hourly") {
            cmd = "systemctl --user disable --now daily-wallpaper.timer; mkdir -p ~/.config/systemd/user/daily-wallpaper.timer.d && cat > ~/.config/systemd/user/daily-wallpaper.timer.d/override.conf << 'EOF'\n[Timer]\nOnCalendar=\nOnCalendar=hourly\nEOF\nsystemctl --user daemon-reload && systemctl --user enable --now daily-wallpaper.timer";
        } else if (freq === "6h") {
            cmd = "systemctl --user disable --now daily-wallpaper.timer; mkdir -p ~/.config/systemd/user/daily-wallpaper.timer.d && cat > ~/.config/systemd/user/daily-wallpaper.timer.d/override.conf << 'EOF'\n[Timer]\nOnCalendar=\nOnCalendar=*-*-* 00/6:00:00\nEOF\nsystemctl --user daemon-reload && systemctl --user enable --now daily-wallpaper.timer";
        } else {
            cmd = "rm -rf ~/.config/systemd/user/daily-wallpaper.timer.d && systemctl --user daemon-reload && systemctl --user enable --now daily-wallpaper.timer";
        }
        SettingsStore.execScript(cmd);
    }

    Column {
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 36
            Text {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "SCHEDULE"
                color: "#6b6258"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                font.letterSpacing: 0.8
            }
        }

        Item {
            width: parent.width - 32
            height: 52
            x: 16

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text { text: "Frequency"; color: "#f5ede0"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                Text { text: "How often to fetch a new wallpaper"; color: "#8a8175"; font.family: Theme.fontFamily; font.pixelSize: 11 }
            }

            PillSelector {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                options: ["Off", "Hourly", "6h", "Daily"]
                currentIndex: {
                    const f = root.currentFrequency;
                    if (f === "off") return 0;
                    if (f === "hourly") return 1;
                    if (f === "6h") return 2;
                    return 3;
                }
                onSelected: function(idx) {
                    root.applyFrequency(["off", "hourly", "6h", "daily"][idx]);
                }
            }
        }

        Rectangle { width: parent.width - 32; x: 16; height: 1; color: "#0e0a06" }

        Item {
            width: parent.width
            height: 52

            Item {
                anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                Column {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 2
                    Text { text: "Skip today"; color: "#f5ede0"; font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Medium }
                    Text { text: "Keep current wallpaper for the rest of today"; color: "#8a8175"; font.family: Theme.fontFamily; font.pixelSize: 11 }
                }
                ToggleSwitch {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    checked: SettingsStore.get("wallpaper", "skip_today") === true
                    onToggled: function(state) {
                        SettingsStore.set("wallpaper", "skip_today", state);
                        SettingsStore.execScript(state
                            ? "date +%Y-%m-%d > ~/.local/share/dotfiles/skip_today"
                            : "rm -f ~/.local/share/dotfiles/skip_today");
                    }
                }
            }
        }

        Rectangle { width: parent.width - 32; x: 16; height: 1; color: "#0e0a06" }

        Item {
            width: parent.width
            height: 52

            Rectangle {
                anchors.left: parent.left; anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                height: 34
                width: fetchText.width + 32
                radius: 10
                color: fetchArea.pressed ? Qt.darker(Theme.accent, 1.2) : (fetchArea.containsMouse ? Qt.lighter(Theme.accent, 1.05) : Theme.accent)
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: fetchText
                    anchors.centerIn: parent
                    text: "Fetch new wallpaper now"
                    color: "#1a1105"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
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
