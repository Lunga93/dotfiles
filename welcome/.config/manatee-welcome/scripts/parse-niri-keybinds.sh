#!/usr/bin/env bash
set -euo pipefail

CONFIG="${1:-$HOME/.config/niri/config.kdl}"

if [ ! -f "$CONFIG" ]; then
    echo "parse-niri-keybinds: config not found: $CONFIG" >&2
    exit 1
fi

awk '
    BEGIN { in_binds = 0; depth = 0 }

    {
        sub(/\/\/.*$/, "")
    }

    /^[[:space:]]*binds[[:space:]]*\{/ {
        in_binds = 1
        depth = 1
        next
    }

    in_binds {
        opens  = gsub(/\{/, "{")
        closes = gsub(/\}/, "}")
        depth += opens - closes
        if (depth <= 0) {
            in_binds = 0
            next
        }

        line = $0
        sub(/^[[:space:]]+/, "", line)
        sub(/[[:space:]]+$/, "", line)
        if (line == "") next

        n = index(line, " ")
        if (n == 0) n = length(line) + 1
        chord = substr(line, 1, n - 1)
        rest  = substr(line, n + 1)

        if (chord !~ /\+/ && chord !~ /^(XF86|F[0-9]+|Escape|Return|Tab|Print|Home|End|Page_(Up|Down)|Up|Down|Left|Right|Space)$/) next

        action = rest
        ob = index(rest, "{")
        cb_pos = 0
        if (ob > 0) {
            d = 0
            for (i = ob; i <= length(rest); i++) {
                ch = substr(rest, i, 1)
                if (ch == "{") d++
                else if (ch == "}") {
                    d--
                    if (d == 0) { cb_pos = i; break }
                }
            }
            if (cb_pos > 0) {
                action = substr(rest, ob + 1, cb_pos - ob - 1)
            }
        }
        sub(/^[[:space:]]+/, "", action)
        sub(/[[:space:]]+$/, "", action)
        sub(/;[[:space:]]*$/, "", action)

        gsub(/\\/, "\\\\", chord)
        gsub(/"/,  "\\\"", chord)
        gsub(/\\/, "\\\\", action)
        gsub(/"/,  "\\\"", action)
        gsub(/\t/, " ", action)

        if (count > 0) printf(",\n")
        printf("  {\"keys\": \"%s\", \"action\": \"%s\"}", chord, action)
        count++
    }

    END {
        if (count > 0) print ""
    }
' "$CONFIG" | awk 'BEGIN { print "[" } { print } END { print "]" }'
