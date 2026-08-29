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
    property int checkedAt: 0
    property bool acting: false

    readonly property bool needsAuth: root.ssh === "auth" && root.authUrl !== ""

    // The path, and the first link that is not carrying. Failures happen at
    // a hop — naming which one is the whole diagnostic, and it is what a
    // row of labels and values cannot say.
    readonly property var hops: ["turing", "tailnet", "ssh", "devbox"]
    readonly property int brokenAt: {
        if (root.tsd !== "active" || root.peer !== "online")
            return 1;
        if (root.ssh !== "ok" && root.ssh !== "unknown")
            return 2;
        return -1;
    }
    readonly property color breakColor: root.state === "error" ? Theme.error : Theme.warning

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
                else if (line.startsWith("NOW:"))
                    root.checkedAt = parseInt(line.slice(4)) || 0;
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
    ccWidgetSecondaryText: root.needsAuth
        ? "tap to authenticate"
        : (root.state === "ok" && root.days > 0
            ? "reachable · key " + root.days + "d"
            : root.detail)
    // Highlighted only when something needs you. Active styling is how the
    // real toggles (Dark Mode, Keep Awake) say "on", so a permanently lit
    // informational tile reads as a switch someone left enabled — and the
    // one state worth noticing across the room stops standing out.
    ccWidgetIsActive: root.state !== "ok" && root.state !== "unknown"

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

                // ── the path ──────────────────────────────────────────
                // Quiet when it carries. Only the failing link takes colour,
                // and only its dot moves — everything else holds still so
                // that one thing is unmistakable across a room.
                Item {
                    width: parent.width
                    height: 34

                    Row {
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: root.hops.length

                            Item {
                                required property int index
                                width: parent.width / root.hops.length
                                height: parent.height

                                readonly property bool isBreak: root.brokenAt === index
                                readonly property bool past: root.brokenAt >= 0 && index > root.brokenAt
                                readonly property color tone: isBreak
                                    ? root.breakColor
                                    : (past ? Theme.outlineMedium
                                            : (root.brokenAt < 0 && index === root.hops.length - 1
                                                ? Theme.success : Theme.surfaceTextMedium))

                                // The wire into this hop, drawn behind the dot.
                                Rectangle {
                                    visible: index > 0
                                    height: 2
                                    radius: 1
                                    color: parent.isBreak ? root.breakColor : Theme.outlineMedium
                                    opacity: parent.isBreak ? 1.0 : 0.5
                                    anchors.verticalCenter: dot.verticalCenter
                                    anchors.right: dot.left
                                    anchors.rightMargin: 4
                                    anchors.left: parent.left
                                    anchors.leftMargin: -(parent.width / 2) + 4
                                }

                                Rectangle {
                                    id: dot
                                    width: parent.isBreak ? 11 : 7
                                    height: width
                                    radius: width / 2
                                    color: parent.tone
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: parent.isBreak ? 2 : 4

                                    Behavior on width {
                                        NumberAnimation { duration: Theme.shortDuration }
                                    }

                                    SequentialAnimation on opacity {
                                        running: parent.isBreak
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 1.0;  duration: 900; easing.type: Easing.InOutQuad }
                                    }
                                }

                                StyledText {
                                    text: root.hops[parent.index]
                                    color: parent.tone
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    font.weight: parent.isBreak ? Font.Bold : Font.Normal
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width

                    StyledText {
                        text: "1Password"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        width: parent.width - opValue.width
                    }

                    StyledText {
                        id: opValue
                        text: root.op === "" ? "—" : root.op
                        color: root.op === "ok" ? Theme.surfaceText
                             : (root.op === "slow" ? Theme.surfaceVariantText : Theme.warning)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }

                // ── key expiry ────────────────────────────────────────────
                // A meter, not a row: this is a quantity of time running out,
                // and the bar says "plenty" or "soon" before the number is read.
                Column {
                    width: parent.width
                    spacing: 4

                    Row {
                        width: parent.width

                        StyledText {
                            text: "node key"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            width: parent.width - expiryValue.width
                        }

                        StyledText {
                            id: expiryValue
                            text: root.days > 0 ? root.days + "d" : "no expiry"
                            color: root.days > 0 && root.days <= 14 ? Theme.warning : Theme.surfaceText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.outlineLight

                        Rectangle {
                            // 180 days is Tailscale's full term, so the bar
                            // empties over exactly the life of the key.
                            width: parent.width * Math.max(0.02, Math.min(1, root.days / 180))
                            height: parent.height
                            radius: parent.radius
                            color: root.days > 0 && root.days <= 14 ? Theme.warning : Theme.primary
                            opacity: 0.55

                            Behavior on width {
                                NumberAnimation { duration: Theme.mediumDuration }
                            }
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

                StyledText {
                    text: root.checkedAt > 0
                        ? "checked " + Qt.formatDateTime(new Date(root.checkedAt * 1000), "HH:mm:ss")
                        : "checking…"
                    color: Theme.surfaceVariantText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: Theme.fontSizeSmall - 1
                    opacity: 0.7
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: root.needsAuth ? Theme.primary : Theme.surfaceContainerHighest
                    border.width: root.needsAuth ? 0 : Theme.layerOutlineWidth
                    border.color: Theme.outlineMedium
                    opacity: actArea.pressed ? 0.8 : 1.0

                    StyledText {
                        anchors.centerIn: parent
                        text: root.needsAuth ? "Authenticate in browser" : "Check again"
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
