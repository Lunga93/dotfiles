import QtQuick
import QtQuick.Controls
import Quickshell

ShellRoot {
    id: root

    PanelWindow {
        id: window
        visible: true

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true

        Item {
            id: focusScope
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: Qt.quit()

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(
                    Theme.background.r,
                    Theme.background.g,
                    Theme.background.b,
                    0.86
                )

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.withAlpha(Theme.primary, 0.10) }
                        GradientStop { position: 0.6; color: "transparent" }
                    }
                }
            }
        }

        Card {
            id: card
            anchors.centerIn: parent
            implicitWidth:  Math.min(window.width  - 64, 960)
            implicitHeight: Math.min(window.height - 64, 640)
            padding: 0

            scale: window.visible ? 1.0 : 0.96
            opacity: window.visible ? 1.0 : 0.0
            Behavior on scale   { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }

            StackView {
                id: stack
                anchors.fill: parent
                clip: true
                initialItem: welcomeComp

                pushEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMed; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "x"; from: 24; to: 0; duration: Theme.durationMed; easing.type: Easing.OutCubic }
                    }
                }
                pushExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast }
                }
                popEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.durationMed; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "x"; from: -24; to: 0; duration: Theme.durationMed; easing.type: Easing.OutCubic }
                    }
                }
                popExit: Transition {
                    NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.durationFast }
                }

                Component { id: welcomeComp;   WelcomePage     { onAdvance: stack.push(overviewComp) } }
                Component { id: overviewComp;  OverviewPage    { onNext: stack.push(keybindsComp); onBack: stack.pop() } }
                Component { id: keybindsComp;  KeybindingsPage { onNext: stack.push(themingComp);  onBack: stack.pop() } }
                Component { id: themingComp;   ThemingPage     { onNext: stack.push(finishComp);   onBack: stack.pop() } }
                Component { id: finishComp;    FinishPage      { onNext: root.exit();              onBack: stack.pop() } }
            }
        }

    }

    function exit(): void {
        Quickshell.execDetached([
            "sh", "-c",
            "mkdir -p \"${XDG_STATE_HOME:-$HOME/.local/state}/manatee-welcome\" && " +
            "touch  \"${XDG_STATE_HOME:-$HOME/.local/state}/manatee-welcome/shown\""
        ]);
        Qt.quit();
    }
}
