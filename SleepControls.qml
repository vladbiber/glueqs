import QtQuick

// The SLEEP MODE card: the switch, what it does and does not do, the
// timeouts, the media hold and the current state. Suspend sits apart because
// it is the one thing here that really stops the machine.
Column {
    width: parent.width
    spacing: 0
    GwCard {
        GwRow { label: "Sleep mode"; hint: "Turns the screen brightness down to 0 after a while without input"
            GwToggle { bound: true; value: Settings.s.sleepEnabled; onToggled: Settings.s.sleepEnabled = !Settings.s.sleepEnabled }
        }
        Item {
            width: parent.width
            implicitHeight: info.implicitHeight + 20
            Rectangle {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14; topMargin: 2; bottomMargin: 10 }
                radius: 8
                color: Qt.alpha(Theme.red, 0.08)
                border.color: Qt.alpha(Theme.red, 0.35)
            }
            Text {
                id: info
                anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 26; rightMargin: 26; topMargin: 10 }
                wrapMode: Text.WordWrap
                text: "Sleep mode only takes the brightness to 0. It does not pause or stop anything: "
                    + "music keeps playing, downloads, apps and the network keep running. "
                    + "Move the mouse or press a key and the screen comes back at the level it had."
                color: Theme.fg; font.family: Theme.uiFont; font.pixelSize: 12
            }
        }
        GwRow { label: "Screen off after"; hint: "Minutes without input"
            enabled: Settings.s.sleepEnabled; opacity: enabled ? 1 : 0.4
            GwNumber { bound: true; value: Settings.s.idleOffMin; min: 1; max: 120; step: 1; unit: "min"; onChanged: v => Settings.s.idleOffMin = Math.round(v) }
        }
        GwRow { label: "Not while media plays"; hint: "Wait for the player to stop, then act"
            GwToggle { bound: true; value: Settings.s.idleNotWhileMedia; onToggled: Settings.s.idleNotWhileMedia = !Settings.s.idleNotWhileMedia }
        }
        GwRow { label: "Keep awake"; hint: "Holds sleep mode and suspend until switched off. Also a bar button."
            GwToggle { bound: true; value: Settings.s.keepAwake; onToggled: Settings.s.keepAwake = !Settings.s.keepAwake }
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
                    color: Idle.state === "disabled" ? Theme.muted : Theme.fg
                    font.family: Theme.uiFont; font.pixelSize: 12
                }
            }
        }
    }

    GwTitle { text: "SUSPEND"; sub: "Different from sleep mode: suspend really pauses the laptop. Music stops, downloads and the network drop until you wake it." }
    GwCard {
        GwRow {
            label: "Suspend after"
            hint: Idle.suspendCmd !== "" ? "Minutes without input; 0 never suspends   ·   runs " + Idle.suspendCmd
                                         : "No loginctl, systemctl or zzz on this system, so there is nothing to suspend with"
            GwNumber { enabled: Idle.suspendCmd !== ""; opacity: enabled ? 1 : 0.4; bound: true; value: Settings.s.idleSuspendMin; min: 0; max: 240; step: 5; unit: "min"; onChanged: v => Settings.s.idleSuspendMin = Math.round(v) }
        }
    }
}
