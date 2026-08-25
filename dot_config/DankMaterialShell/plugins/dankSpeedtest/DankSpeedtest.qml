pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Dank Speedtest — click the bar pill for a popout with an on-demand
// speedtest-cli run (ping / down / up). Saturates the link ~30s while
// testing; results stay in the pill until the next run.
PluginComponent {
    id: root

    property bool testing: false
    property string ping: "—"
    property string down: "—"
    property string up: "—"
    property string lastRun: ""
    property string errorMsg: ""

    popoutHeight: 320

    function mbits(s) {
        var f = parseFloat(s);
        return isNaN(f) ? "—" : Math.round(f) + " Mb/s";
    }

    function startTest() {
        if (root.testing)
            return;
        root.testing = true;
        root.errorMsg = "";
        proc.running = true;
    }

    Process {
        id: proc
        running: false
        command: ["sh", "-c",
            "out=$(speedtest-cli --simple 2>&1); " +
            "if [ $? -eq 0 ]; then " +
            "  echo \"$out\" | sed -n 's/^Ping: /PING:/p; s/^Download: /DOWN:/p; s/^Upload: /UP:/p'; " +
            "else echo \"ERR:$(echo \"$out\" | head -1)\"; fi; " +
            "echo DONE"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("PING:"))
                    root.ping = line.slice(5).trim();
                else if (line.startsWith("DOWN:"))
                    root.down = line.slice(5).trim();
                else if (line.startsWith("UP:"))
                    root.up = line.slice(3).trim();
                else if (line.startsWith("ERR:"))
                    root.errorMsg = line.slice(4).trim();
                else if (line.trim() === "DONE") {
                    root.testing = false;
                    root.lastRun = Qt.formatDateTime(new Date(), "HH:mm");
                }
            }
        }
    }

    // ── Bar pill ──
    horizontalBarPill: Component {
        Row {
            spacing: 3

            DankIcon {
                name: root.testing ? "pending" : "speed"
                size: 16
                color: root.testing ? Theme.warning : (root.errorMsg !== "" ? Theme.error : Theme.surfaceText)
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: root.testing
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                    onStopped: opacity = 1.0
                }
            }

            StyledText {
                visible: root.down !== "—" && !root.testing
                text: "↓" + root.mbits(root.down)
                font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: root.testing ? "pending" : "speed"
            size: 16
            color: root.testing ? Theme.warning : Theme.surfaceText
        }
    }

    // ── Popout ──
    popoutContent: Component {
        PopoutComponent {
            showCloseButton: false

            Column {
                width: parent.width
                spacing: Theme.spacingM

                Row {
                    spacing: Theme.spacingS
                    DankIcon {
                        name: "speed"
                        size: 22
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    StyledText {
                        text: "Speed Test"
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

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
                    text: "last run " + root.lastRun
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 10
                    color: root.testing ? Theme.surfaceVariant : Theme.primary
                    opacity: runArea.pressed ? 0.8 : 1.0

                    StyledText {
                        anchors.centerIn: parent
                        text: root.testing ? "testing… (~30s, saturates the link)" : "Run speed test"
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
