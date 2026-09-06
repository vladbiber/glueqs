#!/usr/bin/env bash
# Applies an EQ preset through EasyEffects (writes a 32-band preset and loads it).
# Usage: eq-preset.sh <flat|bass|treble|vocal|pop|rock|jazz|classic>
#        eq-preset.sh custom G1 G2 G3 G4 G5 G6 G7 G8 G9 G10
#        eq-preset.sh off        quit EasyEffects, so its sink leaves the graph
#
# EasyEffects is started as a background service, never as a window: `-l` on
# its own would pop the GUI up, and a GUI that gets closed takes the EQ sink
# with it and leaves every stream that was routed through it silent.

PRESET_DIR="$HOME/.config/easyeffects/output"
PRESET_NAME="glueqs_eq"
PRESET_FILE="$PRESET_DIR/${PRESET_NAME}.json"

command -v easyeffects >/dev/null 2>&1 || { echo "easyeffects not installed" >&2; exit 1; }

if [ "${1,,}" = off ]; then
    easyeffects -q >/dev/null 2>&1
    exit 0
fi

mkdir -p "$PRESET_DIR"

case "${1,,}" in
    flat)    G="0 0 0 0 0 0 0 0 0 0" ;;
    bass)    G="5 7 5 2 1 0 0 0 1 2" ;;
    treble)  G="-2 -1 0 1 2 3 4 5 6 6" ;;
    vocal)   G="-2 -1 1 3 5 5 4 2 1 0" ;;
    pop)     G="2 4 2 0 1 2 4 2 1 2" ;;
    rock)    G="5 4 2 -1 -2 -1 2 4 5 6" ;;
    jazz)    G="3 3 1 1 1 1 2 1 2 3" ;;
    classic) G="0 1 2 2 2 2 1 2 3 4" ;;
    custom)  shift; G="$*"; [ $(echo "$G" | wc -w) -eq 10 ] || { echo "custom needs 10 gains" >&2; exit 1; } ;;
    *) echo "unknown preset: $1" >&2; exit 1 ;;
esac

python3 - "$G" > "$PRESET_FILE" <<'EOF' || exit 1
import sys, json
gains = [float(x) for x in sys.argv[1].split()]
slider_map = {0: 0, 1: 3, 2: 6, 3: 9, 4: 12, 5: 15, 6: 18, 7: 21, 8: 24, 9: 27}
freqs = [32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630, 800,
         1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000,
         12500, 16000, 20000, 22000, 24000, 24000]
bands = {}
for i in range(32):
    gain = 0.0
    for s, b in slider_map.items():
        if i == b:
            gain = gains[s]
            break
    bands[f"band{i}"] = {"frequency": freqs[i], "gain": gain, "mode": "Bell",
                         "mute": False, "q": 1.0, "solo": False, "width": 1.0, "slope": "x1"}
preset = {"output": {"blocklist": [], "plugins_order": ["equalizer"],
          "equalizer": {"bypass": False, "input-gain": 0.0, "output-gain": 0.0,
                        "left": bands, "right": bands, "mode": "IIR",
                        "num-bands": 32, "split-channels": False}}}
print(json.dumps(preset, indent=4))
EOF

# a running instance (service or window) takes the load command over D-Bus;
# otherwise start the service first so no window appears
if ! pgrep -u "$(id -u)" -x easyeffects >/dev/null 2>&1; then
    easyeffects --gapplication-service >/dev/null 2>&1 &
    disown 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        sleep 0.3
        pgrep -u "$(id -u)" -x easyeffects >/dev/null 2>&1 && break
    done
fi
easyeffects -l "$PRESET_NAME" >/dev/null 2>&1 &
disown 2>/dev/null || true
