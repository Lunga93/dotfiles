// Shared references to top-level windows. shell.qml populates these on init;
// segments toggle popouts directly without going through the IPC + shell roundtrip.

pragma Singleton
import QtQuick

QtObject {
    id: globals

    property var audioPanel: null
    property var calendarPopout: null
    property var powerPopout: null

    function _allPopouts(): var {
        return [audioPanel, calendarPopout, powerPopout].filter(p => p !== null);
    }

    function toggle(target: var): void {
        if (!target) return;
        const opening = !target.visible;
        // Close any other open popout — single-popout-at-a-time UX.
        for (const p of _allPopouts()) {
            if (p !== target && p.visible) p.visible = false;
        }
        target.visible = opening;
    }

    function closeAll(): void {
        for (const p of _allPopouts()) p.visible = false;
    }
}
