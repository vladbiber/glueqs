import QtQuick
import Qt.labs.folderlistmodel

// Under the picker's bar: the folder being looked at (crumbs, subfolders, a
// typed path, make it the shuffle folder) and the fill, transition and
// shuffle options.
Rectangle {
    id: dr
    property var picker
    width: Math.min(picker.width - 80, picker.px(980))
    height: col.implicitHeight + 28
    radius: picker.px(14)
    color: Qt.alpha(Theme.panelSolid, 0.96)
    border.color: Theme.border

    MouseArea { anchors.fill: parent }

    function parentDir(p) { const i = p.lastIndexOf("/"); return i <= 0 ? "/" : p.slice(0, i); }
    readonly property var crumbs: {
        const h = Wallpapers.homeDir;
        const out = [{ label: "/", path: "/" }];
        let acc = "";
        for (const part of picker.dir.split("/").filter(x => x !== "")) {
            acc += "/" + part;
            out.push({ label: acc === h ? "~" : part.toUpperCase(), path: acc });
        }
        return out;
    }

    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool on: false
        signal clicked()
        width: lbl.implicitWidth + 16; height: 24
        radius: 6
        color: on ? Theme.red : (cma.containsMouse ? Theme.hover : "transparent")
        border.color: on ? Theme.red : (cma.containsMouse ? Theme.fg : Theme.border)
        DotText { id: lbl; anchors.centerIn: parent; text: chip.label; maxWidth: 200; px: 0.85; gap: 0.8; color: chip.on ? Theme.onAccent : Theme.fg }
        MouseArea { id: cma; anchors.fill: parent; hoverEnabled: true; onClicked: chip.clicked() }
    }
    component Label: Item {
        property alias text: lt.text
        width: 70; height: 24
        DotText { id: lt; anchors.verticalCenter: parent.verticalCenter; px: 0.85; gap: 0.85; color: Theme.muted }
    }

    FolderListModel {
        id: dirs
        folder: "file://" + dr.picker.dir
        showFiles: false
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10

        Flow {
            width: parent.width
            spacing: 4
            Label { text: "FOLDER" }
            Chip { label: "UP"; onClicked: dr.picker.go(dr.parentDir(dr.picker.dir)) }
            Chip { label: "PICTURES"; onClicked: dr.picker.go(Wallpapers.homeDir + "/Pictures") }
            Item { width: 6; height: 1 }
            Repeater {
                model: dr.crumbs
                delegate: Row {
                    required property var modelData
                    required property int index
                    spacing: 4
                    DotText { visible: index > 0; anchors.verticalCenter: parent.verticalCenter; text: ">"; px: 0.7; gap: 0.7 }
                    Chip { label: modelData.label; on: index === dr.crumbs.length - 1; onClicked: dr.picker.go(modelData.path) }
                }
            }
        }
        Flow {
            width: parent.width
            spacing: 4
            visible: dirs.count > 0
            Label { text: "INSIDE" }
            Repeater {
                model: dirs
                delegate: Chip {
                    required property string fileName
                    required property string filePath
                    label: "/ " + fileName.toUpperCase()
                    onClicked: dr.picker.go(filePath)
                }
            }
        }
        Row {
            width: parent.width
            spacing: 8
            GwField {
                width: parent.width - useFolder.width - 8
                height: 28
                text: dr.picker.dir
                placeholder: "type a folder, or a picture's path, and press Enter"
                onCommitted: v => dr.picker.go(v)
            }
            Chip {
                id: useFolder
                anchors.verticalCenter: parent.verticalCenter
                label: dr.picker.dir === Wallpapers.dir ? "SHUFFLE FOLDER" : "USE THIS FOLDER"
                on: dr.picker.dir === Wallpapers.dir
                onClicked: Settings.s.wallpaperDir = dr.picker.dir
            }
        }
        Rectangle { width: parent.width; height: 1; color: Theme.line }
        Flow {
            width: parent.width
            spacing: 6
            Label { text: "FILL" }
            Repeater {
                model: ["crop", "fit", "stretch", "center", "tile"]
                delegate: Chip { required property string modelData; label: modelData.toUpperCase(); on: Settings.s.wallpaperFill === modelData; onClicked: Settings.s.wallpaperFill = modelData }
            }
            Item { width: 14; height: 1 }
            Label { text: "FX"; width: 30 }
            Repeater {
                model: ["fade", "wipe", "slide", "zoom", "random"]
                delegate: Chip { required property string modelData; label: modelData.toUpperCase(); on: Settings.s.wallpaperTransition === modelData; onClicked: Settings.s.wallpaperTransition = modelData }
            }
        }
        Flow {
            width: parent.width
            spacing: 6
            Label { text: "SHUFFLE" }
            Repeater {
                model: [0, 5, 15, 30, 60]
                delegate: Chip { required property int modelData; label: modelData === 0 ? "OFF" : modelData + " MIN"; on: Settings.s.wallpaperRandomMin === modelData; onClicked: Settings.s.wallpaperRandomMin = modelData }
            }
            Item { width: 14; height: 1 }
            Label { text: "COLOURS"; width: 66 }
            Chip { label: "FROM WALLPAPER"; on: Settings.s.themeScheme === "wallpaper"
                   onClicked: { Settings.s.themeScheme = Settings.s.themeScheme === "wallpaper" ? "nothing" : "wallpaper"; Settings.s.accent = ""; } }
        }
    }
}
