// Friendly device-name + icon resolver. Mirrors the audio-status bash logic
// (single source of truth for naming across the wofi fallback and the panel).

pragma Singleton
import QtQuick

QtObject {
    function _kind(name: string): string {
        const n = (name || "").toLowerCase();
        if (n.includes("hdmi"))                 return "hdmi";
        if (n.includes("iec958") || n.includes("spdif")) return "optical";
        if (n.includes("bluez"))                return "bluetooth";
        if (n.includes("usb") && n.includes("headset")) return "headset";
        if (n.includes("usb") && n.includes("mic"))     return "usb-mic";
        if (n.includes("usb"))                  return "usb";
        if (n.includes("analog") || n.includes("headphones")) return "analog";
        return "other";
    }

    function sinkIcon(name: string): string {
        switch (_kind(name)) {
            case "hdmi":      return "󰽟";
            case "optical":   return "󰽛";
            case "bluetooth": return "󰂯";
            case "headset":   return "󰋋";
            case "usb":       return "󰕓";
            case "analog":    return "󰓃";
            default:          return "󰓃";
        }
    }

    function sourceIcon(name: string): string {
        switch (_kind(name)) {
            case "bluetooth": return "󰂯";
            case "usb-mic":
            case "usb":       return "󰕓";
            default:          return "󰍬";
        }
    }

    // Pull a short label from a Pipewire node — preferring the kind-based
    // human label, then the node nick set by the device, then the description.
    function sinkLabel(node: var): string {
        if (!node) return "";
        const props = node.properties || {};
        const k = _kind(node.name);
        switch (k) {
            case "hdmi": {
                const dnick = (props["node.nick"] || "").trim();
                if (dnick && dnick.toLowerCase() !== "hda nvidia") return dnick;
                if (node.name.includes("extra1")) return "HDMI 2";
                if (node.name.includes("extra2")) return "HDMI 3";
                return "HDMI";
            }
            case "optical":   return "Optical";
            case "bluetooth": return props["node.nick"] || "Bluetooth";
            case "headset":   return "USB Headset";
            case "usb":       return props["node.nick"] || "USB Audio";
            case "analog":    return "Speakers";
            default:          return props["node.nick"] || node.description || node.name;
        }
    }

    function sourceLabel(node: var): string {
        if (!node) return "";
        const props = node.properties || {};
        const k = _kind(node.name);
        switch (k) {
            case "bluetooth": return "Bluetooth Mic";
            case "usb-mic":
            case "usb":       return props["node.nick"] || "USB Mic";
            case "analog":    return "Built-in Mic";
            default:          return props["node.nick"] || node.description || node.name;
        }
    }
}
