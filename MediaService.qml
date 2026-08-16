pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    property bool panelOpen: false
    // centre of the media tile inside the bar window, so the panel can open
    // centred under it
    property real anchorCenter: -1

    readonly property var active: {
        const ps = Mpris.players.values;
        if (!ps || ps.length === 0) return null;
        for (const p of ps)
            if (p.isPlaying) return p;
        return ps[0];
    }
}
