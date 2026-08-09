.pragma library

// Pure helpers over network state (from network-status / network-scan JSON).
// Kept as plain JS so formatting/sorting stay unit-testable and free of QML
// object overhead. NetworkStore and the UI delegates delegate here.

function bars(signal) {
    const s = signal || 0;
    if (s <= 0) return 0;
    const b = Math.floor(s / 25) + 1;
    return Math.min(Math.max(b, 1), 4);
}

// Nerd Font wifi glyphs, weakest → strongest.
const WIFI_GLYPHS = ["\uF143", "\uF15F", "\uF162", "\uF165", "\uF168"];

function signalGlyph(signal) {
    const b = bars(signal);
    return WIFI_GLYPHS[b] || WIFI_GLYPHS[0];
}

function typeGlyph(type, state) {
    if (state === "connected") {
        if (type === "ethernet") return "\uF080"; // 󰀀 ethernet
        if (type === "wifi") return "\uF168";     // 󰤨 wifi full
    }
    if (state === "connecting") return "\uF16A";  // 󰤪
    if (type === "ethernet") return "\uF080";
    return "\uF16D";                              // 󰤭 wifi off
}

function friendlyType(type) {
    if (type === "ethernet") return "Ethernet";
    if (type === "wifi") return "Wi-Fi";
    if (type === "vpn") return "VPN";
    if (type === "loopback") return "Loopback";
    return type || "Unknown";
}

// Sort scan results: connected first, then strongest signal. Stable for
// equal signals (preserves the original scan order).
function sortNetworks(list, connectedSsid) {
    const out = list.slice();
    out.sort((a, b) => {
        const ac = connectedSsid && a.ssid === connectedSsid ? 1 : 0;
        const bc = connectedSsid && b.ssid === connectedSsid ? 1 : 0;
        if (ac !== bc) return bc - ac;
        return (b.signal || 0) - (a.signal || 0);
    });
    return out;
}
