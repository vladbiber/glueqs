import Quickshell
import QtQuick

// ABOUT: where things live, and the resets.
Column {
    id: about
    width: parent.width
    spacing: 0
    readonly property string homeDir: Quickshell.env("HOME") ?? ""
    GwTitle { first: true; text: "GLUEQS"; sub: "Dot-matrix shell for gluewc." }
    GwCard {
        GwRow { label: "Shell files"; hint: Quickshell.shellPath("").replace(about.homeDir, "~") }
        GwRow { label: "Settings"; hint: Settings.dir.replace(about.homeDir, "~") + "/settings.json" }
        GwRow { visible: Gluewc.available; label: "Compositor"; hint: Gluewc.configPath.replace(about.homeDir, "~") }
    }
    GwTitle { text: "RESET"; sub: "Each button only touches its own group; everything else stays." }
    GwCard {
        GwRow { label: "Bar layout"; hint: "Position, size and the widgets back to the defaults"
            GwButton {
                label: "RESET BAR"; danger: true
                onClicked: {
                    Settings.s.barPosition = "top";
                    Settings.s.barSolid = false;
                    Settings.s.barFloating = false;
                    Settings.s.barSize = 48;
                    Settings.s.tileSpacing = 8;
                    Settings.s.barLeft = "settings,launcher,workspaces,tray,media";
                    Settings.s.barCenter = "weather,clock,notifs";
                    Settings.s.barRight = "netspeed,network,volume,brightness,battery,power";
                }
            }
        }
        GwRow { label: "Look"; hint: "Scheme, accent, fonts, dots, corners, opacity and motion"
            GwButton {
                label: "RESET LOOK"; danger: true
                onClicked: {
                    Settings.s.themeScheme = "nothing";
                    Settings.s.accent = "";
                    Settings.s.uiFont = "";
                    Settings.s.fontWeight = 500;
                    Settings.s.dotFont = true;
                    Settings.s.dotShape = "round";
                    Settings.s.dotFill = 1.0;
                    Settings.s.scale = 1.0;
                    Settings.s.radius = 10;
                    Settings.s.borders = true;
                    Settings.s.tileOpacity = 1.0;
                    Settings.s.panelOpacity = 1.0;
                    Settings.s.animSpeed = 1.0;
                }
            }
        }
    }
}
