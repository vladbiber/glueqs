pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Sleep mode. Stage one: after idleOffMin minutes without input the backlight
// goes to 0 through Brightness.set and comes back at the saved level on the
// first input. Stage two: after idleSuspendMin minutes the machine suspends.
// Both wait while a player is playing when idleNotWhileMedia is on, and act
// as soon as it stops. GLUEQS_IDLE_SECONDS overrides both timeouts for tests.
Singleton {
    id: root

    readonly property int testSeconds: parseInt(Quickshell.env("GLUEQS_IDLE_SECONDS") ?? "") || 0
    readonly property int offMin: Settings.s.idleOffMin
    readonly property int suspendMin: Settings.s.idleSuspendMin
    readonly property bool notWhileMedia: Settings.s.idleNotWhileMedia
    readonly property bool playing: MediaService.active !== null && MediaService.active.isPlaying
    readonly property bool held: notWhileMedia && playing

    readonly property bool offArmed: offMin > 0 && Brightness.available && Brightness.canSet
    readonly property bool suspendArmed: suspendMin > 0 && suspendCmd !== ""
    readonly property real offTimeout: testSeconds > 0 ? testSeconds : offMin * 60
    readonly property real suspendTimeout: testSeconds > 0 ? testSeconds * 3 : suspendMin * 60

    // "off" while the backlight is down because of us
    property bool screenOff: false
    property int savedPercent: -1
    property string offSince: ""

    readonly property string state: {
        if (screenOff) return "off";
        if (offMonitor.isIdle && held) return "held";
        if (offArmed || suspendArmed) return "armed";
        return "disabled";
    }
    readonly property string statusText: {
        switch (state) {
        case "off": return "Screen off since " + offSince + ". Move the mouse or press a key to bring it back.";
        case "held": return "Idle, but media is playing. The screen goes off when it stops.";
        case "armed": return (offArmed ? "Screen off after " + offMin + " min without input" : "Screen stays on")
            + (suspendArmed ? ", suspend after " + suspendMin + " min." : ".")
            + (notWhileMedia ? "  Not while media plays." : "");
        default: return "Off. Set a timeout to arm it.";
        }
    }

    function goOff() {
        if (screenOff || !offArmed) return;
        savedPercent = Brightness.percent;
        screenOff = true;
        offSince = Qt.formatTime(new Date(), "HH:mm");
        Brightness.set(0);
    }
    function restore() {
        if (!screenOff) return;
        screenOff = false;
        Brightness.set(savedPercent > 0 ? savedPercent : 50);
        savedPercent = -1;
    }

    IdleMonitor {
        id: offMonitor
        enabled: root.offArmed
        timeout: root.offTimeout
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) { if (!root.held) root.goOff(); }
            else root.restore();
        }
    }
    // media stopped while idle: act now
    onHeldChanged: if (!held && offMonitor.isIdle && offMonitor.enabled) goOff()

    // ---- suspend ----
    property string suspendCmd: ""
    Process {
        running: true
        command: ["sh", "-c",
            'if command -v loginctl >/dev/null 2>&1; then echo "loginctl suspend"; elif command -v systemctl >/dev/null 2>&1; then echo "systemctl suspend"; elif command -v zzz >/dev/null 2>&1; then echo zzz; fi']
        stdout: StdioCollector { onStreamFinished: root.suspendCmd = text.trim() }
    }
    property string lastSuspend: ""
    function suspend() {
        if (!suspendArmed || root.testSeconds > 0) { lastSuspend = "would run: " + suspendCmd; return; }
        lastSuspend = Qt.formatTime(new Date(), "HH:mm");
        Quickshell.execDetached(["sh", "-c", suspendCmd]);
    }
    IdleMonitor {
        id: suspendMonitor
        enabled: root.suspendArmed
        timeout: root.suspendTimeout
        respectInhibitors: true
        onIsIdleChanged: if (isIdle && !root.held) root.suspend()
    }
    Connections {
        target: root
        function onHeldChanged() { if (!root.held && suspendMonitor.isIdle && suspendMonitor.enabled) root.suspend() }
    }
}
