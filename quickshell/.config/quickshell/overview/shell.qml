// Workspace overview, modelled on end-4/dots-hyprland's `overviewWorkspacesToggle`
// widget, rewritten standalone so it carries no theme/service dependencies.
//
// Grid of every workspace with live window previews:
//   left click window     -> focus it
//   middle click window   -> close it
//   drag window to a cell -> move it to that workspace
//   left click empty cell -> switch to that workspace
//   1-9,0 / Escape        -> switch workspace / dismiss
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property int columns: 5
    readonly property int rows: 2
    readonly property int workspaceCount: rows * columns
    // Fraction of the monitor each workspace cell is drawn at.
    readonly property real previewScale: 0.16
    readonly property real spacing: 6
    readonly property color accent: "#33ccff"
    readonly property color scrimColor: "#b0000000"
    readonly property color cardColor: "#151515"
    readonly property color cellColor: "#232323"
    readonly property color cellHoverColor: "#2f2f2f"
    readonly property string fontFamily: "JetBrainsMono Nerd Font"

    property bool open: false
    property int dragTargetWorkspace: -1

    function setOpen(value: bool) {
        if (value === root.open)
            return;
        if (value) {
            // lastIpcObject only refreshes on demand; window geometry comes from it.
            Hyprland.refreshMonitors();
            Hyprland.refreshToplevels();
        }
        root.dragTargetWorkspace = -1;
        root.open = value;
    }

    // Layout coordinates of a monitor's usable area (reserved = bar exclusions).
    function usableRect(monitor) {
        if (!monitor)
            return null;
        const reserved = monitor.lastIpcObject?.reserved ?? [0, 0, 0, 0];
        const scale = monitor.scale > 0 ? monitor.scale : 1;
        return {
            x: monitor.x + reserved[0],
            y: monitor.y + reserved[1],
            w: Math.max(1, monitor.width / scale - reserved[0] - reserved[2]),
            h: Math.max(1, monitor.height / scale - reserved[1] - reserved[3])
        };
    }

    // Bound to Hyprland's `global` dispatcher: hl.dsp.global("quickshell:overviewToggle")
    GlobalShortcut {
        appid: "quickshell"
        name: "overviewToggle"
        description: "Toggle window overview"
        onPressed: root.setOpen(!root.open)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            required property var modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
            readonly property var usable: root.usableRect(monitor)
            readonly property real cellWidth: (usable?.w ?? 1920) * root.previewScale
            readonly property real cellHeight: (usable?.h ?? 1080) * root.previewScale

            function workspaceAt(x: real, y: real): int {
                const column = Math.floor(x / (cellWidth + root.spacing));
                const row = Math.floor(y / (cellHeight + root.spacing));
                if (column < 0 || column >= root.columns || row < 0 || row >= root.rows)
                    return -1;
                return row * root.columns + column + 1;
            }

            function focusWorkspace(id: int) {
                root.setOpen(false);
                Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
            }

            screen: modelData
            // One overview, on whichever monitor has focus.
            visible: root.open && monitor?.focused === true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-overview"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: keyHandler

                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.setOpen(false)
                Keys.onPressed: event => {
                    if (event.key < Qt.Key_0 || event.key > Qt.Key_9)
                        return;
                    const digit = event.key - Qt.Key_0;
                    panel.focusWorkspace(digit === 0 ? 10 : digit);
                    event.accepted = true;
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.setOpen(false)

                    Rectangle {
                        anchors.fill: parent
                        color: root.scrimColor
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: grid.width + 20
                    height: grid.height + 20
                    radius: 8
                    color: root.cardColor
                    border.width: 1
                    border.color: "#303030"

                    MouseArea {
                        // Swallow clicks on the card so the scrim doesn't dismiss.
                        anchors.fill: parent
                    }

                    Item {
                        id: grid

                        anchors.centerIn: parent
                        width: root.columns * panel.cellWidth + (root.columns - 1) * root.spacing
                        height: root.rows * panel.cellHeight + (root.rows - 1) * root.spacing

                        Repeater {
                            model: root.workspaceCount

                            Rectangle {
                                id: cell

                                required property int index
                                readonly property int workspaceId: index + 1
                                readonly property bool dropTarget: root.dragTargetWorkspace === workspaceId

                                x: (index % root.columns) * (panel.cellWidth + root.spacing)
                                y: Math.floor(index / root.columns) * (panel.cellHeight + root.spacing)
                                width: panel.cellWidth
                                height: panel.cellHeight
                                radius: 4
                                color: dropTarget ? root.cellHoverColor : root.cellColor
                                border.width: 2
                                border.color: dropTarget ? root.accent : (Hyprland.focusedWorkspace?.id === workspaceId ? Qt.rgba(0.2, 0.8, 1, 0.45) : "transparent")

                                Text {
                                    anchors.centerIn: parent
                                    text: cell.workspaceId
                                    color: "#3c3c3c"
                                    font.family: root.fontFamily
                                    font.pixelSize: Math.round(panel.cellHeight * 0.5)
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: panel.focusWorkspace(cell.workspaceId)
                                }
                            }
                        }

                        Repeater {
                            model: Hyprland.toplevels.values.filter(toplevel => {
                                const id = toplevel.workspace?.id ?? -1;
                                return id >= 1 && id <= root.workspaceCount;
                            })

                            Item {
                                id: win

                                required property var modelData
                                readonly property var ipc: modelData.lastIpcObject
                                readonly property int workspaceId: modelData.workspace?.id ?? 1
                                readonly property var usable: root.usableRect(modelData.monitor)
                                readonly property real cellX: ((workspaceId - 1) % root.columns) * (panel.cellWidth + root.spacing)
                                readonly property real cellY: Math.floor((workspaceId - 1) / root.columns) * (panel.cellHeight + root.spacing)
                                // Window rect as a fraction of its own monitor's usable area, so
                                // previews stay proportional across differently sized monitors.
                                readonly property real fracX: usable && ipc ? Math.max(0, (ipc.at[0] - usable.x) / usable.w) : 0
                                readonly property real fracY: usable && ipc ? Math.max(0, (ipc.at[1] - usable.y) / usable.h) : 0
                                readonly property real fracW: usable && ipc ? Math.min(1, ipc.size[0] / usable.w) : 1
                                readonly property real fracH: usable && ipc ? Math.min(1, ipc.size[1] / usable.h) : 1

                                property real dragX: 0
                                property real dragY: 0
                                property bool hovered: false

                                x: cellX + fracX * panel.cellWidth + dragX
                                y: cellY + fracY * panel.cellHeight + dragY
                                width: fracW * panel.cellWidth
                                height: fracH * panel.cellHeight
                                z: dragX !== 0 || dragY !== 0 ? 100 : (ipc?.floating ? 2 : 1)
                                opacity: modelData.monitor === panel.monitor ? 1 : 0.55

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: root.open ? win.modelData.wayland : null
                                    live: true
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: win.hovered ? "#26ffffff" : "transparent"
                                    border.width: 1
                                    border.color: modelData.activated ? root.accent : "#59595959"
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

                                    property real pressX: 0
                                    property real pressY: 0
                                    property bool dragging: false

                                    onEntered: win.hovered = true
                                    onExited: win.hovered = false

                                    onPressed: mouse => {
                                        // Cursor in grid coordinates; invariant of win's own offset.
                                        const point = win.mapToItem(grid, mouse.x, mouse.y);
                                        pressX = point.x;
                                        pressY = point.y;
                                        dragging = false;
                                    }

                                    onPositionChanged: mouse => {
                                        if (!pressed)
                                            return;
                                        const point = win.mapToItem(grid, mouse.x, mouse.y);
                                        const dx = point.x - pressX;
                                        const dy = point.y - pressY;
                                        if (!dragging && Math.abs(dx) + Math.abs(dy) < 8)
                                            return;
                                        dragging = true;
                                        win.dragX = dx;
                                        win.dragY = dy;
                                        root.dragTargetWorkspace = panel.workspaceAt(point.x, point.y);
                                    }

                                    onReleased: {
                                        if (!dragging)
                                            return;
                                        const target = root.dragTargetWorkspace;
                                        win.dragX = 0;
                                        win.dragY = 0;
                                        root.dragTargetWorkspace = -1;
                                        if (target > 0 && target !== win.workspaceId)
                                            Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${target}, follow = false, window = "address:0x${win.modelData.address}" })`);
                                    }

                                    onClicked: mouse => {
                                        if (dragging) {
                                            dragging = false;
                                            return;
                                        }
                                        if (mouse.button === Qt.MiddleButton) {
                                            Hyprland.dispatch(`hl.dsp.window.close({ window = "address:0x${win.modelData.address}" })`);
                                            return;
                                        }
                                        root.setOpen(false);
                                        Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${win.modelData.address}" })`);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
