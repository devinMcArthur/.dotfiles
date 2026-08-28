#!/usr/bin/env python3
# kokoro-say — speak stdin text with Kokoro-82M, raw s16le PCM to stdout.
# Engine two of claude-tts (piper is engine one); the caller pipes stdout
# into pw-cat. Runs under the uv venv python at
# ~/.local/share/claude-tts/kokoro/venv (kokoro-onnx, CPU onnxruntime).
#
#   kokoro-say.py <voice> [speed]     # e.g. kokoro-say.py af_heart 1.0
#
# Env:
#   KOKORO_PROGRESS   file to write the index of the unit currently being
#                     HEARD (not written — see LAG_BYTES). Lets a caller
#                     resume this message later from roughly where it was
#                     cut off, e.g. when dictation interrupts it.
#   KOKORO_FROM_UNIT  skip this many units. Splitting is deterministic, so
#                     the same text plus an index reproduces the remainder
#                     exactly; no audio is stored anywhere.
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

# Written audio runs AHEAD of audible audio by the prebuffer plus pw-cat's
# own buffer. Reporting the last unit written would resume past speech the
# listener never heard, so back the estimate off by that much. Erring late
# means resume repeats a little, which is the pleasant direction.
LAG_SEC = 2.6


def main() -> int:
    progress_path = os.environ.get("KOKORO_PROGRESS") or ""
    try:
        from_unit = max(0, int(os.environ.get("KOKORO_FROM_UNIT") or 0))
    except ValueError:
        from_unit = 0

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
    # Absolute indices survive the slice, so a resumed run reports
    # positions in the original message's terms.
    base = min(from_unit, len(chunks))
    chunks = chunks[base:]
    q: queue.Queue = queue.Queue(maxsize=LOOKAHEAD)
    dead = threading.Event()  # writer lost its pipe (hushed) — stop synth

    def producer() -> None:
        for i, chunk in enumerate(chunks):
            if dead.is_set():
                break
            samples, _rate = kokoro.create(chunk, voice=voice, speed=speed, lang="en-us")
            pcm = (np.clip(samples, -1.0, 1.0) * 32767).astype(np.int16)
            q.put((base + i, pcm.tobytes()))
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
    pending: list[tuple[int, bytes]] = []
    banked = 0
    done = False
    while not done and banked < PREBUFFER_SEC * BYTES_PER_SEC:
        item = q.get()
        if item is None:
            done = True
        else:
            pending.append(item)
            banked += len(item[1])

    written = 0
    marks: list[tuple[int, int]] = []   # (unit index, cumulative end byte)
    lag_bytes = int(LAG_SEC * BYTES_PER_SEC)

    def note(idx: int, nbytes: int) -> None:
        nonlocal written
        written += nbytes
        marks.append((idx, written))
        if not progress_path:
            return
        heard = written - lag_bytes
        cur = marks[0][0]
        for a, end in marks:
            if end > heard:
                cur = a
                break
        try:
            with open(progress_path, "w") as fh:
                fh.write(str(cur))
        except OSError:
            pass

    try:
        for idx, buf in pending:
            out.write(buf)
            note(idx, len(buf))
        out.flush()
        while not done:
            item = q.get()
            if item is None:
                break
            idx, buf = item
            out.write(buf)
            note(idx, len(buf))
            out.flush()
    except BrokenPipeError:  # hushed mid-playback — exit quietly
        dead.set()
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
