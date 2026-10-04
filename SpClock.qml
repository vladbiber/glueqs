import QtQuick

// CLOCK
Column {
    width: parent.width
    spacing: 0
    GwTitle { first: true; text: "FORMAT"; sub: "Click the clock in the bar for the calendar." }
    GwCard {
        SToggle { label: "12-hour format"; skey: "clock12h" }
        SToggle { label: "Show the date"; skey: "showDate" }
    }
}
