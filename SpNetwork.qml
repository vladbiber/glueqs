import QtQuick

// NETWORK: the same wifi and bluetooth controls as the bar popup, wider.
Column {
    width: parent.width
    spacing: 0
    GwTitle { first: true; text: "WIFI AND BLUETOOTH"; sub: "Switch the radios, join a network or pair a device. The same controls open from the wifi tile on the bar." }
    NetView { wide: true; active: Popups.open === "settings" }
}
