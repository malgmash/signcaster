"""The hand tracker: `python -m signtracker [--show] [--camera N] [--exit-when-orphaned]`.

Reads the webcam, finds a hand with MediaPipe, reads the letter with the model trained by
tools/train.py, and tells the game over localhost UDP.
Frames never leave this process: nothing is saved to disk and only small JSON messages
(status, hand presence, letters, optional landmarks) are sent, to 127.0.0.1 only.
"""

from __future__ import annotations

import argparse
import math
import time
from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

from signtracker import __version__, protocol
from signtracker.capture import Camera
from signtracker.classifier import BadLetterModel, LetterModel, LetterModelMissing, pick
from signtracker.features import BadHand, feature_vector
from signtracker.landmarks import Hand, HandFinder, ModelMissing
from signtracker.pacing import Every, OrphanWatch, RateLimiter
from signtracker.smoothing import Smoother

TRACKER_NAME = "mediapipe"
# Half the game's 2 s silence limit, so one late packet never looks like a disconnect.
HELLO_SECONDS = 1.0
ORPHAN_SECONDS = 5.0
CAMERA_RETRY_SECONDS = 2.0
ACTIVE_FPS = 30
IDLE_FPS = 10
HAND_PER_SECOND = 30
NO_HAND_PER_SECOND = 5
WAIT_SECONDS = 0.05
PREVIEW_WINDOW = "Signcaster tracker (preview only, nothing is saved)"
PREVIEW_DOT_RADIUS = 4
PREVIEW_DOT_COLOR = (80, 220, 120)
PREVIEW_TEXT_COLOR = (255, 255, 255)
QUIT_KEYS = (ord("q"), 27)
HAND_MODEL_DETAIL = "hand_landmarker.task is missing, see the tracker console"
LETTER_MODEL_DETAIL = "letter model missing or out of date, see tracker/README.md"


@dataclass
class Settings:
    """What the game asked for in config, expect and idle messages."""

    mirror: bool = False
    debug_landmarks: bool = False
    min_confidence: float = 0.8
    hold_frames: int = 6
    release_frames: int = 4
    idle: bool = False
    expected: str = ""


def _flag(msg: protocol.Message, key: str, current: bool) -> bool:
    """A true/false field, or `current` if it is missing or not a real JSON boolean."""
    value = msg.get(key, current)
    return value if isinstance(value, bool) else current


def _number(msg: protocol.Message, key: str, current: float) -> float:
    """A number field, or `current` if it is missing, not a number, or not finite."""
    value = msg.get(key, current)
    # bool is a subclass of int in Python, so true would otherwise count as 1.
    if isinstance(value, bool) or not isinstance(value, int | float) or not math.isfinite(value):
        return current
    return float(value)


def handle_control(msg: protocol.Message, settings: Settings, orphan: OrphanWatch | None, now: float) -> None:
    """Applies one message from the game. Unknown fields and bad values are ignored, never fatal."""
    kind = msg.get("type")
    if kind == "config":
        settings.mirror = _flag(msg, "mirror", settings.mirror)
        settings.debug_landmarks = _flag(msg, "debug_landmarks", settings.debug_landmarks)
        settings.min_confidence = _number(msg, "min_confidence", settings.min_confidence)
        settings.hold_frames = int(_number(msg, "hold_frames", settings.hold_frames))
        settings.release_frames = int(_number(msg, "release_frames", settings.release_frames))
    elif kind == "expect":
        settings.idle = False
        settings.expected = str(msg.get("letters", "")).upper()
    elif kind == "idle":
        settings.idle = True
        settings.expected = ""
    elif kind == "ping" and orphan is not None:
        orphan.ping(now)


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="python -m signtracker", description=__doc__.splitlines()[0])
    parser.add_argument("--game-port", type=int, default=protocol.GAME_PORT)
    parser.add_argument("--control-port", type=int, default=protocol.CONTROL_PORT)
    parser.add_argument("--camera", type=int, default=0, help="webcam index (default 0)")
    parser.add_argument("--show", action="store_true", help="open a preview window, for debugging only")
    parser.add_argument(
        "--exit-when-orphaned",
        action="store_true",
        help=f"quit after {ORPHAN_SECONDS:.0f} s without a ping from the game",
    )
    return parser.parse_args(argv)


class Tracker:
    """The camera loop. Kept thin: timing lives in pacing.py, messages in protocol.py.

    The sockets, camera, hand finder and clock can be swapped for fakes, so tests run
    the real loop logic with no network, camera or MediaPipe.
    """

    def __init__(
        self,
        args: argparse.Namespace,
        sender: protocol.Sender | None = None,
        receiver: protocol.Receiver | None = None,
        camera: Camera | None = None,
        make_finder: Callable[[], HandFinder] = HandFinder,
        make_model: Callable[[], LetterModel] = LetterModel.load,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        self.args = args
        self.settings = Settings()
        self.clock = clock
        # The receiver first: if the port is taken, fail before loading the model.
        self.receiver = receiver if receiver is not None else protocol.Receiver(args.control_port)
        self.sender = sender if sender is not None else protocol.Sender(args.game_port)
        self.camera = camera if camera is not None else Camera(args.camera)
        self.hello_timer = Every(HELLO_SECONDS)
        self.camera_retry = Every(CAMERA_RETRY_SECONDS)
        self.hand_limit = RateLimiter(HAND_PER_SECOND)
        self.no_hand_limit = RateLimiter(NO_HAND_PER_SECOND)
        now = clock()
        self.orphan = OrphanWatch(ORPHAN_SECONDS, now) if args.exit_when_orphaned else None
        self.problem: tuple[str, str] | None = None
        self.frames = 0
        self.fps = 0
        self.fps_since = now
        # A missing model is a problem that stays, even when the camera comes back.
        self.base_problem: tuple[str, str] | None = None
        self.finder: HandFinder | None = None
        try:
            self.finder = make_finder()
        except ModelMissing as missing:
            print(missing)
            self.base_problem = ("model_missing", HAND_MODEL_DETAIL)
        self.model: LetterModel | None = None
        try:
            self.model = make_model()
        except (LetterModelMissing, BadLetterModel) as problem:
            # The camera still runs, so --show can check the hand dots before any training.
            print(problem)
            self.base_problem = self.base_problem or ("model_missing", LETTER_MODEL_DETAIL)
        self.smoother = Smoother(self.settings.hold_frames, self.settings.min_confidence, self.settings.release_frames)
        self.top: tuple[str, float] | None = None  # this frame's best guess, for the preview
        if self.base_problem is not None:
            self.set_problem(*self.base_problem)

    def clear_camera_problem(self) -> None:
        """The camera works again: back to ok, or to a model problem if there is one."""
        if self.base_problem is not None:
            self.set_problem(*self.base_problem)
        else:
            self.set_problem(None)

    def set_problem(self, value: str | None, detail: str = "") -> None:
        new = (value, detail) if value else None
        if new == self.problem:
            return
        self.problem = new
        self.sender.send(protocol.status(value or "ok", detail))

    def run(self) -> int:
        print(f"signtracker {__version__}: sending to {protocol.HOST}:{self.args.game_port}, Ctrl+C to stop")
        try:
            while self.step():
                pass
        except KeyboardInterrupt:
            pass
        finally:
            self.close()
        return 0

    def step(self) -> bool:
        """One pass of the loop. False means stop."""
        started = self.clock()
        for msg in self.receiver.poll():
            handle_control(msg, self.settings, self.orphan, started)
            if msg.get("type") == "expect":
                self.smoother.reset()  # a new word starts fresh
        s = self.settings
        self.smoother.set_params(s.hold_frames, s.min_confidence, s.release_frames)
        if self.orphan is not None and self.orphan.orphaned(started):
            print(f"No ping from the game for {ORPHAN_SECONDS:.0f} s, exiting so the camera turns off.")
            return False
        # Camera first, so a camera problem is already known when the first hello goes out.
        frame = self.next_frame(started)
        self.heartbeat(started)
        if frame is None:
            time.sleep(WAIT_SECONDS)
            return True
        hand = self.finder.find(frame, int(started * 1000)) if self.finder else None
        self.report(hand)
        self.read_letter(hand)
        if self.args.show and not self.preview(frame, hand):
            return False
        self.frames += 1
        target = IDLE_FPS if self.settings.idle else ACTIVE_FPS
        time.sleep(max(0.0, 1.0 / target - (self.clock() - started)))
        return True

    def heartbeat(self, now: float) -> None:
        if not self.hello_timer.due(now):
            return
        elapsed = now - self.fps_since
        if elapsed > 0:
            self.fps = round(self.frames / elapsed)
        self.frames = 0
        self.fps_since = now
        if self.problem is not None:
            # Repeated so a game that starts after us still learns what is wrong. Sent before
            # the hello, so the game never shows "connected" for a moment first.
            self.sender.send(protocol.status(*self.problem))
        self.sender.send(protocol.hello(TRACKER_NAME, __version__, self.fps))

    def next_frame(self, now: float) -> Any | None:
        if self.finder is None:
            return None
        if not self.camera.is_open:
            if not self.camera_retry.due(now):
                return None
            if not self.camera.open():
                self.set_problem("no_camera", f"Camera index {self.args.camera} could not be opened")
                return None
            self.clear_camera_problem()
        return self.camera.read()

    def report(self, hand: Hand | None) -> None:
        now = self.clock()
        if hand is None:
            if self.no_hand_limit.allow(now):
                self.sender.send(protocol.hand_absent())
            return
        if self.hand_limit.allow(now):
            points = hand.points if self.settings.debug_landmarks else None
            self.sender.send(protocol.hand_present(time.time(), hand.handedness, points))

    def read_letter(self, hand: Hand | None) -> None:
        """Model guess, expect hint, smoother. Sends a letter message when one is accepted."""
        if self.model is None:
            return
        self.top = None
        if hand is None:
            self.smoother.update(None)
            return
        try:
            features = feature_vector(hand.points, hand.aspect, self.settings.mirror)
        except BadHand:
            self.smoother.update(None)
            return
        probabilities = self.model.predict(features)
        letter, confidence = pick(probabilities, self.model.letters, self.settings.expected)
        self.top = (letter, confidence)
        accepted = self.smoother.update(letter, confidence)
        if accepted is None:
            return
        self.sender.send(protocol.letter(time.time(), accepted, round(confidence, 3), self.settings.hold_frames))
        print(f"letter {accepted} {confidence:.2f}")

    def preview(self, frame: Any, hand: Hand | None) -> bool:
        """Shows the frame with landmark dots and the current guess. False when the player pressed Q or Esc."""
        import cv2

        if hand is not None:
            height, width = frame.shape[:2]
            for x, y, _z in hand.points:
                center = (int(x * width), int(y * height))
                cv2.circle(frame, center, PREVIEW_DOT_RADIUS, PREVIEW_DOT_COLOR, -1)
        # Shown like a mirror. Only the picture is flipped; the points sent and read are not.
        view = cv2.flip(frame, 1)
        if self.model is None:
            text = "No letter model yet (hand dots only)"
        elif self.top is None:
            text = "No hand"
        else:
            text = f"{self.top[0]}  {self.top[1]:.0%}"
        cv2.putText(view, text, (16, 40), cv2.FONT_HERSHEY_SIMPLEX, 1.0, PREVIEW_TEXT_COLOR, 2)
        cv2.imshow(PREVIEW_WINDOW, view)
        return (cv2.waitKey(1) & 0xFF) not in QUIT_KEYS

    def close(self) -> None:
        self.camera.release()
        if self.finder is not None:
            self.finder.close()
        if self.args.show:
            import cv2

            cv2.destroyAllWindows()
        self.sender.close()
        self.receiver.close()


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        tracker = Tracker(args)
    except OSError as error:
        print(
            f"Could not listen on {protocol.HOST}:{args.control_port} ({error}).\n"
            "Is another tracker already running? Close it and try again."
        )
        return 1
    return tracker.run()


if __name__ == "__main__":
    raise SystemExit(main())
