// Spotlight search bar for Manatee Desktop.
// Search input with three mode buttons (apps, wallpapers, clipboard).

import QtQuick
import "../"

Item {
    id: root

    required property var style
    required property string mode
    required property bool modeRailExpanded
    required property int modeFocusIndex
    required property real railProgress

    property alias text: searchInput.text
    property real requestedMainWidth: style.searchWidth
    readonly property bool inputActiveFocus: searchInput.activeFocus

    // Single blur region behind the search bar
    readonly property Item blurRegionItem: blurBg

    signal routedKey(var event)
    signal modeClicked(int index)

    height: style.searchHeight + style.effectBleed * 2

    function focusInput() { searchInput.forceActiveFocus(); }

    // ── Background surface ───────────────────────────────────────────
    Rectangle {
        id: blurBg
        x: (root.width - root.requestedMainWidth) / 2
        y: style.effectBleed
        width: root.requestedMainWidth
        height: root.style.searchHeight
        radius: root.style.searchHeight / 2
        color: root.style.surfaceColor
    }

    MultiEffect {
        anchors.fill: blurBg; source: blurBg
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: root.style.shadowColor
        shadowBlur: root.style.shadowBlur
        shadowVerticalOffset: root.style.shadowVerticalOffset
    }

    // ── Search input ─────────────────────────────────────────────────
    Item {
        x: (root.width - root.requestedMainWidth) / 2
        y: style.effectBleed
        width: root.requestedMainWidth
        height: style.searchHeight
        clip: true

        Text {
            x: style.searchHorizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf002"  // Nerd Font magnifying glass
            font.family: Theme.fontMono
            font.pixelSize: style.searchIconSize
            color: Theme.textSecondary
        }

        TextInput {
            id: searchInput
            x: style.searchHorizontalPadding + style.searchIconSize + 14
            width: parent.width - x - style.searchHorizontalPadding
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textPrimary
            selectionColor: Theme.primary
            selectedTextColor: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: 20
            verticalAlignment: TextInput.AlignVCenter
            selectByMouse: true; clip: true; focus: true
            activeFocusOnTab: false
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => root.routedKey(event)

            // Placeholder
            Text {
                anchors.fill: parent
                text: "Search apps…"
                color: Theme.textTertiary
                font: searchInput.font
                verticalAlignment: Text.AlignVCenter
                opacity: searchInput.text.length === 0 ? 1 : 0
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            propagateComposedEvents: true
            onPressed: mouse => { root.focusInput(); mouse.accepted = false; }
        }
    }

    // ── Mode buttons ─────────────────────────────────────────────────
    Repeater {
        model: [
            { icon: "\uf12c", label: "Apps" },       // Nerd Font apps
            { icon: "\uf03e", label: "Wallpapers" },  // Nerd Font image
            { icon: "\uf0ea", label: "Clipboard" }    // Nerd Font clipboard
        ]

        delegate: Item {
            id: modeBtn
            required property int index
            required property var modelData
            readonly property bool active:
                (index === 0 && root.mode === "apps")
                || (index === 1 && root.mode === "wallpapers")
                || (index === 2 && root.mode === "clipboard")
            readonly property bool focused:
                root.modeRailExpanded && root.modeFocusIndex === index

            // Position: right of search bar, evenly spaced
            x: (root.width - root.requestedMainWidth) / 2
                + root.requestedMainWidth + style.modeButtonGap
                + index * (style.modeButtonDiameter + style.modeButtonGap)
            y: root.height / 2 - style.modeButtonDiameter / 2
            width: style.modeButtonDiameter; height: width

            Rectangle {
                anchors.fill: parent; radius: width / 2
                color: btnMouse.pressed ? Theme.withAlpha(Theme.primary, 0.22)
                    : modeBtn.focused ? Theme.withAlpha(Theme.primary, 0.18)
                    : btnMouse.containsMouse ? Theme.hoverColor : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: modeBtn.modelData.icon
                font.family: Theme.fontMono; font.pixelSize: 20
                color: modeBtn.focused || modeBtn.active ? Theme.primary : Theme.textSecondary
            }

            MouseArea {
                id: btnMouse
                anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { root.modeClicked(modeBtn.index); root.focusInput(); }
            }
        }
    }
}
