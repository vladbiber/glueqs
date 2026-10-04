import QtQuick

// Number with steppers and a typed field: clamps to min..max, keeps the
// requested decimals and shows the unit after the field.
Row {
    id: root
    property string key: ""
    property real min: 0
    property real max: 100
    property real step: 1
    property int decimals: 0
    property string unit: ""
    property int fieldWidth: 74
    // bound values override the key when set (used by the monitors page)
    property bool bound: false
    property real value: 0
    signal changed(real v)

    readonly property real current: bound ? value : Gluewc.getNum(key)
    spacing: 6

    function fmt(v) { return decimals > 0 ? v.toFixed(decimals) : String(Math.round(v)) }
    function apply(v) {
        if (isNaN(v)) return;
        v = Math.min(max, Math.max(min, v));
        if (bound) root.changed(v);
        else Gluewc.set(key, fmt(v));
    }

    GwButton {
        anchors.verticalCenter: parent.verticalCenter
        label: "-"; small: true; implicitWidth: 26
        onClicked: root.apply(root.current - root.step)
    }
    GwField {
        anchors.verticalCenter: parent.verticalCenter
        width: root.fieldWidth
        align: Text.AlignHCenter
        text: root.fmt(root.current)
        onCommitted: v => root.apply(parseFloat(v))
    }
    GwButton {
        anchors.verticalCenter: parent.verticalCenter
        label: "+"; small: true; implicitWidth: 26
        onClicked: root.apply(root.current + root.step)
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        text: root.unit
        color: Theme.muted
        font.family: Theme.uiFont
        font.pixelSize: 12
    }
}
