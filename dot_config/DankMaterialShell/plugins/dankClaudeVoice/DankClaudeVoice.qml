pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

// Claude Voice — top-bar pill toggling claude-tts (spoken Claude Code
// replies). Pure view over the ~/.local/state/claude-tts/off flag file:
// click runs `claude-tts on|off`, which also kills any in-flight speech
// on mute. The Stop hook reads the same flag every fire, so the toggle
// is instant — no Claude session restart.
PluginComponent {
    id: root

    property bool muted: false

    Process {
        id: reader
        running: false
        command: ["sh", "-c", "[ -e \"$HOME/.local/state/claude-tts/off\" ] && echo MUTED || echo ON"]
        stdout: SplitParser {
            onRead: line => {
                const s = line.trim();
                if (s === "MUTED")
                    root.muted = true;
                else if (s === "ON")
                    root.muted = false;
            }
        }
    }

    // Flip based on the flag's real state (not the cached property), so a
    // toggle from the terminal and a click can't fight each other.
    Process {
        id: toggler
        running: false
        command: ["sh", "-c",
            "if [ -e \"$HOME/.local/state/claude-tts/off\" ]; then " +
            "\"$HOME/.local/bin/claude-tts\" on; else " +
            "\"$HOME/.local/bin/claude-tts\" off; fi >/dev/null 2>&1"]
        onExited: reader.running = true
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }

    pillClickAction: () => {
        root.muted = !root.muted;   // optimistic; reader confirms
        toggler.running = true;
    }

    horizontalBarPill: Component {
        DankIcon {
            name: root.muted ? "voice_over_off" : "record_voice_over"
            size: root.iconSize
            color: root.muted ? Theme.surfaceVariantText : Theme.surfaceText
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: root.muted ? "voice_over_off" : "record_voice_over"
            size: root.iconSize
            color: root.muted ? Theme.surfaceVariantText : Theme.surfaceText
        }
    }
}
