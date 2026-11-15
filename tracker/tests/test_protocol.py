"""Protocol builders, encoding and parsing (docs/TRACKER_PROTOCOL.md). No sockets needed."""

import json

import pytest

from signtracker import protocol


def roundtrip(msg: protocol.Message) -> protocol.Message | None:
    return protocol.parse(protocol.encode(msg))


@pytest.mark.parametrize(
    "msg",
    [
        protocol.hello("mediapipe", "0.1.0", 30),
        protocol.hand_present(1731430000.123, "Right"),
        protocol.hand_present(1.0, "Left", [[0.5, 0.6, -0.01]] * 21),
        protocol.hand_absent(),
        protocol.letter(1.0, "b", 0.93, 6),
        protocol.status("no_camera", "Camera index 0 could not be opened"),
    ],
)
def test_every_tracker_message_round_trips(msg: protocol.Message) -> None:
    assert roundtrip(msg) == json.loads(json.dumps(msg))
    assert msg["v"] == 1


def test_letters_are_uppercase() -> None:
    assert protocol.letter(1.0, "b", 0.9, 6)["letter"] == "B"


def test_landmarks_are_only_sent_when_given() -> None:
    assert "landmarks" not in protocol.hand_present(1.0, "Right")
    assert len(protocol.hand_present(1.0, "Right", [[0.1, 0.2, 0.3]] * 21)["landmarks"]) == 21


def test_a_full_hand_fits_in_one_packet() -> None:
    msg = protocol.hand_present(1731430000.123, "Right", [[0.123456, 0.654321, -0.0123456]] * 21)
    assert len(protocol.encode(msg)) <= protocol.MAX_BYTES


def test_unknown_status_is_refused() -> None:
    with pytest.raises(ValueError):
        protocol.status("on_fire")


def test_oversize_messages_are_refused_when_encoding() -> None:
    with pytest.raises(ValueError):
        protocol.encode({"v": 1, "type": "status", "detail": "x" * protocol.MAX_BYTES})


@pytest.mark.parametrize(
    "data",
    [
        b"not json",
        b"\xff\xfe",
        b"[1, 2, 3]",
        b'{"type": "hello"}',
        b'{"v": 2, "type": "hello"}',
        b'{"v": 1, "type": "selfie"}',
        b'{"v": 1, "type": "ping", "pad": "' + b"x" * protocol.MAX_BYTES + b'"}',
    ],
)
def test_bad_packets_parse_to_none(data: bytes) -> None:
    assert protocol.parse(data) is None


@pytest.mark.parametrize("kind", ["config", "expect", "idle", "ping"])
def test_game_messages_parse(kind: str) -> None:
    assert protocol.parse(json.dumps({"v": 1, "type": kind}).encode()) == {"v": 1, "type": kind}


def test_sockets_only_use_localhost() -> None:
    assert protocol.HOST == "127.0.0.1"
