import Quickshell
import Quickshell.Wayland
import QtQuick

// Rich weather view: current conditions, location, details grid, 3-day forecast.
PanelWindow {
    id: root
    anchors.top: true
    margins.top: Theme.popupTop
    implicitWidth: 340
    implicitHeight: 430
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    visible: Popups.open === "weather"

    property real intro: 0
    onVisibleChanged: if (visible) { intro = 0; introAnim.restart(); Weather.refresh(); }
    NumberAnimation {
        id: introAnim
        target: root; property: "intro"
        from: 0; to: 1; duration: 700
        easing.type: Easing.OutCubic
    }
    function stage(a, b) { return Math.max(0, Math.min(1, (intro - a) / (b - a))) }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: 14
        color: "#0d0d0d"
        border.color: Theme.blockBorder
        border.width: 1

        DotIcon {
            anchors { top: parent.top; right: parent.right; margins: 14 }
            name: "x"
            px: 1.6; gap: 1
            color: wxArea.containsMouse ? Theme.red : Theme.dim
            MouseArea {
                id: wxArea
                anchors.fill: parent; anchors.margins: -6
                hoverEnabled: true
                onClicked: Popups.open = ""
            }
        }

        Column {
            anchors { fill: parent; margins: 18 }
            spacing: 12

            Row {
                spacing: 16
                opacity: root.stage(0, 0.4)
                DotIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: Weather.icon
                    px: 3.4; gap: 1.6
                    color: Theme.fg
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    DotText { text: Weather.temp.toUpperCase(); px: 3; gap: 1.4 }
                    DotText {
                        text: Weather.condition.toUpperCase()
                        maxWidth: content.width - 130
                        px: 1.1; gap: 1; color: Theme.mid
                    }
                    DotText {
                        text: (Weather.area + " " + Weather.country).toUpperCase()
                        maxWidth: content.width - 130
                        px: 0.9; gap: 0.9; color: Theme.red
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }

            Grid {
                columns: 2
                columnSpacing: 24
                rowSpacing: 8
                opacity: root.stage(0.2, 0.7)

                component Detail: Item {
                    property string label: ""
                    property string value: ""
                    width: 140; height: 24
                    DotText {
                        anchors { left: parent.left; top: parent.top }
                        text: parent.label
                        px: 0.8; gap: 0.8; color: Theme.dim
                    }
                    DotText {
                        anchors { left: parent.left; bottom: parent.bottom }
                        text: parent.value
                        px: 1.1; gap: 1
                    }
                }

                Detail { label: "FEELS LIKE"; value: Weather.feels.toUpperCase() }
                Detail { label: "HUMIDITY"; value: Weather.humidity }
                Detail { label: "WIND"; value: Weather.wind + " " + Weather.windDir }
                Detail { label: "UV INDEX"; value: Weather.uv }
                Detail { label: "SUNRISE"; value: Weather.sunrise.toUpperCase() }
                Detail { label: "SUNSET"; value: Weather.sunset.toUpperCase() }
            }

            Rectangle { width: parent.width; height: 1; color: Theme.blockBorder }

            DotText {
                text: "FORECAST"
                px: 1; gap: 1; color: Theme.dim
                opacity: root.stage(0.4, 0.9)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 26
                opacity: root.stage(0.5, 1)
                Repeater {
                    model: Weather.forecast
                    delegate: Column {
                        required property var modelData
                        spacing: 6
                        DotText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            px: 0.9; gap: 0.9
                            color: modelData.name === "TODAY" ? Theme.red : Theme.mid
                        }
                        DotIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: modelData.icon
                            px: 1.6; gap: 1
                            color: Theme.fg
                        }
                        DotText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.max
                            px: 1.2; gap: 1
                        }
                        DotText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.min
                            px: 1; gap: 1; color: Theme.dim
                        }
                    }
                }
            }

            DotText {
                text: "LOCATION IN SETTINGS / WEATHER"
                px: 0.8; gap: 0.8; color: Theme.hint
            }
        }
    }

    Timer {
        running: (Quickshell.env("GLUEQS_SHOT") ?? "") !== ""
        interval: 10600
        onTriggered: { Popups.open = "weather"; shotTimer.start(); }
    }
    Timer {
        id: shotTimer
        interval: 1400
        onTriggered: content.grabToImage(res =>
            res.saveToFile(Quickshell.env("GLUEQS_SHOT") + "/weather-" + root.screen.name + ".png"))
    }
}
