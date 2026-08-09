.pragma library

// Pure helpers over niri `outputs` data (from `niri msg -j outputs`).
// Kept as plain JS so parsing/sorting/labeling stay unit-testable and free
// of QML object overhead. MonitorStore delegates here.

function parseMonitors(raw) {
    const data = JSON.parse(raw);
    const list = [];
    for (const connector in data) {
        if (!data.hasOwnProperty(connector)) continue;
        const m = data[connector];
        const logical = m.logical || {};
        list.push({
            connector: connector,
            name: m.name || connector,
            make: m.make || "",
            model: m.model || "",
            serial: m.serial || "",
            width: logical.width || 0,
            height: logical.height || 0,
            x: logical.x || 0,
            y: logical.y || 0,
            scale: logical.scale || 1.0,
            transform: logical.transform || "Normal",
            modes: m.modes || [],
            currentMode: m.current_mode !== undefined ? m.current_mode : 0,
            enabled: true
        });
    }
    return list.sort((a, b) => a.x - b.x || a.y - b.y);
}

function modeLabel(mode) {
    if (!mode) return "";
    const w = mode.width || 0;
    const h = mode.height || 0;
    const hz = mode.refresh_rate ? (mode.refresh_rate / 1000).toFixed(2) : "60";
    return w + "\u00D7" + h + " @ " + hz + " Hz";
}

function currentModeLabel(monitor) {
    if (!monitor || !monitor.modes) return "";
    const idx = monitor.currentMode || 0;
    return modeLabel(monitor.modes[idx]);
}

function modeString(mode) {
    if (!mode) return "";
    return mode.width + "x" + mode.height + "@" + (mode.refresh_rate || 60000);
}
