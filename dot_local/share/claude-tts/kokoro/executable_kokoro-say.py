#!/usr/bin/env python3
# kokoro-say — speak stdin text with Kokoro-82M, raw s16le PCM to stdout.
# Engine two of claude-tts (piper is engine one); the caller pipes stdout
# into pw-cat. Runs under the uv venv python at
# ~/.local/share/claude-tts/kokoro/venv (kokoro-onnx, CPU onnxruntime).
#
#   kokoro-say.py <voice> [speed]     # e.g. kokoro-say.py af_heart 1.0
#
# Output sample rate is 24000 (Kokoro native; caller must match).
# Synthesis is chunked per sentence so first audio arrives after one
# sentence, and a producer thread synthesizes AHEAD of playback: without
# the lookahead, each sentence only started synthesizing when the previous
# one finished writing, so any long sentence drained the pipe's ~1s of
# buffer and left an audible mid-message gap. onnxruntime releases the
# GIL during inference, so producer and writer genuinely overlap.

import os
import queue
import re
import sys
import threading

import numpy as np
from kokoro_onnx import Kokoro

HERE = os.path.dirname(os.path.abspath(__file__))
LOOKAHEAD = 6  # sentences held in memory ahead of playback (~500KB max)


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

    # Sentence split, then clause-split anything long: a single long
    # sentence takes longer to synthesize than the audio buffered before
    # it, which is exactly the mid-message stall the lookahead can't fix
    # (nothing exists to look ahead INTO until the big unit finishes).
    # ~90 chars ≈ 1.5-2s synth vs ~5s spoken — producer stays ahead.
    MAXLEN = 90

    def split_units(t: str) -> list[str]:
        units = []
        for sent in re.split(r"(?<=[.!?:;])\s+", t):
            sent = sent.strip()
            if not sent:
                continue
            if len(sent) <= MAXLEN:
                units.append(sent)
                continue
            piece = ""
            for clause in re.split(r"(?<=[,—–])\s+|\s+(?=[-—–]\s)", sent):
                if piece and len(piece) + len(clause) > MAXLEN:
                    units.append(piece)
                    piece = clause
                else:
                    piece = f"{piece} {clause}".strip()
                # hard-wrap a clause that is itself enormous
                while len(piece) > MAXLEN * 2:
                    cut = piece.rfind(" ", 0, MAXLEN)
                    cut = cut if cut > 0 else MAXLEN
                    units.append(piece[:cut])
                    piece = piece[cut:].strip()
            if piece:
                units.append(piece)
        return units

    chunks = split_units(text)
    q: queue.Queue = queue.Queue(maxsize=LOOKAHEAD)
    dead = threading.Event()  # writer lost its pipe (hushed) — stop synth

    def producer() -> None:
        for chunk in chunks:
            if dead.is_set():
                break
            samples, _rate = kokoro.create(chunk, voice=voice, speed=speed, lang="en-us")
            pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
            q.put(pcm.tobytes())
        q.put(None)

    threading.Thread(target=producer, daemon=True).start()

    # Prebuffer ~2s of audio before the first byte reaches the pipe: a
    # short opening sentence banks less playback time than the next unit
    # costs to synthesize, which starved the stream right at the start.
    # Costs well under a second of extra first-audio latency (short units
    # synthesize fast) and removes the last of the mid-message gaps.
    PREBUFFER_SEC = 2.0
    BYTES_PER_SEC = 48000  # 24kHz s16 mono

    out = sys.stdout.buffer
    pending: list[bytes] = []
    banked = 0
    done = False
    while not done and banked < PREBUFFER_SEC * BYTES_PER_SEC:
        buf = q.get()
        if buf is None:
            done = True
        else:
            pending.append(buf)
            banked += len(buf)

    try:
        for buf in pending:
            out.write(buf)
        out.flush()
        while not done:
            buf = q.get()
            if buf is None:
                break
            out.write(buf)
            out.flush()
    except BrokenPipeError:  # hushed mid-playback — exit quietly
        dead.set()
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
