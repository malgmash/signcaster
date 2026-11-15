"""Messages and sockets for talking to the game. See docs/TRACKER_PROTOCOL.md.

Builders and the parser are pure functions. The two socket classes are thin and only ever
use 127.0.0.1. Nothing here can carry an image: messages hold landmarks, letters and status.
"""

from __future__ import annotations

import json
import socket
from typing import Any

HOST = "127.0.0.1"
GAME_PORT = 47800
CONTROL_PORT = 47801
VERSION = 1
MAX_BYTES = 2048

TRACKER_TYPES = ("hello", "hand", "letter", "status")
GAME_TYPES = ("config", "expect", "idle", "ping")
KNOWN_TYPES = TRACKER_TYPES + GAME_TYPES
STATUSES = ("ok", "no_camera", "model_missing", "low_light", "error")

Message = dict[str, Any]


def _message(kind: str, **fields: Any) -> Message:
    return {"v": VERSION, "type": kind, **fields}


def hello(tracker: str, version: str, fps: int) -> Message:
    """Start-up message and the once-a-second heartbeat."""
    return _message("hello", tracker=tracker, version=version, fps=fps)


def hand_present(t: float, handedness: str, landmarks: list[list[float]] | None = None) -> Message:
    """A hand is visible. Landmarks are included only when the game asked for them."""
    msg = _message("hand", t=t, handedness=handedness, present=True)
    if landmarks is not None:
        msg["landmarks"] = [[round(c, 4) for c in point] for point in landmarks]
    return msg


def hand_absent() -> Message:
    """No hand is visible."""
    return _message("hand", present=False)


def letter(t: float, value: str, confidence: float, hold_frames: int) -> Message:
    """The smoother accepted a letter (sent from M5 on, and by the fake tracker)."""
    return _message("letter", t=t, letter=value.upper(), confidence=confidence, hold_frames=hold_frames)


def status(value: str, detail: str = "") -> Message:
    """Something about the tracker changed, for example the camera could not be opened."""
    if value not in STATUSES:
        raise ValueError(f"unknown status {value!r}")
    return _message("status", status=value, detail=detail)


def encode(msg: Message) -> bytes:
    """One message as one UTF-8 JSON datagram. Raises if it would be too big to send."""
    data = json.dumps(msg, separators=(",", ":")).encode("utf-8")
    if len(data) > MAX_BYTES:
        raise ValueError(f"message is {len(data)} bytes, the limit is {MAX_BYTES}")
    return data


def parse(data: bytes) -> Message | None:
    """The message in a datagram, or None if it is too big, not JSON, or not version 1."""
    if len(data) > MAX_BYTES:
        return None
    try:
        msg = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None
    if not isinstance(msg, dict) or msg.get("v") != VERSION or msg.get("type") not in KNOWN_TYPES:
        return None
    return msg


class Sender:
    """Sends messages to one localhost port. A separate socket from the receiver on purpose:
    on Windows, a UDP socket that sent to a closed port throws on its next receive."""

    def __init__(self, port: int) -> None:
        self._address = (HOST, port)
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

    def send(self, msg: Message) -> None:
        try:
            self._sock.sendto(encode(msg), self._address)
        except OSError:
            pass  # Nobody listening yet. UDP is fire and forget.

    def close(self) -> None:
        self._sock.close()


class Receiver:
    """Non-blocking listener on one localhost port."""

    def __init__(self, port: int) -> None:
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._sock.bind((HOST, port))
        self._sock.setblocking(False)

    def poll(self) -> list[Message]:
        """Every valid message waiting right now. Bad packets are dropped."""
        messages: list[Message] = []
        while True:
            try:
                data, _ = self._sock.recvfrom(MAX_BYTES + 1)
            except OSError:
                # BlockingIOError: nothing waiting. ConnectionResetError: Windows reporting an
                # earlier send to a closed port. Either way there is nothing more to read now.
                return messages
            msg = parse(data)
            if msg is not None:
                messages.append(msg)

    def close(self) -> None:
        self._sock.close()
