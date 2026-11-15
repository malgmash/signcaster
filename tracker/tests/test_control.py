"""How the tracker applies config, expect, idle and ping messages from the game."""

from signtracker.__main__ import Settings, handle_control
from signtracker.pacing import OrphanWatch


def test_config_updates_settings() -> None:
    settings = Settings()
    msg = {"v": 1, "type": "config", "mirror": True, "debug_landmarks": True, "min_confidence": 0.9, "hold_frames": 8}
    handle_control(msg, settings, None, 0.0)
    assert (settings.mirror, settings.debug_landmarks, settings.min_confidence, settings.hold_frames) == (
        True,
        True,
        0.9,
        8,
    )


def test_config_keeps_fields_it_does_not_mention() -> None:
    settings = Settings()
    handle_control({"v": 1, "type": "config", "mirror": True}, settings, None, 0.0)
    assert settings.hold_frames == Settings().hold_frames


def test_config_with_bad_values_keeps_the_current_settings() -> None:
    settings = Settings()
    bad = {
        "v": 1,
        "type": "config",
        "mirror": "yes",
        "debug_landmarks": 1,
        "min_confidence": "abc",
        "hold_frames": None,
    }
    handle_control(bad, settings, None, 0.0)
    assert settings == Settings()
    for value in (True, float("nan"), float("inf"), [0.9], {"x": 1}):
        handle_control({"v": 1, "type": "config", "min_confidence": value}, settings, None, 0.0)
        assert settings.min_confidence == Settings().min_confidence, value


def test_expect_and_idle_switch_the_mode() -> None:
    settings = Settings()
    handle_control({"v": 1, "type": "expect", "challenge_id": "c_000001", "letters": "blue"}, settings, None, 0.0)
    assert (settings.idle, settings.expected) == (False, "BLUE")
    handle_control({"v": 1, "type": "idle"}, settings, None, 0.0)
    assert (settings.idle, settings.expected) == (True, "")


def test_ping_feeds_the_orphan_watch() -> None:
    watch = OrphanWatch(5.0, now=0.0)
    handle_control({"v": 1, "type": "ping"}, Settings(), watch, 4.0)
    assert not watch.orphaned(8.0)
    assert watch.orphaned(9.0)
