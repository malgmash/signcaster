"""Timing helpers for the tracker loop. Pure: every method takes the current time.

Passing time in (instead of calling time.time() inside) keeps the tests exact and fast.
"""

from __future__ import annotations

# Frame times like 16 * 0.05 are not exactly 0.8 in floating point, so allow a hair of slack.
TOLERANCE = 1e-9


class RateLimiter:
    """Allows at most `max_per_second` events, spaced out evenly."""

    def __init__(self, max_per_second: float) -> None:
        self._gap = 1.0 / max_per_second
        self._last: float | None = None

    def allow(self, now: float) -> bool:
        if self._last is not None and now - self._last < self._gap - TOLERANCE:
            return False
        self._last = now
        return True


class Every:
    """True once every `seconds`, starting with the first call."""

    def __init__(self, seconds: float) -> None:
        self._seconds = seconds
        self._next: float | None = None

    def due(self, now: float) -> bool:
        if self._next is not None and now < self._next:
            return False
        self._next = now + self._seconds
        return True


class OrphanWatch:
    """Tells the tracker to quit when the game has not pinged for `seconds`.

    The clock starts when the watch is created, so a tracker whose game never shows up
    also quits. This way a crashed game never leaves the camera on (docs/adr/0006).
    """

    def __init__(self, seconds: float, now: float) -> None:
        self._seconds = seconds
        self._last_ping = now

    def ping(self, now: float) -> None:
        self._last_ping = now

    def orphaned(self, now: float) -> bool:
        return now - self._last_ping >= self._seconds
