// Spotlight launcher for Manatee Desktop.
// Full-screen overlay with search, mode switching, keyboard navigation.
// Toggle via: qs ipc call spotlight toggle

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"

PanelWindow {
    id: root

    visible: false
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }

    WlrLayershell.namespace: "manatee-spotlight"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    // ── State ────────────────────────────────────────────────────────
    property string windowPhase: "hidden"
    property string mode: "apps"
    property bool modeRailExpanded: false
    property int modeFocusIndex: -1
    property string query: ""
    property int selectedResultIndex: -1
    property string selectedResultId: ""
    property real windowProgress: 0
    property real railProgress: 0

    readonly property var activeResults: mode === "apps"
        ? appProvider.results
        : (mode === "wallpapers"
            ? wallpaperProvider.results
            : clipboardProvider.results)
    readonly property bool showing: windowPhase !== "hidden" && root.visible

    // ── Components ───────────────────────────────────────────────────
    SpotlightStyle { id: style }
    SpotlightAppProvider { id: appProvider; query: root.query }
    SpotlightWallpaperProvider { id: wallpaperProvider; query: root.query }
    SpotlightClipboardProvider { id: clipboardProvider; query: root.query }

    // ── Mode helpers ─────────────────────────────────────────────────
    function normalizedMode(value) {
        const r = String(value || "").toLowerCase();
        return r === "apps" || r === "wallpapers" || r === "clipboard" ? r : "";
    }

    function modeForIndex(index) {
        return ["apps", "wallpapers", "clipboard"][
            Math.max(0, Math.min(2, index))];
    }

    function modeIndex(value) {
        return value === "wallpapers" ? 1 : value === "clipboard" ? 2 : 0;
    }

    // ── Animation ────────────────────────────────────────────────────
    function animateWindow(target) {
        windowAnim.stop()
        windowAnim.from = windowProgress
        windowAnim.to = target
        windowAnim.duration = Math.max(1,
            (target > windowProgress ? style.windowOpenDuration : style.windowCloseDuration)
            * Math.abs(target - windowProgress))
        windowAnim.restart()
    }

    function animateRail(target) {
        railAnim.stop()
        railAnim.from = railProgress
        railAnim.to = target
        railAnim.duration = Math.max(1,
            style.railDuration * Math.abs(target - railProgress))
        railAnim.restart()
    }

    // ── Open / Close ─────────────────────────────────────────────────
    function openSpotlight(requestedMode) {
        const localMode = normalizedMode(requestedMode);
        if (localMode !== "") setLocalMode(localMode);
        else if (windowPhase === "hidden") setLocalMode("apps");

        if (mode === "clipboard") clipboardProvider.refresh();

        if (windowPhase === "open" || windowPhase === "opening") {
            focusSpotlight(); return true;
        }
        if (!visible) visible = true;
        windowPhase = "opening";
        animateWindow(1);
        focusSpotlight();
        return true;
    }

    function focusSpotlight() {
        if (!showing) return;
        Qt.callLater(() => { if (showing) searchBar.focusInput(); });
    }

    function requestClose() {
        if (windowPhase === "hidden" || windowPhase === "closing") return false;
        windowPhase = "closing";
        modeRailExpanded = false;
        modeFocusIndex = -1;
        animateRail(0);
        animateWindow(0);
        return true;
    }

    function toggleWindow() {
        return (windowPhase === "hidden" || windowPhase === "closing")
            ? openSpotlight() : requestClose();
    }

    function setLocalMode(requestedMode) {
        const localMode = normalizedMode(requestedMode);
        if (localMode === "") return false;
        selectedResultId = "";
        mode = localMode;
        selectResult(activeResults.length > 0 ? 0 : -1);
        focusSpotlight();
        return true;
    }

    function setRailExpanded(expanded) {
        if (modeRailExpanded === expanded) return;
        modeRailExpanded = expanded;
        if (!expanded) modeFocusIndex = -1;
        animateRail(expanded ? 1 : 0);
    }

    // ── Selection ────────────────────────────────────────────────────
    function selectResult(index) {
        if (activeResults.length === 0 || index < 0) {
            selectedResultIndex = -1; selectedResultId = ""; return false;
        }
        const bounded = Math.max(0, Math.min(activeResults.length - 1, index));
        const result = activeResults[bounded];
        selectedResultIndex = bounded;
        selectedResultId = result?.id !== undefined ? String(result.id) : "";
        return true;
    }

    function moveSelection(offset) {
        if (activeResults.length === 0) return;
        const cur = selectedResultIndex < 0 ? 0 : selectedResultIndex;
        selectResult(Math.max(0, Math.min(activeResults.length - 1, cur + offset)));
    }

    function activateSelected() {
        if (modeRailExpanded && modeFocusIndex >= 0) {
            setLocalMode(modeForIndex(modeFocusIndex));
            setRailExpanded(false);
            return true;
        }
        if (selectedResultIndex < 0) return false;
        if (mode === "apps" && appProvider.execute(selectedResultIndex)) {
            requestClose(); return true;
        }
        if (mode === "wallpapers") return wallpaperProvider.execute(selectedResultIndex);
        if (mode === "clipboard") return clipboardProvider.execute(selectedResultIndex);
        return false;
    }

    // ── Keyboard ─────────────────────────────────────────────────────
    function handleEscape() {
        if (modeRailExpanded || railProgress > 0.001) setRailExpanded(false);
        else if (query !== "") query = "";
        else requestClose();
    }

    function handleKey(event) {
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
        if (ctrl && event.key === Qt.Key_1) { setLocalMode("apps"); setRailExpanded(false); event.accepted = true; return; }
        if (ctrl && event.key === Qt.Key_2) { setLocalMode("wallpapers"); setRailExpanded(false); event.accepted = true; return; }
        if (ctrl && event.key === Qt.Key_3) { setLocalMode("clipboard"); setRailExpanded(false); event.accepted = true; return; }
        if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
            moveModeFocus(event.key === Qt.Key_Backtab ? -1 : 1); event.accepted = true; return; }
        if (event.key === Qt.Key_Escape) { handleEscape(); event.accepted = true; return; }
        if (event.key === Qt.Key_Up) { moveSelection(-1); event.accepted = true; return; }
        if (event.key === Qt.Key_Down) { moveSelection(1); event.accepted = true; return; }
        if (event.key === Qt.Key_Left && mode === "wallpapers") { moveSelection(-1); event.accepted = true; return; }
        if (event.key === Qt.Key_Right && mode === "wallpapers") { moveSelection(1); event.accepted = true; return; }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected(); event.accepted = true; return; }
    }

    function moveModeFocus(delta) {
        if (!modeRailExpanded) {
            modeFocusIndex = modeIndex(mode); setRailExpanded(true); return;
        }
        modeFocusIndex = (modeFocusIndex + delta + 3) % 3;
    }

    onActiveResultsChanged: {
        if (selectedResultIndex >= activeResults.length)
            selectResult(activeResults.length > 0 ? activeResults.length - 1 : -1);
        else if (selectedResultIndex < 0 && activeResults.length > 0)
            selectResult(0);
    }

    // ── Animations ───────────────────────────────────────────────────
    NumberAnimation {
        id: windowAnim; target: root; property: "windowProgress"
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.windowProgress < to ? style.windowEnterCurve : style.windowExitCurve
        onFinished: {
            if (to >= 1) { root.windowProgress = 1; root.windowPhase = "open"; root.focusSpotlight(); return; }
            root.windowProgress = 0; root.windowPhase = "hidden"; root.visible = false;
            root.query = ""; root.mode = "apps"; root.selectedResultIndex = -1;
            root.selectedResultId = ""; root.modeRailExpanded = false;
            root.modeFocusIndex = -1; root.railProgress = 0;
        }
    }

    NumberAnimation { id: railAnim; target: root; property: "railProgress"
        easing.type: Easing.BezierSpline; easing.bezierCurve: style.railCurve }

    // ── Blur ─────────────────────────────────────────────────────────
    CompositorBlurRegion {
        targetWindow: root
        backgroundItem: searchBar.blurRegionItem
        additionalBackgroundItems: [resultsPanel.blurRegionItem]
        blurEnabled: root.showing
    }

    // ── Backdrop click to close ──────────────────────────────────────
    MouseArea { anchors.fill: parent; onClicked: root.requestClose() }

    // ── Content ──────────────────────────────────────────────────────
    FocusScope {
        id: spotlightRoot
        focus: true; Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => root.handleKey(event)

        readonly property real baseY:
            Math.max(40, root.height * 0.22 - searchBar.height / 2)

        width: Math.min(
            mode === "wallpapers" ? style.wallpaperPanelWidth : style.canvasWidth,
            Math.max(360, root.width - style.windowHorizontalMargin * 2))
        height: searchBar.height + style.resultGap + resultsPanel.height
        anchors.horizontalCenter: parent.horizontalCenter
        y: baseY + style.initialYOffset * (1 - root.windowProgress)
        opacity: root.windowProgress
        scale: style.initialScale + (1 - style.initialScale) * root.windowProgress
        transformOrigin: Item.Top

        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        SpotlightSearchBar {
            id: searchBar; width: parent.width; anchors.top: parent.top
            style: style; mode: root.mode
            modeRailExpanded: root.modeRailExpanded
            modeFocusIndex: root.modeFocusIndex
            railProgress: root.railProgress
            requestedMainWidth: Math.max(420,
                Math.min(style.searchWidth, width - style.compactSideReserve))
            text: root.query
            onTextChanged: root.query = text
            onRoutedKey: event => root.handleKey(event)
            onModeClicked: index => {
                root.modeFocusIndex = index;
                root.setLocalMode(root.modeForIndex(index));
                root.setRailExpanded(false);
            }
        }

        SpotlightResultsPanel {
            id: resultsPanel
            width: mode === "wallpapers"
                ? Math.min(style.wallpaperPanelWidth, spotlightRoot.width)
                : searchBar.requestedMainWidth
            anchors.top: searchBar.bottom; anchors.topMargin: style.resultGap
            anchors.horizontalCenter: parent.horizontalCenter
            style: style; mode: root.mode; results: root.activeResults
            selectedIndex: root.selectedResultIndex
            loading: (mode === "apps" && appProvider.loading)
                || (mode === "wallpapers" && wallpaperProvider.loading)
                || (mode === "clipboard" && clipboardProvider.loading)
            providerAvailable: mode === "apps" ? appProvider.available
                : mode === "wallpapers" ? wallpaperProvider.available
                : clipboardProvider.available
            providerError: mode === "apps" ? appProvider.error
                : mode === "wallpapers" ? wallpaperProvider.error
                : clipboardProvider.error
            availableHeight: Math.max(style.emptyHeight,
                root.height - spotlightRoot.baseY - searchBar.height
                - style.resultGap - style.windowBottomMargin)
            onSelectionRequested: index => root.selectResult(index)
            onActivationRequested: index => { root.selectResult(index); root.activateSelected(); }
            onDeleteRequested: index => clipboardProvider.deleteEntry(index)
        }
    }

    // ── IPC ──────────────────────────────────────────────────────────
    function toggle(): void { toggleWindow() }
    function show(): void  { openSpotlight() }
    function hide(): void  { requestClose() }
}
