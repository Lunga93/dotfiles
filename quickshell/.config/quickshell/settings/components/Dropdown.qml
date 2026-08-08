import QtQuick
import QtQuick.Controls
import Quickshell
import "../.." // qmldir types

// Reusable animated dropdown. Opens a scrollable option list (top-level
// Popup, so it escapes the page's clipping) with a fade+slide transition.
// Used wherever a fixed pill row would overflow the panel width.
Item {
    id: root

    property var options: []
    property int currentIndex: -1
    property int maxVisible: 8
    property string placeholder: "Select..."
    readonly property bool popupOpen: menu.opened

    signal selected(int index)

    function openPopup(): void { menu.open() }
    function closePopup(): void { menu.close() }

    implicitWidth: 200
    implicitHeight: trigger.height

    readonly property int _listHeight: Math.min(Math.max(root.options.length, 1), root.maxVisible) * 34 + 8

    function _findViewport(): Item {
        let p = root.parent;
        while (p !== null && p !== undefined) {
            if (p === root.Window) break;
            if (p.clip === true) return p;
            p = p.parent;
        }
        return null;
    }

    readonly property Item _viewport: root._findViewport()

    // ── Trigger button ────────────────────────────────────────────
    Rectangle {
        id: trigger
        width: parent.width
        height: 38
        radius: Theme.radiusControl
        color: {
            if (area.pressed) return Theme.surfacePressed;
            if (area.containsMouse) return Theme.surfaceElev;
            return Theme.surfaceDeep;
        }
        border.color: Theme.border
        border.width: 1
        Behavior on color { ColorAnimation { duration: Theme.durationFast; easing.type: Easing.OutQuad } }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: chevron.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.currentIndex >= 0 && root.currentIndex < root.options.length
                ? root.options[root.currentIndex]
                : root.placeholder
            color: root.currentIndex >= 0 ? Theme.textPrimary : Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        PhosphorIcon {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            name: "caret-down"
            size: 13
            color: Theme.textSecondary
            rotation: menu.opened ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: Theme.durationMed; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: menu.opened ? menu.close() : menu.open()
        }

        // ── Option list ───────────────────────────────────────────
        // Popup renders in the overlay window, so it escapes the page's
        // clipping. Coordinates are relative to this trigger item.
        Popup {
            id: menu
            x: (parent.width - width) / 2
            y: {
                const vp = root._viewport;
                if (!vp) return parent.height + 6;
                const pos = root.mapToItem(vp, 0, 0);
                const below = vp.height - pos.y - root.height;
                const above = pos.y;
                const need = root._listHeight + 12;
                if (below < need && above >= need) return -root._listHeight - 6;
                if (above < need && below >= need) return parent.height + 6;
                return below >= above ? parent.height + 6 : -root._listHeight - 6;
            }
            width: root.width
            closePolicy: Popup.CloseOnPressOutside | Popup.CloseOnPressOutsideParent | Popup.CloseOnEscape
            padding: 0
            background: null

            enter: Transition {
                NumberAnimation { target: menu.contentItem; property: "opacity"; from: 0.0; to: 1.0; duration: Theme.durationMed; easing.type: Easing.OutCubic }
                NumberAnimation { target: menu.contentItem; property: "scale"; from: 0.96; to: 1.0; duration: Theme.durationMed; easing.type: Easing.OutCubic }
            }
            exit: Transition {
                NumberAnimation { target: menu.contentItem; property: "opacity"; from: 1.0; to: 0.0; duration: Theme.durationFast; easing.type: Easing.InCubic }
                NumberAnimation { target: menu.contentItem; property: "scale"; from: 1.0; to: 0.96; duration: Theme.durationFast; easing.type: Easing.InCubic }
            }

            contentItem: Rectangle {
                id: menuRect
                implicitWidth: root.width
                implicitHeight: root._listHeight
                radius: Theme.radiusControl
                color: Theme.surfaceWindow
                border.color: Theme.border
                border.width: 1
                clip: true
                opacity: 1
                scale: 1
                transformOrigin: Item.TopLeft

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    model: root.options
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: root.options.length > root.maxVisible ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        readonly property bool isActive: index === root.currentIndex

                        width: list.width - 12
                        height: 34
                        x: 6
                        radius: 8
                        color: {
                            if (isActive) return Theme.accentSoft;
                            if (rowArea.containsMouse) return Theme.surfaceHover;
                            return "transparent";
                        }
                        Behavior on color { ColorAnimation { duration: Theme.durationFast; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData
                            color: isActive ? Theme.accent : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: isActive ? Font.DemiBold : Font.Normal
                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                        }

                        MouseArea {
                            id: rowArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = index;
                                root.selected(index);
                                menu.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
