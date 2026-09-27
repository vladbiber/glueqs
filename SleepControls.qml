import QtQuick

// The SLEEP MODE card: timeouts, the media hold and the current state.
Column {
    width: parent.width
    spacing: 0
    GwCard {
        GwRow { label: "Screen off after"; hint: "Minutes without input; 0 keeps the screen on"
            GwNumber { bound: true; value: Settings.s.idleOffMin; min: 0; max: 120; step: 1; unit: "min"; onChanged: v => Settings.s.idleOffMin = Math.round(v) }
        }
        GwRow {
            label: "Suspend after"
            hint: Idle.suspendCmd !== "" ? "Minutes without input; 0 never suspends   ·   runs " + Idle.suspendCmd
                                         : "No loginctl, systemctl or zzz on this system, so there is nothing to suspend with"
            GwNumber { enabled: Idle.suspendCmd !== ""; opacity: enabled ? 1 : 0.4; bound: true; value: Settings.s.idleSuspendMin; min: 0; max: 240; step: 5; unit: "min"; onChanged: v => Settings.s.idleSuspendMin = Math.round(v) }
        }
        GwRow { label: "Not while media plays"; hint: "Wait for the player to stop, then act"
            GwToggle { bound: true; value: Settings.s.idleNotWhileMedia; onToggled: Settings.s.idleNotWhileMedia = !Settings.s.idleNotWhileMedia }
        }
        GwRow { label: "State"
            Row {
                spacing: 8
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4
                    color: Idle.state === "off" ? Theme.red : Idle.state === "armed" ? Theme.fg : Idle.state === "held" ? "#f5c518" : Theme.faint
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 330
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.WordWrap
                    text: Idle.statusText
                    color: Idle.state === "disabled" ? "#9a9a9a" : Theme.fg
                    font.family: Theme.uiFont; font.pixelSize: 12
                }
            }
        }
    }
}
