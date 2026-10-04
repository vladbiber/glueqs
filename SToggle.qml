import QtQuick

// A row with a switch bound to one key of the shell settings.
GwRow {
    id: st
    property string skey: ""
    GwToggle { bound: true; value: Settings.s[st.skey] ?? false; onToggled: Settings.s[st.skey] = !Settings.s[st.skey] }
}
