"""Record letter samples: `python tools/record.py --signer <nickname> --letters ADGMO`.

Saves hand landmark points only (21 numbers-only points per frame), never images or video,
to tracker/data/<signer>/<letter>.npz. The window shows the letter's name and nothing about
how to sign it: the signer signs it the way they were taught, and someone who knows ASL
checks the recordings before we train the full alphabet.
"""

from __future__ import annotations

import argparse
import time
from collections.abc import Callable
from pathlib import Path
from typing import Any

import numpy as np

from signtracker.capture import Camera
from signtracker.dataset import DATA_DIR, SIGNING_HANDS, append_take, check_letter, check_signer_id, sample_path
from signtracker.landmarks import Hand, HandFinder, ModelMissing
from signtracker.pacing import RateLimiter

COUNTDOWN_SECONDS = 3
# Frames right next to each other are near copies, so keep about 10 a second.
SAMPLES_PER_SECOND = 10
WINDOW = "Signcaster recorder (hand points only, no images are saved)"
KEEP_KEY = ord("k")
REDO_KEY = ord("r")
QUIT_KEYS = (ord("q"), 27)
DOT_RADIUS = 4
DOT_COLOR = (80, 220, 120)
TEXT_COLOR = (255, 255, 255)
SHADOW_COLOR = (0, 0, 0)
LINE_HEIGHT = 34

CONSENT = """
Signcaster letter recorder

- This saves the positions of 21 points on your hand, as numbers, for each frame it records.
- It never saves images or video.
- Files go to {folder} on this computer only. Nothing is uploaded, and git ignores the folder.
- Use a nickname, not your real name. To delete your recordings, delete that folder.
"""


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="python tools/record.py", description=__doc__.splitlines()[0])
    parser.add_argument("--signer", required=True, help="a nickname, like malama (not a real name)")
    parser.add_argument("--letters", required=True, help="letters to record, for example ADGMO")
    parser.add_argument("--hand", choices=SIGNING_HANDS, default="right", help="the hand you sign with")
    parser.add_argument("--takes", type=int, default=4, help="takes per letter (default 4)")
    parser.add_argument("--samples", type=int, default=50, help="samples per take (default 50)")
    parser.add_argument("--camera", type=int, default=0, help="webcam index (default 0)")
    parser.add_argument("--data", type=Path, default=DATA_DIR, help=f"where to save (default {DATA_DIR})")
    return parser.parse_args(argv)


def unique_letters(text: str) -> list[str]:
    """The letters in order, each once. Raises ValueError for J, Z or anything not a letter."""
    letters: list[str] = []
    for value in text:
        letter = check_letter(value)
        if letter not in letters:
            letters.append(letter)
    return letters


def ask_consent(folder: Path, read: Callable[[str], str] = input, show: Callable[[str], None] = print) -> bool:
    """Prints what is saved and where. True only if the person types yes."""
    show(CONSENT.format(folder=folder))
    return read("Type yes to agree and start recording: ").strip().lower() == "yes"


class Recorder:
    """The camera window. Kept thin: saving and checks live in signtracker/dataset.py."""

    def __init__(self, camera: Camera, finder: HandFinder) -> None:
        import cv2

        self.cv2 = cv2
        self.camera = camera
        self.finder = finder

    def look(self, lines: list[str]) -> tuple[Any, Hand | None, int] | None:
        """Reads one frame, shows it with dots and text. (frame, hand, key), or None if the camera stopped."""
        frame = self.camera.read()
        if frame is None:
            return None
        hand = self.finder.find(frame, int(time.monotonic() * 1000))
        if hand is not None:
            height, width = frame.shape[:2]
            for x, y, _z in hand.points:
                self.cv2.circle(frame, (int(x * width), int(y * height)), DOT_RADIUS, DOT_COLOR, -1)
        # Shown like a mirror, which feels natural. Only the picture is flipped, never the saved points.
        view = self.cv2.flip(frame, 1)
        for row, text in enumerate(lines):
            origin = (16, 40 + row * LINE_HEIGHT)
            self.cv2.putText(view, text, origin, self.cv2.FONT_HERSHEY_SIMPLEX, 0.9, SHADOW_COLOR, 4)
            self.cv2.putText(view, text, origin, self.cv2.FONT_HERSHEY_SIMPLEX, 0.9, TEXT_COLOR, 2)
        self.cv2.imshow(WINDOW, view)
        return frame, hand, self.cv2.waitKey(1) & 0xFF

    def take(self, letter: str, label: str, samples: int) -> tuple[str, np.ndarray | None, float]:
        """One take: countdown, record, then keep or redo.

        Returns ("keep", points, aspect), or ("redo", None, 1.0), or ("quit", None, 1.0).
        """
        start = time.monotonic()
        while (left := COUNTDOWN_SECONDS - (time.monotonic() - start)) > 0:
            seen = self.look([f"Letter {letter}   {label}", f"Get ready: {int(left) + 1}"])
            if seen is None or seen[2] in QUIT_KEYS:
                return "quit", None, 1.0
        limiter = RateLimiter(SAMPLES_PER_SECOND)
        points: list[list[list[float]]] = []
        aspect = 1.0
        while len(points) < samples:
            seen = self.look([f"Letter {letter}   {label}", f"Recording {len(points)}/{samples}  (Q to stop)"])
            if seen is None or seen[2] in QUIT_KEYS:
                return "quit", None, 1.0
            hand = seen[1]
            if hand is not None and limiter.allow(time.monotonic()):
                points.append(hand.points)
                aspect = hand.aspect
        while True:
            seen = self.look([f"Letter {letter}   {label}: done", "K keep   R redo   Q quit"])
            if seen is None or seen[2] in QUIT_KEYS:
                return "quit", None, 1.0
            if seen[2] == KEEP_KEY:
                return "keep", np.array(points, dtype=np.float32), aspect
            if seen[2] == REDO_KEY:
                return "redo", None, 1.0

    def close(self) -> None:
        self.cv2.destroyAllWindows()


def main(argv: list[str] | None = None, read: Callable[[str], str] = input) -> int:
    args = parse_args(argv)
    try:
        signer = check_signer_id(args.signer)
        letters = unique_letters(args.letters)
    except ValueError as error:
        print(error)
        return 2
    if args.takes < 1 or args.samples < 1:
        print("--takes and --samples must be at least 1")
        return 2
    folder = args.data / signer
    if not ask_consent(folder, read):
        print("Nothing was recorded.")
        return 1
    try:
        finder = HandFinder()
    except ModelMissing as missing:
        print(missing)
        return 1
    camera = Camera(args.camera)
    if not camera.open():
        print(f"Camera index {args.camera} could not be opened. Try --camera 1.")
        finder.close()
        return 1
    recorder = Recorder(camera, finder)
    try:
        for letter in letters:
            take = 1
            while take <= args.takes:
                result, points, aspect = recorder.take(letter, f"take {take} of {args.takes}", args.samples)
                if result == "quit":
                    print("Stopped. Takes you kept are saved.")
                    return 0
                if result == "keep" and points is not None:
                    path = sample_path(args.data, signer, letter)
                    number = append_take(path, points, aspect, args.hand, letter)
                    print(f"Saved {letter} take {number} ({len(points)} samples) to {path}")
                    take += 1
        print("Done. Train with: python tools/train.py")
        return 0
    finally:
        recorder.close()
        camera.release()
        finder.close()


if __name__ == "__main__":
    raise SystemExit(main())
