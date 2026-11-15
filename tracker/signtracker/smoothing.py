"""Turns a stream of per-frame guesses into accepted letters. Pure: no camera, no clock.

The model guesses a letter on every frame, and single frames are noisy. The smoother waits
until one letter holds steadily, accepts it once, and will not accept that same letter again
until the hand clearly lets go. The numbers come from the game's config message
(game/content/config/tracker.json), see docs/TRACKER_PROTOCOL.md.
"""

from __future__ import annotations


class Smoother:
    """Feed it one guess per frame with update(); it returns a letter only when one is accepted.

    - Accept: the same letter is the top guess with confidence >= min_confidence for
      hold_frames frames in a row. One frame below the bar starts the count again.
    - No repeats: after accepting a letter, that same letter is blocked until release_frames
      frames in a row show a different letter or no hand. A different letter does not wait
      for the release; it only needs its own hold.

    TODO(M6): double letters (the OO in MOON) keep the same shape, so this rule never sees
    the second one. Decide with real words and an ASL check how a repeat is detected.
    """

    def __init__(self, hold_frames: int, min_confidence: float, release_frames: int) -> None:
        self.set_params(hold_frames, min_confidence, release_frames)
        self.reset()

    def set_params(self, hold_frames: int, min_confidence: float, release_frames: int) -> None:
        """New tuning from a config message. Keeps whatever is being held right now."""
        self.hold_frames = max(1, hold_frames)
        self.min_confidence = min_confidence
        self.release_frames = max(1, release_frames)

    def reset(self) -> None:
        """Forget everything, for example when a new word starts."""
        self._candidate: str | None = None
        self._count = 0
        self._blocked: str | None = None
        self._release_count = 0

    def update(self, letter: str | None, confidence: float = 0.0) -> str | None:
        """One frame's top guess (None when no hand is visible). Returns the accepted letter, or None."""
        confident = letter is not None and confidence >= self.min_confidence
        self._track_release(letter, confident)
        if not confident:
            self._candidate = None
            self._count = 0
            return None
        if letter == self._candidate:
            self._count += 1
        else:
            self._candidate = letter
            self._count = 1
        # == rather than >=, so holding a letter for a long time still accepts it only once.
        if self._count == self.hold_frames and letter != self._blocked:
            self._blocked = letter
            self._release_count = 0
            return letter
        return None

    def _track_release(self, letter: str | None, confident: bool) -> None:
        if self._blocked is None:
            return
        if letter != self._blocked:
            self._release_count += 1
            if self._release_count >= self.release_frames:
                self._blocked = None
        elif confident:
            # The blocked shape is back for sure, so the release has to start over.
            self._release_count = 0
        # The blocked letter at low confidence: the hand may still be in that shape. Wait.
