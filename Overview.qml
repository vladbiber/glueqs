pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Whether the compositor's overview is up. gluewc publishes this to its state
// dir on every toggle; nothing else writes that file, so anything gated on
// `active` simply never appears under another compositor.
Singleton {
    id: root

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") !== ""
                                     && Quickshell.env("XDG_STATE_HOME") !== null
                                        ? Quickshell.env("XDG_STATE_HOME")
                                        : Quickshell.env("HOME") + "/.local/state") + "/gluewc"
    property bool active: false

    FileView {
        id: state
        path: root.stateDir + "/overview"
        watchChanges: true
        preload: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.active = text().trim() === "1"
        onLoadFailed: root.active = false
    }
}
