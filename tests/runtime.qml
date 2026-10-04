import Quickshell
import QtQuick
import ".."

ShellRoot {
    id: test
    property int stage: 0
    property int ticks: 0
    property int workspaceEvents: 0
    property int screenEvents: 0
    property string initialAccent: ""
    Connections { target: WsState; function onOutputsChanged() { test.workspaceEvents++ } }
    Connections { target: Gluewc; function onPassiveOutputsChanged() { test.screenEvents++ } }
    Item { width: 720; SpTheme {} }

    function check(value, message) {
        if (!value) { console.error("FAIL: " + message); Qt.exit(1); throw new Error(message); }
    }
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            if (++test.ticks > 150) { console.error("FAIL: timeout " + Theme.wallError); Qt.exit(1); return; }
            if (!Settings.ready) return;
            if (test.stage === 0) {
                const snapshot = "TEST-1 1 2 0,2,1,0 bsp\n";
                check(WsState.parse(snapshot), "complete workspace state");
                const events = test.workspaceEvents;
                WsState.parse("");
                WsState.parse("TEST-1 1 2 0,2");
                WsState.parse(snapshot);
                check(test.workspaceEvents === events, "empty/partial/unchanged states must not recreate workspaces");
                check(WsState.available && WsState.outputs["TEST-1"].ws === 2, "workspace stays available");
                WsState.parse("TEST-1 1 3 0,2,1,1 bsp\n");
                check(WsState.outputs["TEST-1"].ws === 3, "real workspace changes apply");
                Gluewc.parseOutputs("name=TEST-1\tenabled=1\tmirror=none\tfocused=1\n");
                const screens = test.screenEvents;
                Gluewc.parseOutputs("");
                Gluewc.parseOutputs("name=TEST-1\tenabled=1\tmirror=none\tfocused=0\n");
                check(test.screenEvents === screens, "focus does not recreate screen windows");
                Gluewc.parseOutputs("name=TEST-1\tenabled=0\tmirror=none\tfocused=0\n");
                check(Gluewc.isPassive("TEST-1"), "disabled screen detected");
                Gluewc.parse("border_focus = 11223380\nborder_normal = 22334460\nnormal_mode_color = 445566aa\n");
                check(ThemeSync.borderColor("border_focus", "#abcdef") === "abcdef80", "border alpha preserved");
                Settings.s.themeScheme = "wallpaper";
                Settings.s.wallpaperSchemeType = "faithful";
                Settings.s.wallpaper = Quickshell.env("GLUE_TEST_IMAGES") + "/blue.png";
                test.stage = 1;
            } else if (test.stage === 1 && Theme.wallReady) {
                test.initialAccent = String(Theme.red);
                Settings.s.wallpaper = Quickshell.env("GLUE_TEST_IMAGES") + "/red.png";
                test.stage = 2;
            } else if (test.stage === 2 && Theme.wallBusy) {
                // Replace an outstanding request; the intermediate red must
                // never be the final palette and all consumers must catch up.
                Settings.s.wallpaper = Quickshell.env("GLUE_TEST_IMAGES") + "/green.png";
                Settings.s.wallpaperSchemeMode = "light";
                test.stage = 3;
            } else if (test.stage === 3 && Theme.wallReady) {
                check(Theme.wallPath.endsWith("green.png"), "latest wallpaper won");
                check(!Theme.dark && String(Theme.red) !== test.initialAccent, "mode and wallpaper both applied");
                ThemeSync.apply();
                test.stage = 4;
            } else if (test.stage === 4 && ThemeSync.status.indexOf("applied") >= 0) {
                check(Gluewc.get("border_focus").slice(0, 6) === String(Theme.red).slice(1), "borders follow palette");
                console.log("PASS: state stability, border alpha, wallpaper changes, latest request, terminal sync, theme UI");
                Qt.quit();
            }
        }
    }
}
