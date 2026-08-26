#!/usr/bin/env python3
# kokoro-say — speak stdin text with Kokoro-82M, raw s16le PCM to stdout.
# Engine two of claude-tts (piper is engine one); the caller pipes stdout
# into pw-cat. Runs under the uv venv python at
# ~/.local/share/claude-tts/kokoro/venv (kokoro-onnx, CPU onnxruntime).
#
#   kokoro-say.py <voice> [speed]     # e.g. kokoro-say.py af_heart 1.0
#
# Output sample rate is 24000 (Kokoro native; caller must match).
# Synthesis is chunked per sentence so long messages start speaking after
# the first sentence instead of after the whole text.

import re
import sys
import os

import numpy as np
from kokoro_onnx import Kokoro

HERE = os.path.dirname(os.path.abspath(__file__))


def main() -> int:
    voice = sys.argv[1] if len(sys.argv) > 1 else "af_heart"
    speed = float(sys.argv[2]) if len(sys.argv) > 2 else 1.0
    text = sys.stdin.read().strip()
    if not text:
        return 0

    kokoro = Kokoro(
        os.path.join(HERE, "kokoro-v1.0.onnx"),
        os.path.join(HERE, "voices-v1.0.bin"),
    )

    # Sentence-ish chunks: keeps first-audio latency at one sentence and
    # lets a mid-message hush() kill cleanly between chunks.
    chunks = [c.strip() for c in re.split(r"(?<=[.!?:;])\s+", text) if c.strip()]
    out = sys.stdout.buffer
    for chunk in chunks:
        samples, _rate = kokoro.create(chunk, voice=voice, speed=speed, lang="en-us")
        pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
        try:
            out.write(pcm.tobytes())
            out.flush()
        except BrokenPipeError:  # hushed mid-playback — exit quietly
            return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
