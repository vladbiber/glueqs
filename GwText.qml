import QtQuick

// Free text for a string key.
GwField {
    property string key: ""
    width: 220
    text: Gluewc.get(key)
    onCommitted: v => Gluewc.set(key, v.trim())
}
