pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Thumbnails and the average colour of each picture, made with ImageMagick
// into ~/.cache/glueqs/thumbs and kept between runs. Without magick the
// picker shows the pictures themselves and the colour filters stay empty.
Singleton {
    id: root
    readonly property string cache: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/glueqs/thumbs"
    property var thumbs: ({})   // path -> thumbnail path
    property var colors: ({})   // path -> "rrggbb"
    property int version: 0
    property bool busy: scan.running
    property string pendingDir: ""

    function thumb(path) { return thumbs[path] ?? path }

    function load(dir) {
        if (scan.running) { pendingDir = dir; return; }
        scan.dir = dir;
        scan.running = true;
    }

    Process {
        id: scan
        property string dir: ""
        command: ["sh", "-c", `
            dir=$1; c=$2; mkdir -p "$c"
            command -v magick >/dev/null 2>&1 || m=0
            for f in "$dir"/*; do
                [ -f "$f" ] || continue
                case "$(printf %s "\${f##*.}" | tr A-Z a-z)" in jpg|jpeg|png|webp|bmp|gif|avif|jxl) ;; *) continue;; esac
                [ "$m" = 0 ] && continue
                h=$(printf %s "$f" | md5sum | cut -c1-16); t="$c/$h.jpg"; k="$c/$h.hex"
                if [ ! -s "$t" ] || [ "$f" -nt "$t" ]; then
                    MAGICK_THREAD_LIMIT=1 nice magick "$f[0]" -resize 'x480>' -quality 82 "$t" 2>/dev/null; rm -f "$k"
                fi
                [ -s "$k" ] || magick "$t" -modulate 100,200 -resize '1x1^' -gravity center -extent 1x1 -depth 8 -format '%[hex:p{0,0}]' info:- > "$k" 2>/dev/null
                printf '%s|%s|%s\\n' "$f" "$t" "$(cat "$k" 2>/dev/null)"
            done`, "glueqs", dir, root.cache]
        stdout: SplitParser {
            onRead: line => {
                const p = line.split("|");
                if (p.length < 3) return;
                root.thumbs[p[0]] = p[1];
                if (p[2] !== "") root.colors[p[0]] = p[2].slice(0, 6);
                root.version++;
            }
        }
        onExited: if (root.pendingDir !== "") { const d = root.pendingDir; root.pendingDir = ""; root.load(d); }
    }

    // which filter a colour falls into, by hue, like the hypr picker
    function bucket(hex) {
        if (!hex || hex.length < 6) return "";
        const r = parseInt(hex.slice(0, 2), 16) / 255, g = parseInt(hex.slice(2, 4), 16) / 255, b = parseInt(hex.slice(4, 6), 16) / 255;
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn;
        const s = mx === 0 ? 0 : d / mx;
        if (s < 0.05 || mx < 0.08) return "mono";
        let h;
        if (d === 0) h = 0;
        else if (mx === r) h = 60 * (((g - b) / d) % 6);
        else if (mx === g) h = 60 * ((b - r) / d + 2);
        else h = 60 * ((r - g) / d + 4);
        if (h < 0) h += 360;
        if (h >= 345 || h < 15) return "red";
        if (h < 45) return "orange";
        if (h < 75) return "yellow";
        if (h < 165) return "green";
        if (h < 260) return "blue";
        if (h < 315) return "purple";
        return "pink";
    }
    readonly property var buckets: [
        { id: "red", c: "#ff4500" }, { id: "orange", c: "#ffa500" }, { id: "yellow", c: "#ffd700" },
        { id: "green", c: "#32cd32" }, { id: "blue", c: "#1e90ff" }, { id: "purple", c: "#8a2be2" },
        { id: "pink", c: "#ff69b4" }, { id: "mono", c: "#a9a9a9" }
    ]
}
