// Results panel — adapted from Clavis Shell for Manatee Desktop.
// Three views: app list, wallpaper grid, clipboard history.
// All colors from Theme.* (pywal palette).

import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../"

Item {
    id: root

    required property var style
    required property string mode
    required property var results
    required property int selectedIndex

    property bool loading: false
    property bool providerAvailable: true
    property var providerError: null
    property real availableHeight: 100000
    property real contentOpacity: 1

    readonly property int modeIndex: mode === "wallpapers"
        ? 1 : (mode === "clipboard" ? 2 : 0)
    readonly property int clipboardHeaderHeight:
        mode === "clipboard" ? 46 : 0
    readonly property int wallpaperColumnCount:
        style.wallpaperColumnsForWidth(wallpaperGrid.width)
    readonly property real wallpaperCellWidth:
        wallpaperGrid.width / Math.max(1, wallpaperColumnCount)
    readonly property real wallpaperPreviewWidth:
        Math.max(1, wallpaperCellWidth - style.wallpaperGridGap)
    readonly property real wallpaperPreviewHeight:
        wallpaperPreviewWidth / style.wallpaperPreviewAspectRatio
    readonly property real wallpaperCellHeight:
        wallpaperPreviewHeight + style.wallpaperLabelGap
        + style.wallpaperLabelHeight + style.wallpaperGridGap
    readonly property Item blurRegionItem: panelSurface
    readonly property bool modalActive: false

    readonly property int targetHeight: {
        if (mode === "web") return 0;
        if (loading || !providerAvailable || results.length === 0)
            return style.emptyHeight + clipboardHeaderHeight;
        if (mode === "wallpapers")
            return Math.min(style.wallpaperGridHeight,
                Math.max(style.emptyHeight, availableHeight));
        return Math.min(style.resultMaxHeight,
            results.length * style.resultRowHeight
            + style.resultPadding * 2 + clipboardHeaderHeight);
    }

    signal selectionRequested(int index)
    signal activationRequested(int index, bool keepOpen)
    signal deleteRequested(int index)

    height: targetHeight
    opacity: mode !== "web" ? 1 : 0
    visible: height > 0.5 || opacity > 0.01

    Behavior on height {
        NumberAnimation {
            duration: root.style.panelDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.style.panelCurve
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.style.panelDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.style.effectsCurve
        }
    }

    onModeChanged: {
        root.contentOpacity = 0;
        contentFade.restart();
    }

    onSelectedIndexChanged: ensureCurrentVisible()

    function iconSource(icon) {
        if (!icon) return "";
        if (String(icon).startsWith("/")) return "file://" + icon;
        if (String(icon).startsWith("file://") || String(icon).startsWith("image://"))
            return icon;
        return "image://icon/" + icon;
    }

    function navigationStep(direction) {
        return mode === "wallpapers"
            ? direction * wallpaperColumnCount : direction;
    }

    function ensureCurrentVisible() {
        if (selectedIndex < 0 || results.length === 0) return;
        if (mode === "wallpapers")
            wallpaperGrid.positionViewAtIndex(selectedIndex, GridView.Contain);
        else if (mode === "clipboard")
            clipboardList.positionViewAtIndex(selectedIndex, ListView.Contain);
        else
            appList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    NumberAnimation {
        id: contentFade
        target: root
        property: "contentOpacity"
        from: 0; to: 1
        duration: root.style.panelDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.style.effectsCurve
    }

    // ── Panel surface with shadow ────────────────────────────────────
    Rectangle {
        id: panelSurface

        anchors.fill: parent
        radius: root.style.resultRadius
        color: root.style.panelColor
        visible: false
    }

    MultiEffect {
        anchors.fill: panelSurface
        source: panelSurface
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: root.style.shadowColor
        shadowBlur: root.style.shadowBlur
        shadowVerticalOffset: root.style.shadowVerticalOffset
        shadowHorizontalOffset: 0
    }

    StackLayout {
        anchors.fill: parent
        anchors.margins: mode === "wallpapers"
            ? root.style.wallpaperPanelPadding
            : root.style.resultPadding
        currentIndex: root.modeIndex
        opacity: root.contentOpacity

        // ── App list ────────────────────────────────────────────────
        ListView {
            id: appList

            clip: true
            spacing: 0
            model: root.mode === "apps" ? root.results : []
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: appDelegate

                required property int index
                required property var modelData
                width: ListView.view.width
                height: root.style.resultRowHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl
                    color: appDelegate.index === root.selectedIndex
                        ? root.style.selectedColor
                        : (appMouse.containsMouse
                            ? root.style.hoverColor : "transparent")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 16
                    spacing: 14

                    Image {
                        Layout.preferredWidth: root.style.resultIconSize
                        Layout.preferredHeight: root.style.resultIconSize
                        source: root.iconSource(appDelegate.modelData.icon)
                        sourceSize.width: root.style.resultIconSize * 2
                        sourceSize.height: root.style.resultIconSize * 2
                        asynchronous: true
                        fillMode: Image.PreserveAspectFit
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: appDelegate.modelData.title
                            color: appDelegate.index === root.selectedIndex
                                ? root.style.selectedContentColor
                                : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: appDelegate.modelData.subtitle
                            color: appDelegate.index === root.selectedIndex
                                ? root.style.selectedContentColor
                                : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                    }

                    // Enter key icon — Nerd Font
                    Text {
                        text: "\u21b5"
                        font.family: Theme.fontMono
                        font.pixelSize: 19
                        color: root.style.selectedContentColor
                        opacity: appDelegate.index === root.selectedIndex ? 0.78 : 0
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: appMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectionRequested(appDelegate.index);
                        root.activationRequested(appDelegate.index, false);
                    }
                }
            }
        }

        // ── Wallpaper grid ──────────────────────────────────────────
        GridView {
            id: wallpaperGrid

            clip: true
            model: root.mode === "wallpapers" ? root.results : []
            currentIndex: root.selectedIndex
            cellWidth: wallpaperCellWidth
            cellHeight: wallpaperCellHeight
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: wallpaperDelegate

                required property int index
                required property var modelData
                width: wallpaperGrid.cellWidth
                height: wallpaperGrid.cellHeight

                Rectangle {
                    id: wallpaperCard

                    anchors.fill: parent
                    anchors.margins: root.style.wallpaperGridGap / 2
                    radius: Theme.radiusControl
                    color: wallpaperDelegate.index === root.selectedIndex
                        ? root.style.selectedColor
                        : (wallpaperMouse.containsMouse
                            ? root.style.hoverColor : "transparent")

                    Item {
                        id: previewFrame
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        height: width / root.style.wallpaperPreviewAspectRatio

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.surfaceElev
                        }

                        Image {
                            anchors.fill: parent
                            source: wallpaperDelegate.modelData.preview
                            sourceSize.width: Math.ceil(previewFrame.width * 2)
                            sourceSize.height: Math.ceil(previewFrame.height * 2)
                            asynchronous: true
                            cache: true
                            smooth: true
                            fillMode: Image.PreserveAspectCrop
                            scale: wallpaperMouse.containsMouse
                                ? root.style.wallpaperHoverScale : 1

                            Behavior on scale {
                                NumberAnimation {
                                    duration: root.style.wallpaperHoverDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: root.style.wallpaperHoverCurve
                                }
                            }
                        }
                    }

                    Text {
                        anchors.top: previewFrame.bottom
                        anchors.topMargin: root.style.wallpaperLabelGap
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        height: root.style.wallpaperLabelHeight
                        text: wallpaperDelegate.modelData.title
                        color: wallpaperDelegate.index === root.selectedIndex
                            ? root.style.selectedContentColor
                            : Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: root.style.wallpaperLabelFontSize
                        font.weight: Font.Medium
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideMiddle
                    }
                }

                MouseArea {
                    id: wallpaperMouse
                    anchors.fill: wallpaperCard
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectionRequested(wallpaperDelegate.index);
                        root.activationRequested(wallpaperDelegate.index, false);
                    }
                }
            }
        }

        // ── Clipboard list ──────────────────────────────────────────
        ListView {
            id: clipboardList

            clip: true
            spacing: 0
            model: root.mode === "clipboard" ? root.results : []
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds

            delegate: Item {
                id: clipboardDelegate

                required property int index
                required property var modelData
                width: ListView.view.width
                height: root.style.resultRowHeight

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radiusControl
                    color: clipboardDelegate.index === root.selectedIndex
                        ? root.style.selectedColor
                        : (clipMouse.containsMouse
                            ? root.style.hoverColor : "transparent")
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 16
                    spacing: 13

                    // Nerd Font clipboard icon
                    Text {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        text: "\uf0ea"
                        font.family: Theme.fontMono
                        font.pixelSize: 22
                        color: clipboardDelegate.index === root.selectedIndex
                            ? root.style.selectedContentColor
                            : Theme.primary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: clipboardDelegate.modelData.title
                            color: clipboardDelegate.index === root.selectedIndex
                                ? root.style.selectedContentColor
                                : Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: clipboardDelegate.modelData.subtitle
                            color: clipboardDelegate.index === root.selectedIndex
                                ? root.style.selectedContentColor
                                : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            maximumLineCount: 1
                            elide: Text.ElideRight
                        }
                    }

                    // Delete button — Nerd Font trash
                    Text {
                        text: "\uf014"
                        font.family: Theme.fontMono
                        font.pixelSize: 18
                        color: Theme.textTertiary
                        opacity: clipMouse.containsMouse ? 1.0 : 0.4
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -8
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteRequested(clipboardDelegate.index)
                        }
                    }
                }

                MouseArea {
                    id: clipMouse
                    anchors.fill: parent
                    anchors.rightMargin: 42
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectionRequested(clipboardDelegate.index);
                        root.activationRequested(clipboardDelegate.index, false);
                    }
                }
            }
        }
    }

    // ── Empty state ──────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        anchors.topMargin: clipboardHeaderHeight
        visible: loading || !providerAvailable || results.length === 0
        opacity: root.contentOpacity

        Column {
            anchors.centerIn: parent
            spacing: 10

            // Nerd Font search-off icon
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !root.loading
                text: "\uf002"
                font.family: Theme.fontMono
                font.pixelSize: 32
                color: Theme.textTertiary
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(520, root.width - 48)
                text: root.loading
                    ? "Loading…"
                    : (!root.providerAvailable
                        ? (root.providerError
                            ? root.providerError.message
                            : "Provider unavailable")
                        : "No results found")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }
        }
    }
}
