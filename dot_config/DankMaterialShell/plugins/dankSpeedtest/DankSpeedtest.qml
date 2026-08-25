pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Dank Speedtest — Control Center widget. The test itself runs in a
// DETACHED net-speedtest process (survives the popup closing — CC widget
// instances die with the popup, taking child processes with them); this
// widget only launches it and renders ~/.cache/speedtest/state. Completion
// arrives as a notification regardless of whether the popup is open.
PluginComponent {
    id: root

    property bool testing: false
    property string ping: "—"
    property string down: "—"
    property string up: "—"
    property string lastRun: ""
    property string errorMsg: ""

    function mbits(s) {
        var f = parseFloat(s);
        return isNaN(f) ? "—" : Math.round(f) + " Mb/s";
    }

    function startTest() {
        if (root.testing)
            return;
        root.testing = true;   // optimistic; state file confirms
        root.errorMsg = "";
        launcher.running = true;
    }

    // Fire-and-forget: setsid -f orphans the worker so it outlives both
    // this Process object and the popup.
    Process {
        id: launcher
        running: false
        command: ["sh", "-c", "setsid -f \"$HOME/.local/bin/net-speedtest\" >/dev/null 2>&1 </dev/null"]
    }

    // State viewer: poll the worker's state file while the widget exists.
    Process {
        id: reader
        running: false
        command: ["sh", "-c", "cat \"$HOME/.cache/speedtest/state\" 2>/dev/null || echo STATUS:none"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("STATUS:")) {
                    const s = line.slice(7).trim();
                    root.testing = (s === "running");
                    if (s !== "error")
                        root.errorMsg = "";
                } else if (line.startsWith("PING:"))
                    root.ping = line.slice(5).trim();
                else if (line.startsWith("DOWN:"))
                    root.down = line.slice(5).trim();
                else if (line.startsWith("UP:"))
                    root.up = line.slice(3).trim();
                else if (line.startsWith("AT:"))
                    root.lastRun = line.slice(3).trim();
                else if (line.startsWith("ERR:"))
                    root.errorMsg = line.slice(4).trim();
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }

    // ── Control Center pill ──
    ccWidgetIcon: root.testing ? "pending" : "speed"
    ccWidgetPrimaryText: "Speed Test"
    ccWidgetSecondaryText: root.testing
        ? "testing… ~30s (popup can close)"
        : (root.errorMsg !== ""
            ? "failed — expand for details"
            : (root.down !== "—"
                ? "↓ " + root.mbits(root.down) + "  ↑ " + root.mbits(root.up)
                : "click icon to run"))
    ccWidgetIsActive: root.testing

    onCcWidgetToggled: root.startTest()

    // ── Expanded detail panel ──
    ccDetailContent: Component {
        Rectangle {
            implicitHeight: detailCol.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: detailCol
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                Repeater {
                    model: [
                        { icon: "network_ping", label: "Ping", value: root.ping },
                        { icon: "arrow_downward", label: "Download", value: root.down },
                        { icon: "arrow_upward", label: "Upload", value: root.up }
                    ]
                    delegate: Row {
                        required property var modelData
                        spacing: Theme.spacingS
                        DankIcon {
                            name: parent.modelData.icon
                            size: 18
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: parent.modelData.label + ":  "
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: parent.modelData.value
                            color: Theme.surfaceText
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                StyledText {
                    visible: root.errorMsg !== ""
                    text: root.errorMsg
                    color: Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                StyledText {
                    visible: root.lastRun !== ""
                    text: (root.testing ? "started " : "last run ") + root.lastRun
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: root.testing ? Theme.surfaceVariant : Theme.primary
                    opacity: runArea.pressed ? 0.8 : 1.0

                    StyledText {
                        anchors.centerIn: parent
                        text: root.testing ? "testing… feel free to close this" : "Run speed test"
                        color: root.testing ? Theme.surfaceVariantText : Theme.primaryText
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: runArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.testing
                        onClicked: root.startTest()
                    }
                }
            }
        }
    }
}
