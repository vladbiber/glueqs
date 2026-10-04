import QtQuick

// The floating bar over the picker: a status pill, which screen, the colour
// filters, the name search and the folder/options button.
Rectangle {
    id: bar
    property var picker
    width: row.implicitWidth + picker.px(24)
    height: picker.px(56)
    radius: picker.px(14)
    color: Qt.alpha(Theme.panelSolid, 0.92)
    border.color: Theme.border

    MouseArea { anchors.fill: parent }   // keep clicks off the veil

    component Pill: Rectangle {
        id: pill
        property bool on: false
        property real w: bar.picker.px(44)
        signal clicked()
        width: w; height: bar.picker.px(40)
        radius: bar.picker.px(10)
        color: on ? Theme.fg : pma.containsMouse ? Theme.hover : Theme.surface
        border.color: on ? Theme.fg : Theme.border
        scale: on ? 1.08 : pma.containsMouse ? 1.04 : 1
        Behavior on scale { NumberAnimation { duration: Theme.ms(300); easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        Behavior on color { ColorAnimation { duration: Theme.ms(150) } }
        MouseArea { id: pma; anchors.fill: parent; hoverEnabled: true; onClicked: pill.clicked() }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: bar.picker.px(10)

        // status: count, or what is being made
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: stat.implicitWidth + bar.picker.px(26); height: bar.picker.px(40)
            radius: bar.picker.px(10)
            color: Theme.surface; border.color: Theme.border
            Behavior on width { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
            DotText {
                id: stat
                anchors.centerIn: parent
                text: WallThumbs.busy ? "MAKING THUMBNAILS" : bar.picker.files.length + " / " + bar.picker.allFiles.length
                px: 1.25; gap: 1
                color: WallThumbs.busy ? Theme.red : Theme.fg
            }
        }

        // which screen: everywhere, or the one the picker is on
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: bar.picker.px(6)
            Pill {
                w: allLbl.implicitWidth + bar.picker.px(20)
                on: bar.picker.target === ""
                onClicked: bar.picker.target = ""
                DotText { id: allLbl; anchors.centerIn: parent; text: "ALL"; px: 1.25; gap: 1; color: parent.on ? Theme.panelSolid : Theme.fg }
            }
            Pill {
                w: scrLbl.implicitWidth + bar.picker.px(20)
                on: bar.picker.target !== ""
                onClicked: bar.picker.target = bar.picker.screenName
                DotText { id: scrLbl; anchors.centerIn: parent; text: bar.picker.screenName.toUpperCase(); px: 1.25; gap: 1; color: parent.on ? Theme.panelSolid : Theme.fg }
            }
        }

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: bar.picker.px(28); color: Theme.border }

        // colour filters
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            on: bar.picker.filter === "all"
            onClicked: bar.picker.filter = "all"
            DotIcon { anchors.centerIn: parent; name: "grid"; px: 1.3; gap: 1; color: parent.on ? Theme.panelSolid : Theme.fg }
        }
        Repeater {
            model: WallThumbs.buckets
            delegate: Rectangle {
                id: sw
                required property var modelData
                readonly property bool on: bar.picker.filter === modelData.id
                anchors.verticalCenter: parent.verticalCenter
                width: bar.picker.px(36); height: width
                radius: bar.picker.px(10)
                color: modelData.c
                border.color: on ? Theme.fg : Theme.border
                border.width: on ? bar.picker.px(2) : 1
                scale: on ? 1.15 : sma.containsMouse ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: Theme.ms(400); easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                MouseArea { id: sma; anchors.fill: parent; hoverEnabled: true; onClicked: bar.picker.filter = sw.on ? "all" : sw.modelData.id }
            }
        }

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 1; height: bar.picker.px(28); color: Theme.border }

        // the typed search, widening while there is a query
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: bar.picker.query !== "" ? bar.picker.px(280) : bar.picker.px(44)
            height: bar.picker.px(40)
            radius: bar.picker.px(10)
            color: Theme.surface
            border.color: bar.picker.query !== "" ? Theme.fg : Theme.border
            border.width: bar.picker.query !== "" ? bar.picker.px(2) : 1
            clip: true
            Behavior on width { NumberAnimation { duration: Theme.ms(500); easing.type: Easing.OutBack; easing.overshoot: 0.5 } }
            DotIcon { id: sIcon; anchors { left: parent.left; leftMargin: bar.picker.px(14); verticalCenter: parent.verticalCenter }
                name: "search"; px: 1.1; gap: 0.8 }
            DotText {
                anchors { left: sIcon.right; leftMargin: bar.picker.px(10); verticalCenter: parent.verticalCenter }
                text: bar.picker.query.toUpperCase() + "_"
                maxWidth: parent.width - bar.picker.px(60)
                px: 1.25; gap: 1
            }
        }

        // folder and options
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            on: bar.picker.drawer
            onClicked: bar.picker.drawer = !bar.picker.drawer
            DotIcon { anchors.centerIn: parent; name: "sliders"; px: 1.1; gap: 0.8; color: parent.on ? Theme.panelSolid : Theme.fg }
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter
            w: rndLbl.implicitWidth + bar.picker.px(20)
            onClicked: Wallpapers.random(bar.picker.target)
            DotText { id: rndLbl; anchors.centerIn: parent; text: "RANDOM"; px: 1.25; gap: 1 }
        }
    }
}
