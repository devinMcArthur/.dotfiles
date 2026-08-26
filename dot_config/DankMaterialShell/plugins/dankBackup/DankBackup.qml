pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Dank Backup — Control Center widget for the offsite restic → R2 backup.
// Pure state-file viewer: reads ~/.local/state/laptop-backup/* (progress
// written by `laptop-backup run` from restic's --json stream, plus the
// last-success/check/skip timestamp files). Needs no credentials, so it
// never pops a 1Password prompt. "Back up now" starts the systemd unit
// (--no-block) — the run belongs to systemd, not this popup.
PluginComponent {
    id: root

    property string status: "idle"   // idle | running | pruning | checking | error
    property string svc: "inactive"  // laptop-backup.service ActiveState
    property real pct: 0             // 0..1
    property real bytesDone: 0
    property real bytesTotal: 0
    property int etaSec: -1
    property real successTs: 0
    property real checkTs: 0
    property real skipTs: 0
    property real now: 0
    property bool starting: false    // optimistic, until the unit shows up

    // A "running" progress file only counts if the unit is actually alive —
    // a crashed run can't report forever.
    readonly property bool busy: root.starting
        || (root.status !== "idle" && root.status !== "error"
            && (root.svc === "active" || root.svc === "activating"))
    readonly property bool stale: root.successTs === 0
        || (root.now - root.successTs) > 259200   // 3 days, matches `status`
    readonly property bool skippedRecently: root.skipTs > root.successTs

    function ageStr(ts) {
        if (ts <= 0)
            return "never";
        var s = root.now - ts;
        if (s < 7200)
            return Math.max(1, Math.round(s / 60)) + "m ago";
        if (s < 172800)
            return Math.round(s / 3600) + "h ago";
        return Math.round(s / 86400) + "d ago";
    }

    function gb(b) {
        return (b / 1073741824).toFixed(1) + " GB";
    }

    function etaStr(s) {
        if (s < 0)
            return "";
        if (s < 90)
            return "~1m left";
        if (s < 3600)
            return "~" + Math.round(s / 60) + "m left";
        return "~" + Math.floor(s / 3600) + "h " + Math.round((s % 3600) / 60) + "m left";
    }

    function phaseText() {
        if (root.status === "pruning")
            return "pruning old snapshots…";
        if (root.status === "checking")
            return "verifying repository…";
        var t = Math.round(root.pct * 100) + "%";
        if (root.bytesTotal > 0)
            t += " · " + root.gb(root.bytesDone) + " / " + root.gb(root.bytesTotal);
        var e = root.etaStr(root.etaSec);
        if (e !== "")
            t += " · " + e;
        return t;
    }

    function startBackup() {
        if (root.busy)
            return;
        root.starting = true;
        launcher.running = true;
    }

    Process {
        id: launcher
        running: false
        command: ["sh", "-c", "systemctl --user start --no-block laptop-backup.service"]
    }

    Process {
        id: reader
        running: false
        command: ["sh", "-c",
            "d=\"$HOME/.local/state/laptop-backup\"; " +
            "cat \"$d/progress\" 2>/dev/null || echo STATUS:idle; " +
            "echo \"SVC:$(systemctl --user is-active laptop-backup.service 2>/dev/null)\"; " +
            "[ -f \"$d/last-success\" ] && echo \"SUCCESS:$(stat -c %Y \"$d/last-success\")\"; " +
            "[ -f \"$d/last-check\" ] && echo \"CHECK:$(stat -c %Y \"$d/last-check\")\"; " +
            "[ -f \"$d/last-skip\" ] && echo \"SKIP:$(stat -c %Y \"$d/last-skip\")\"; " +
            "echo \"NOW:$(date +%s)\"; " +
            "echo ENDCYCLE"]
        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("STATUS:"))
                    root.status = line.slice(7).trim();
                else if (line.startsWith("SVC:")) {
                    root.svc = line.slice(4).trim();
                    if (root.svc === "active" || root.svc === "activating")
                        root.starting = false;
                } else if (line.startsWith("PCT:"))
                    root.pct = parseFloat(line.slice(4)) || 0;
                else if (line.startsWith("DONE:"))
                    root.bytesDone = parseFloat(line.slice(5)) || 0;
                else if (line.startsWith("TOTAL:"))
                    root.bytesTotal = parseFloat(line.slice(6)) || 0;
                else if (line.startsWith("ETA:"))
                    root.etaSec = parseInt(line.slice(4)) || -1;
                else if (line.startsWith("SUCCESS:"))
                    root.successTs = parseFloat(line.slice(8)) || 0;
                else if (line.startsWith("CHECK:"))
                    root.checkTs = parseFloat(line.slice(6)) || 0;
                else if (line.startsWith("SKIP:"))
                    root.skipTs = parseFloat(line.slice(5)) || 0;
                else if (line.startsWith("NOW:"))
                    root.now = parseFloat(line.slice(4)) || 0;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }

    // ── Control Center pill ──
    ccWidgetIcon: root.busy ? "cloud_upload"
        : (root.status === "error" ? "cloud_off"
            : (root.stale ? "cloud_off" : "cloud_done"))
    ccWidgetPrimaryText: "Backup"
    ccWidgetSecondaryText: root.busy
        ? (root.starting ? "starting…" : root.phaseText())
        : (root.status === "error"
            ? "FAILED — expand for details"
            : (root.skippedRecently
                ? "skipped (vault locked) " + root.ageStr(root.skipTs)
                : (root.stale
                    ? "STALE — last " + root.ageStr(root.successTs)
                    : "backed up " + root.ageStr(root.successTs))))
    ccWidgetIsActive: root.busy

    onCcWidgetToggled: root.startBackup()

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

                // Live progress bar while a backup runs.
                Column {
                    visible: root.busy && root.status === "running"
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: root.phaseText()
                        color: Theme.surfaceText
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Theme.surfaceVariant

                        Rectangle {
                            width: parent.width * Math.min(1, root.pct)
                            height: parent.height
                            radius: 4
                            color: Theme.primary

                            Behavior on width {
                                NumberAnimation { duration: 400 }
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.busy && root.status !== "running"
                    text: root.phaseText()
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    visible: root.status === "error" && !root.busy
                    text: "Last run failed — journalctl --user -u laptop-backup"
                    color: Theme.error
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                Repeater {
                    model: [
                        { icon: "cloud_done", label: "Last backup", value: root.ageStr(root.successTs), warn: root.stale },
                        { icon: "verified", label: "Last integrity check", value: root.ageStr(root.checkTs), warn: false }
                    ]
                    delegate: Row {
                        required property var modelData
                        spacing: Theme.spacingS
                        DankIcon {
                            name: parent.modelData.icon
                            size: 18
                            color: parent.modelData.warn ? Theme.error : Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: parent.modelData.label + ":  "
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        StyledText {
                            text: parent.modelData.value
                            color: parent.modelData.warn ? Theme.error : Theme.surfaceText
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                StyledText {
                    visible: root.skippedRecently && !root.busy
                    text: "Last timer run skipped " + root.ageStr(root.skipTs) + " — 1Password was locked. It retries daily; or back up now with the vault open."
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    width: parent.width
                    wrapMode: Text.Wrap
                }

                StyledText {
                    text: "Encrypted → Cloudflare R2 · daily 00:02 · keeps 7d/5w/12m"
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: root.busy ? Theme.surfaceVariant : Theme.primary
                    opacity: runArea.pressed ? 0.8 : 1.0

                    StyledText {
                        anchors.centerIn: parent
                        text: root.busy ? "backing up… feel free to close this" : "Back up now"
                        color: root.busy ? Theme.surfaceVariantText : Theme.primaryText
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        id: runArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.busy
                        onClicked: root.startBackup()
                    }
                }
            }
        }
    }
}
