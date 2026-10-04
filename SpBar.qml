import QtQuick

// BAR: where it sits and how it is drawn.
Column {
    width: parent.width
    spacing: 0
    GwTitle { first: true; text: "PLACE"; sub: "Which edge, and whether the bar touches it." }
    GwCard {
        GwRow { label: "Position"; hint: "Which screen edge"
            GwChoice {
                bound: true; value: Settings.s.barPosition
                options: [{ v: "top", label: "TOP" }, { v: "bottom", label: "BOTTOM" }, { v: "left", label: "LEFT" }, { v: "right", label: "RIGHT" }]
                onPicked: v => Settings.s.barPosition = v
            }
        }
        SToggle { label: "Floating"; hint: "A gap between the bar and the screen edge, rounded ends"; skey: "barFloating" }
        SToggle { label: "Solid background"; hint: "One strip behind the tiles instead of see-through"; skey: "barSolid" }
    }
    GwTitle { text: "SIZE"; sub: "Bar thickness and the gap between tiles. UI scale on the LOOK page scales everything at once." }
    GwCard {
        GwRow { label: "Bar size"; hint: "Thickness before scaling"
            GwNumber { bound: true; value: Settings.s.barSize; min: 32; max: 72; step: 2; unit: "px"; onChanged: v => Settings.s.barSize = Math.round(v) }
        }
        GwRow { label: "Tile spacing"
            GwNumber { bound: true; value: Settings.s.tileSpacing; min: 0; max: 24; step: 1; unit: "px"; onChanged: v => Settings.s.tileSpacing = Math.round(v) }
        }
        SToggle { label: "Tile outlines"; hint: "A hairline around each tile"; skey: "borders" }
    }
    Note { text: "Which widgets are on the bar and in what order is on the WIDGETS page." }
}
