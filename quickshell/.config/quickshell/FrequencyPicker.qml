import QtQuick
import QtQuick.Controls
import Quickshell

Column {
    id: root
    width: parent.width
    spacing: 0

    readonly property string currentFrequency: SettingsStore.get("wallpaper", "frequency") || "daily"

    function applyFrequency(freq: string): void {
        SettingsStore.set("wallpaper", "frequency", freq);
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

    Item {
        width: parent.width
        height: 36
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: "AUTO ROTATION"
            color: "#6b6258"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            font.letterSpacing: 0.8
        }
    }

    Item {
        width: parent.width
        height: 64

        Item {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Frequency"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
                Text {
                    text: "How often to fetch a new wallpaper"
                    color: "#8a8175"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
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
                    const freqs = ["off", "hourly", "6h", "daily"];
                    applyFrequency(freqs[idx]);
                }
            }
        }
    }

    Rectangle {
        width: parent.width - 32
        x: 16
        height: 1
        color: "#0e0a06"
    }

    Item {
        width: parent.width
        height: 56

        Item {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: "Skip today"
                    color: "#f5ede0"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
                Text {
                    text: "Keep current wallpaper for the rest of today"
                    color: "#8a8175"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            ToggleSwitch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: SettingsStore.get("wallpaper", "skip_today") === true
                onToggled: function(state) {
                    SettingsStore.set("wallpaper", "skip_today", state);
                    if (state) {
                        SettingsStore.execScript("date +%Y-%m-%d > ~/.local/share/dotfiles/skip_today");
                    } else {
                        SettingsStore.execScript("rm -f ~/.local/share/dotfiles/skip_today");
                    }
                }
            }
        }
    }
}
