pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Dank Devbox — Control Center widget for the remote dev box.
//
// Every remote-access failure so far has been silent and has looked the
// same from the outside ("I can't connect to my box"), while needing a
// different fix each time: a firewall pinned to a stale IP, 1Password not
// running so ssh had no key, and Tailscale SSH's periodic re-auth whose
// URL goes to ssh's stderr where nothing surfaces it. This makes the
// difference visible, and — when the answer is "click this" — clickable.
//
// All state comes from `devbox-health`; nothing is computed here. The
// script is also run on a timer for notifications, so the two agree by
// construction rather than by luck.
PluginComponent {
    id: root

    property string state: "unknown"   // ok | warn | error | unknown
    property string detail: "checking…"
    property string tsd: ""
    property string peer: ""
    property string ssh: ""
    property string op: ""
    property int days: 0
    property string authUrl: ""
    property bool acting: false

    readonly property bool needsAuth: root.ssh === "auth" && root.authUrl !== ""

    function iconFor() {
        if (root.needsAuth)
            return "key";
        if (root.state === "error")
            return "cloud_off";
        if (root.state === "warn")
            return "warning";
        return "dns";
    }

    // The pill's one action is whatever the current problem needs: open the
    // auth page, or re-probe. A button that does the wrong thing quietly is
    // worse than no button.
    function act() {
        if (root.acting)
            return;
        root.acting = true;
        if (root.needsAuth)
            opener.running = true;
        else
            reader.running = true;
        resetActing.restart();
    }

    Timer {
        id: resetActing
        interval: 1500
        onTriggered: root.acting = false
    }

    Process {
        id: opener
        running: false
        command: ["sh", "-c", "xdg-open \"$(cat \"${XDG_STATE_HOME:-$HOME/.local/state}/devbox-health/authurl\")\""]
    }

    Process {
        id: reader
        running: false
        command: ["sh", "-c", "$HOME/.local/bin/devbox-health"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("STATE:"))
                    root.state = line.slice(6).trim();
                else if (line.startsWith("DETAIL:"))
                    root.detail = line.slice(7).trim();
                else if (line.startsWith("TSD:"))
                    root.tsd = line.slice(4).trim();
                else if (line.startsWith("PEER:"))
                    root.peer = line.slice(5).trim();
                else if (line.startsWith("SSH:"))
                    root.ssh = line.slice(4).trim();
                else if (line.startsWith("OP:"))
                    root.op = line.slice(3).trim();
                else if (line.startsWith("DAYS:"))
                    root.days = parseInt(line.slice(5)) || 0;
                else if (line.startsWith("AUTHURL:"))
                    root.authUrl = line.slice(8).trim();
            }
        }
    }

    // 60s: the probe opens an ssh connection, so this is not free. Nothing
    // here changes on a shorter horizon than that anyway.
    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }

    // ── Control Center pill ──
    ccWidgetIcon: root.iconFor()
    ccWidgetPrimaryText: "Dev box"
    ccWidgetSecondaryText: root.needsAuth ? "tap to authenticate" : root.detail
    ccWidgetIsActive: root.state === "ok"

    onCcWidgetToggled: root.act()

    // ── Expanded detail panel ──
    ccDetailContent: Component {
        Rectangle {
            implicitHeight: col.implicitHeight + Theme.spacingL * 2
            color: Theme.surfaceContainerHigh
            radius: Theme.cornerRadius

            Column {
                id: col
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingM

                StyledText {
                    text: root.detail
                    color: root.state === "error" ? Theme.error : Theme.surfaceText
                    font.weight: Font.Bold
                    width: parent.width
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                Repeater {
                    model: [
                        { label: "tailscaled", value: root.tsd,  warn: root.tsd !== "active" },
                        { label: "tailnet",    value: root.peer, warn: root.peer !== "online" },
                        { label: "ssh",        value: root.ssh,  warn: root.ssh !== "ok" },
                        { label: "1Password",  value: root.op,   warn: root.op !== "ok" },
                        { label: "key expires", value: root.days > 0 ? root.days + " days" : "never",
                          warn: root.days > 0 && root.days <= 14 }
                    ]

                    Row {
                        required property var modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            text: parent.modelData.label
                            color: Theme.surfaceVariantText
                            width: 110
                            elide: Text.ElideRight
                        }

                        // Bounded and elided: the value is short today, but
                        // an unbounded label in a fixed-width panel is how a
                        // row silently pushes past its edge later.
                        StyledText {
                            text: parent.modelData.value
                            color: parent.modelData.warn ? Theme.error : Theme.surfaceText
                            font.weight: Font.Bold
                            width: parent.width - 110 - Theme.spacingS
                            elide: Text.ElideRight
                        }
                    }
                }

                StyledText {
                    visible: root.needsAuth
                    text: "Tailscale's default policy re-checks SSH on a timer. Authenticating opens a browser; changing the tailnet policy from \"check\" to \"accept\" removes the prompt for good."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: root.needsAuth ? Theme.primary : Theme.surfaceVariant
                    opacity: actArea.pressed ? 0.8 : 1.0

                    StyledText {
                        anchors.centerIn: parent
                        text: root.needsAuth ? "Authenticate in browser" : "Re-check now"
                        color: root.needsAuth ? Theme.primaryText : Theme.surfaceText
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.act()
                    }
                }
            }
        }
    }
}
