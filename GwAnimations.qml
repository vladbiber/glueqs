import QtQuick

// Animations page: the switch, the durations, open and close styles and
// their cubic-bezier curves, each drawn so the numbers mean something.
Column {
    id: page
    spacing: 0
    readonly property var types: [
        { v: "zoom", label: "ZOOM" }, { v: "slide", label: "SLIDE" },
        { v: "fade", label: "FADE" }, { v: "none", label: "NONE" }
    ]

    component CurveRow: Item {
        id: crow
        property string key: ""
        property string label: ""
        readonly property var pts: {
            const p = Gluewc.get(key).split(",").map(parseFloat);
            return p.length === 4 && !p.some(isNaN) ? p : [0.25, 0.1, 0.25, 1];
        }
        width: parent.width
        implicitHeight: 96
        Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: parent.width - 96 - 24
            spacing: 6
            Text { text: crow.label; color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 13; font.weight: Font.Medium }
            Text {
                text: "cubic-bezier x1,y1,x2,y2 like CSS" + (Gluewc.hasDefault(crow.key) ? "   ·   default " + Gluewc.defaults[crow.key] : "")
                color: "#9a9a9a"; font.family: Theme.uiFont; font.pixelSize: 11
            }
            Row {
                spacing: 8
                GwField {
                    width: 190
                    text: Gluewc.get(crow.key)
                    onCommitted: v => {
                        const p = v.split(",").map(s => parseFloat(s.trim()));
                        if (p.length === 4 && !p.some(isNaN)) Gluewc.set(crow.key, p.join(","));
                    }
                }
                GwButton {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Gluewc.hasDefault(crow.key) && !Gluewc.isDefault(crow.key)
                    label: "RESET"; small: true
                    onClicked: Gluewc.reset(crow.key)
                }
            }
        }
        Rectangle {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: 96; height: 72
            radius: 8
            color: "#0a0a0a"
            border.color: Theme.blockBorder
            Canvas {
                anchors { fill: parent; margins: 10 }
                property var pts: crow.pts
                property color accent: Theme.red
                onPtsChanged: requestPaint()
                onAccentChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height, p = pts;
                    ctx.strokeStyle = "#2a2a2a"; ctx.lineWidth = 1;
                    ctx.beginPath(); ctx.moveTo(0, h); ctx.lineTo(w, 0); ctx.stroke();
                    ctx.strokeStyle = String(accent); ctx.lineWidth = 2;
                    ctx.beginPath(); ctx.moveTo(0, h);
                    ctx.bezierCurveTo(p[0] * w, h - p[1] * h, p[2] * w, h - p[3] * h, w, 0);
                    ctx.stroke();
                }
            }
        }
        Rectangle { anchors { left: parent.left; right: parent.right; bottom: parent.bottom } height: 1; color: "#1a1a1a" }
    }

    GwTitle { first: true; text: "MOTION"; sub: "Window moves, workspace switches and the overview all follow these." }
    GwRow { label: "Animations"; key: "animations"
        GwToggle { key: "animations" } }
    GwRow { label: "Duration"; hint: "Moves, resizes, workspace switches"; key: "animation_duration"; unit: "ms"
        GwNumber { key: "animation_duration"; min: 0; max: 1500; step: 20; unit: "ms" } }

    GwTitle { text: "OPENING"; sub: "zoom pops the window out of its own centre, slide brings it in from below, fade is opacity only." }
    GwRow { label: "Style"; key: "animation_type_open"
        GwChoice { key: "animation_type_open"; options: page.types } }
    GwRow { label: "Duration"; key: "animation_duration_open"; unit: "ms"
        GwNumber { key: "animation_duration_open"; min: 0; max: 1500; step: 20; unit: "ms" } }
    GwRow { label: "Start size"; hint: "How small a zoomed window starts, as a share of its final size"; key: "zoom_initial_ratio"
        GwNumber { key: "zoom_initial_ratio"; min: 0.05; max: 1; step: 0.02; decimals: 2 } }
    CurveRow { key: "animation_curve_open"; label: "Curve" }

    GwTitle { text: "CLOSING" }
    GwRow { label: "Style"; key: "animation_type_close"
        GwChoice { key: "animation_type_close"; options: page.types } }
    GwRow { label: "Duration"; key: "animation_duration_close"; unit: "ms"
        GwNumber { key: "animation_duration_close"; min: 0; max: 1500; step: 20; unit: "ms" } }
    GwRow { label: "End size"; hint: "How small a zoomed window ends"; key: "zoom_end_ratio"
        GwNumber { key: "zoom_end_ratio"; min: 0.05; max: 1; step: 0.02; decimals: 2 } }
    CurveRow { key: "animation_curve_close"; label: "Curve" }
}
