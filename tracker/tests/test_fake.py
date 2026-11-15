"""The fake tracker's message sequence and pacing, without sockets or real sleeping."""

import pytest

from signtracker import fake, protocol


def kinds(steps: list[fake.Step]) -> list[str]:
    return [msg["type"] for _, msg in steps]


def test_blue_is_a_hello_then_four_letters() -> None:
    steps = fake.script("blue", delay=0.2)
    assert kinds(steps) == ["hello", "letter", "letter", "letter", "letter"]
    assert [msg["letter"] for _, msg in steps[1:]] == ["B", "L", "U", "E"]
    assert [offset for offset, _ in steps] == pytest.approx([0.0, 0.2, 0.4, 0.6, 0.8])


def test_slow_words_keep_the_heartbeat() -> None:
    steps = fake.script("BLUE", delay=1.5)  # letters at 1.5, 3.0, 4.5 and 6.0 s
    hellos = [offset for offset, msg in steps if msg["type"] == "hello"]
    assert hellos == [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
    gaps = [b - a for a, b in zip(hellos, hellos[1:], strict=False)]
    assert all(gap <= fake.HELLO_SECONDS for gap in gaps)


def test_letter_times_start_from_the_start_time() -> None:
    steps = fake.script("AB", delay=0.5, start=1000.0)
    assert [msg["t"] for _, msg in steps if msg["type"] == "letter"] == [1000.5, 1001.0]


def test_non_letters_are_skipped() -> None:
    assert [m["letter"] for _, m in fake.script("a-b c", 0.1) if m["type"] == "letter"] == ["A", "B", "C"]


def test_every_message_is_valid_protocol() -> None:
    for _, msg in fake.script("BLUE", 0.6):
        assert protocol.parse(protocol.encode(msg)) is not None


def test_play_sends_in_order_and_waits_between_steps() -> None:
    sent: list[protocol.Message] = []
    waits: list[float] = []
    count = fake.play("CAT", 0.3, sent.append, sleep=waits.append, clock=lambda: 50.0)
    assert count == 4
    assert kinds([(0.0, m) for m in sent]) == ["hello", "letter", "letter", "letter"]
    assert waits == pytest.approx([0.0, 0.3, 0.3, 0.3])
