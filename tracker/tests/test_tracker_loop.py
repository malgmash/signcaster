"""The Tracker loop with fake sockets, camera, hand finder and clock: no network, webcam or MediaPipe."""

from __future__ import annotations

import socket
from pathlib import Path
from typing import Any

import numpy as np

from signtracker import protocol
from signtracker.__main__ import CAMERA_RETRY_SECONDS, ORPHAN_SECONDS, Tracker, main, parse_args
from signtracker.classifier import LetterModelMissing
from signtracker.landmarks import Hand, ModelMissing

FRAME = object()  # stands in for a camera image; the fakes never look inside it
POINTS = (np.random.default_rng(5).random((21, 3))).tolist()  # any points with a real palm size


class FakeSender:
    def __init__(self) -> None:
        self.sent: list[protocol.Message] = []

    def send(self, msg: protocol.Message) -> None:
        self.sent.append(msg)

    def types(self) -> list[str]:
        """Each message's type, with the status value for status messages, like 'status:no_camera'."""
        return [f"status:{m['status']}" if m["type"] == "status" else m["type"] for m in self.sent]

    def close(self) -> None:
        pass


class FakeReceiver:
    def poll(self) -> list[protocol.Message]:
        return []

    def close(self) -> None:
        pass


class FakeCamera:
    def __init__(self, opens: bool) -> None:
        self.opens = opens
        self.is_open = False
        self.open_calls = 0

    def open(self) -> bool:
        self.open_calls += 1
        self.is_open = self.opens
        return self.opens

    def read(self) -> Any:
        return FRAME if self.is_open else None

    def release(self) -> None:
        self.is_open = False


class FakeFinder:
    def find(self, _frame: Any, _timestamp_ms: int) -> Hand | None:
        return None

    def close(self) -> None:
        pass


class FakeModel:
    """Always sure it sees `letter`. The real model is tested in test_classifier.py."""

    def __init__(self, letter: str = "A", confidence: float = 0.95) -> None:
        self.letters = ("A", "B")
        self.probabilities = np.array([confidence, 1 - confidence])
        if letter == "B":
            self.probabilities = self.probabilities[::-1]

    def predict(self, _features: np.ndarray) -> np.ndarray:
        return self.probabilities


class FakeClock:
    def __init__(self) -> None:
        self.now = 100.0

    def __call__(self) -> float:
        return self.now


def missing_model() -> FakeFinder:
    raise ModelMissing(Path("models/hand_landmarker.task"))


def missing_letter_model() -> FakeModel:
    raise LetterModelMissing(Path("models/letters.npz"))


def make_tracker(
    *flags: str, camera_opens: bool = True, finder: Any = FakeFinder, model: Any = FakeModel
) -> tuple[Tracker, Any, Any]:
    sender, camera = FakeSender(), FakeCamera(camera_opens)
    tracker = Tracker(
        parse_args(list(flags)),
        sender=sender,
        receiver=FakeReceiver(),
        camera=camera,
        make_finder=finder,
        make_model=model,
        clock=FakeClock(),
    )
    return tracker, sender, camera


def test_a_missing_model_never_opens_the_camera() -> None:
    tracker, sender, camera = make_tracker(finder=missing_model)
    assert tracker.next_frame(100.0) is None
    tracker.heartbeat(100.0)
    assert camera.open_calls == 0
    assert sender.types() == ["status:model_missing", "status:model_missing", "hello"]


def test_a_problem_status_goes_out_before_each_hello() -> None:
    tracker, sender, _camera = make_tracker(camera_opens=False)
    for second in range(3):
        now = 100.0 + second * CAMERA_RETRY_SECONDS
        tracker.next_frame(now)
        tracker.heartbeat(now)
    # Announced once when it starts, then repeated just before every hello, never after.
    assert sender.types() == ["status:no_camera"] + ["status:no_camera", "hello"] * 3


def test_the_camera_is_retried_every_two_seconds_and_recovery_is_announced() -> None:
    tracker, sender, camera = make_tracker(camera_opens=False)
    tracker.next_frame(100.0)
    tracker.next_frame(100.0 + CAMERA_RETRY_SECONDS / 2)
    assert camera.open_calls == 1
    camera.opens = True
    assert tracker.next_frame(100.0 + CAMERA_RETRY_SECONDS) is FRAME
    assert sender.types() == ["status:no_camera", "status:ok"]
    assert tracker.problem is None


def test_landmarks_are_only_sent_when_the_game_asks() -> None:
    tracker, sender, _camera = make_tracker()
    tracker.report(Hand("Right", POINTS))
    assert "landmarks" not in sender.sent[-1]
    tracker.settings.debug_landmarks = True
    tracker.clock.now += 1.0  # past the hand rate limit
    tracker.report(Hand("Right", POINTS))
    assert len(sender.sent[-1]["landmarks"]) == 21


def test_a_held_letter_is_sent_once() -> None:
    tracker, sender, _camera = make_tracker()
    hand = Hand("Right", POINTS, aspect=16 / 9)
    for _ in range(tracker.settings.hold_frames * 3):
        tracker.read_letter(hand)
    letters = [m for m in sender.sent if m["type"] == "letter"]
    assert len(letters) == 1
    assert (letters[0]["letter"], letters[0]["confidence"]) == ("A", 0.95)
    assert letters[0]["hold_frames"] == tracker.settings.hold_frames


def test_a_new_expect_lets_the_same_letter_count_again() -> None:
    tracker, sender, _camera = make_tracker()
    hand = Hand("Right", POINTS)
    for _ in range(tracker.settings.hold_frames):
        tracker.read_letter(hand)
    tracker.receiver.poll = lambda: [{"v": 1, "type": "expect", "challenge_id": "c_1", "letters": "AB"}]
    tracker.step()  # handles the expect; the camera fake gives a frame with no hand
    tracker.receiver.poll = lambda: []
    for _ in range(tracker.settings.hold_frames):
        tracker.read_letter(hand)
    assert [m["letter"] for m in sender.sent if m["type"] == "letter"] == ["A", "A"]


def test_unsure_guesses_send_nothing() -> None:
    tracker, sender, _camera = make_tracker(model=lambda: FakeModel(confidence=0.6))
    for _ in range(30):
        tracker.read_letter(Hand("Right", POINTS))
    assert not [m for m in sender.sent if m["type"] == "letter"]
    assert tracker.top == ("A", 0.6)


def test_a_missing_letter_model_is_reported_and_survives_the_camera_coming_back() -> None:
    tracker, sender, camera = make_tracker(model=missing_letter_model)
    assert tracker.next_frame(100.0) is FRAME  # the camera still runs, for --show
    assert camera.open_calls == 1
    assert sender.types() == ["status:model_missing"]  # not "ok" after the camera opened
    tracker.read_letter(Hand("Right", POINTS))  # no model: nothing happens, nothing breaks
    assert tracker.top is None


def test_config_tunes_the_smoother() -> None:
    tracker, sender, _camera = make_tracker()
    tracker.receiver.poll = lambda: [{"v": 1, "type": "config", "hold_frames": 2, "release_frames": 7}]
    tracker.step()
    assert (tracker.smoother.hold_frames, tracker.smoother.release_frames) == (2, 7)
    tracker.read_letter(Hand("Right", POINTS))
    tracker.read_letter(Hand("Right", POINTS))
    assert [m["letter"] for m in sender.sent if m["type"] == "letter"] == ["A"]


def test_exits_when_the_game_stops_pinging() -> None:
    tracker, _sender, _camera = make_tracker("--exit-when-orphaned")
    tracker.clock.now += ORPHAN_SECONDS
    assert tracker.step() is False


def test_a_taken_control_port_exits_cleanly(capsys: Any) -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as taken:
        taken.bind((protocol.HOST, 0))
        port = taken.getsockname()[1]
        assert main(["--control-port", str(port)]) == 1
    assert "another tracker" in capsys.readouterr().out
