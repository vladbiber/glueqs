import QtQuick

// The band of slanted cards: narrow, dimmed ones to the sides, the focused one
// wide and lit in the middle, the one on screen tagged NOW. The frame of each
// card is the picture's own average colour. Scroll or drag to browse.
Item {
    id: strip
    property var picker
    readonly property real s: picker.s
    readonly property real itemW: picker.px(380)
    readonly property real itemH: picker.px(440)
    readonly property real wideW: itemW * 1.5
    readonly property real gap: picker.px(10)
    readonly property real skew: -0.32
    readonly property real frame: picker.px(3)
    property bool settled: false
    property string lastPath: ""

    readonly property string focused: view.currentIndex >= 0 ? (picker.files[view.currentIndex] ?? "") : ""
    function step(d) {
        if (picker.files.length === 0) return;
        view.currentIndex = Math.max(0, Math.min(picker.files.length - 1, view.currentIndex + d));
        lastPath = picker.files[view.currentIndex];
    }
    function jump(i) {
        if (picker.files.length === 0) return;
        view.currentIndex = Math.max(0, Math.min(picker.files.length - 1, i));
        lastPath = picker.files[view.currentIndex];
    }
    // set on open: land on `path` as soon as the folder listing arrives
    property string pending: ""
    function focusOn(path) {
        pending = picker.files.indexOf(path) >= 0 ? "" : path;
        settled = false;
        const i = picker.files.indexOf(path);
        view.currentIndex = i >= 0 ? i : 0;
        lastPath = picker.files[view.currentIndex] ?? "";
        view.positionViewAtIndex(view.currentIndex, ListView.Center);
        settle.restart();
    }
    Timer {
        id: settle
        interval: 80
        onTriggered: { view.positionViewAtIndex(view.currentIndex, ListView.Center); strip.settled = true; }
    }
    Connections {
        target: strip.picker
        // a new list resets the view; stay on the same picture if it is still there
        function onFilesChanged() {
            const f = strip.picker.files;
            if (strip.pending !== "" && f.indexOf(strip.pending) >= 0) { strip.focusOn(strip.pending); return; }
            const i = f.indexOf(strip.lastPath);
            view.currentIndex = i >= 0 ? i : Math.min(Math.max(0, view.currentIndex), f.length - 1);
        }
    }

    ListView {
        id: view
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: 0
        clip: false
        cacheBuffer: 2400
        model: strip.picker.files
        onMovementEnded: strip.lastPath = strip.picker.files[currentIndex] ?? strip.lastPath
        // strict centring only once the band has settled: switched on while the
        // focused card is still widening it hands focus on to the next card
        highlightRangeMode: strip.settled ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
        preferredHighlightBegin: width / 2 - (strip.wideW + strip.gap) / 2
        preferredHighlightEnd: width / 2 + (strip.wideW + strip.gap) / 2
        highlightMoveDuration: strip.settled ? Theme.ms(480) : 0
        boundsBehavior: Flickable.StopAtBounds
        // the band opens with a short zoom out
        opacity: strip.picker.visible ? 1 : 0
        scale: strip.picker.visible ? 1 : 1.06
        Behavior on opacity { NumberAnimation { duration: Theme.ms(500); easing.type: Easing.OutQuart } }
        Behavior on scale { NumberAnimation { duration: Theme.ms(650); easing.type: Easing.OutExpo } }

        header: Item { width: Math.max(0, view.width / 2 - strip.wideW / 2) }
        footer: Item { width: Math.max(0, view.width / 2 - strip.wideW / 2) }

        delegate: Item {
            id: cell
            required property string modelData
            required property int index
            readonly property bool wide: ListView.isCurrentItem
            readonly property bool isNow: modelData === strip.picker.current
            readonly property real cw: wide ? strip.wideW : strip.itemW * 0.5
            readonly property real ch: wide ? strip.itemH + strip.picker.px(30) : strip.itemH
            width: cw + strip.gap
            height: ch
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            opacity: wide ? 1 : (hov.containsMouse ? 0.85 : 0.55)
            z: wide ? 10 : 1
            Behavior on width { enabled: strip.settled; NumberAnimation { duration: Theme.ms(480); easing.type: Easing.InOutQuad } }
            Behavior on height { enabled: strip.settled; NumberAnimation { duration: Theme.ms(480); easing.type: Easing.InOutQuad } }
            Behavior on opacity { NumberAnimation { duration: Theme.ms(300) } }

            Item {
                id: card
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: ((strip.itemH - height) / 2) * strip.skew
                width: cell.cw
                height: cell.ch
                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(1, strip.skew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }
                // the frame: the picture's average colour, or the accent on the one on screen
                Rectangle {
                    anchors.fill: parent
                    color: cell.isNow ? Theme.red
                         : WallThumbs.colors[cell.modelData] ? "#" + WallThumbs.colors[cell.modelData] : Theme.border
                    Behavior on color { ColorAnimation { duration: Theme.ms(300) } }
                }
                Item {
                    anchors { fill: parent; margins: strip.frame }
                    clip: true
                    Rectangle { anchors.fill: parent; color: Theme.surface }
                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: strip.picker.px(-40)
                        // always the wide size, so widening reveals more instead of rescaling
                        width: strip.wideW + (strip.itemH + strip.picker.px(30)) * Math.abs(strip.skew) + strip.picker.px(40)
                        height: strip.itemH + strip.picker.px(30)
                        fillMode: Image.PreserveAspectCrop
                        source: { WallThumbs.version; return "file://" + WallThumbs.thumb(cell.modelData); }
                        sourceSize.height: 480
                        asynchronous: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.ms(250) } }
                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -strip.skew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    // NOW tag, upright
                    Rectangle {
                        visible: cell.isNow
                        anchors { top: parent.top; right: parent.right; topMargin: 12; rightMargin: 12 + (cell.wide ? 0 : 4) }
                        width: nowLbl.implicitWidth + 14; height: 20; radius: 5
                        color: Theme.red
                        transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -strip.skew, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1) }
                        DotText { id: nowLbl; anchors.centerIn: parent; text: "NOW"; px: 0.9; gap: 0.8; color: Theme.onAccent }
                    }
                }
                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        view.currentIndex = cell.index;
                        strip.lastPath = cell.modelData;
                        strip.picker.apply(cell.modelData);
                    }
                }
            }
        }

        // the wheel steps one card per notch-ish, either axis
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            property real acc: 0
            onWheel: w => {
                const d = Math.abs(w.angleDelta.x) > Math.abs(w.angleDelta.y) ? w.angleDelta.x : w.angleDelta.y;
                acc += d;
                if (Math.abs(acc) >= 120) { strip.step(acc > 0 ? -1 : 1); acc = 0; }
                w.accepted = true;
            }
        }
    }
}
