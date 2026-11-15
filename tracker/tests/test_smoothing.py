"""The smoother: hold, accept once, release. Letters here are just labels for the rule."""

from __future__ import annotations

from signtracker.smoothing import Smoother

HOLD = 6
BAR = 0.8
RELEASE = 4
SURE = 0.9
UNSURE = 0.5


def smoother() -> Smoother:
    return Smoother(HOLD, BAR, RELEASE)


def feed(s: Smoother, frames: list[tuple[str | None, float]]) -> list[str]:
    """Runs the frames and returns every accepted letter in order."""
    accepted = []
    for letter, confidence in frames:
        result = s.update(letter, confidence)
        if result is not None:
            accepted.append(result)
    return accepted


def hold(letter: str | None, frames: int, confidence: float = SURE) -> list[tuple[str | None, float]]:
    return [(letter, confidence)] * frames


def test_accepts_after_exactly_hold_frames() -> None:
    s = smoother()
    assert feed(s, hold("B", HOLD - 1)) == []
    assert s.update("B", SURE) == "B"


def test_holding_longer_still_accepts_once() -> None:
    assert feed(smoother(), hold("B", HOLD * 5)) == ["B"]


def test_one_unsure_frame_restarts_the_hold() -> None:
    frames = hold("B", HOLD - 1) + hold("B", 1, UNSURE) + hold("B", HOLD - 1)
    assert feed(smoother(), frames) == []


def test_confidence_exactly_at_the_bar_counts() -> None:
    assert feed(smoother(), hold("B", HOLD, BAR)) == ["B"]


def test_a_flicker_to_another_letter_restarts_the_hold() -> None:
    frames = hold("B", HOLD - 1) + hold("L", 1) + hold("B", HOLD - 1)
    assert feed(smoother(), frames) == []


def test_no_repeat_until_the_hand_lets_go() -> None:
    s = smoother()
    frames = hold("B", HOLD) + hold("L", RELEASE - 1, UNSURE) + hold("B", HOLD)
    assert feed(s, frames) == ["B"]


def test_no_hand_for_release_frames_allows_a_repeat() -> None:
    frames = hold("B", HOLD) + hold(None, RELEASE) + hold("B", HOLD)
    assert feed(smoother(), frames) == ["B", "B"]


def test_release_frames_must_be_in_a_row() -> None:
    frames = hold("B", HOLD) + hold(None, RELEASE - 1) + hold("B", 1) + hold(None, RELEASE - 1) + hold("B", HOLD)
    assert feed(smoother(), frames) == ["B"]


def test_the_blocked_letter_at_low_confidence_does_not_release() -> None:
    frames = hold("B", HOLD) + hold("B", RELEASE * 3, UNSURE) + hold("B", HOLD)
    assert feed(smoother(), frames) == ["B"]


def test_a_different_letter_does_not_wait_for_the_release() -> None:
    frames = hold("B", HOLD) + hold("L", HOLD)
    assert feed(smoother(), frames) == ["B", "L"]


def test_a_word_with_a_letter_coming_back() -> None:
    # M O M: the O in between releases the first M.
    frames = hold("M", HOLD) + hold("O", HOLD) + hold("M", HOLD)
    assert feed(smoother(), frames) == ["M", "O", "M"]


def test_double_letters_are_not_seen_yet() -> None:
    # Pinned on purpose, see the TODO(M6) in smoothing.py: the same shape held twice is one O.
    frames = hold("M", HOLD) + hold("O", HOLD) + hold("O", HOLD) + hold("N", HOLD)
    assert feed(smoother(), frames) == ["M", "O", "N"]


def test_set_params_changes_the_rule_without_forgetting() -> None:
    s = smoother()
    feed(s, hold("B", 2))
    s.set_params(3, BAR, RELEASE)
    assert s.update("B", SURE) == "B"


def test_set_params_keeps_counts_sane() -> None:
    s = Smoother(0, BAR, 0)
    assert (s.hold_frames, s.release_frames) == (1, 1)
    assert s.update("B", SURE) == "B"


def test_reset_forgets_the_blocked_letter() -> None:
    s = smoother()
    feed(s, hold("B", HOLD))
    s.reset()
    assert feed(s, hold("B", HOLD)) == ["B"]
