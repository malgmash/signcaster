"""Webcam access. Frames stay in memory: this module never writes or sends them.

OpenCV is imported inside the methods so tests and CI run without a camera.
"""

from __future__ import annotations

from typing import Any


class Camera:
    """Opens one webcam, reads frames, and always releases it (use it in a `with` block)."""

    def __init__(self, index: int) -> None:
        self.index = index
        self._capture: Any = None

    def open(self) -> bool:
        """True if the camera opened. Safe to call again to retry."""
        import cv2

        self.release()
        capture = cv2.VideoCapture(self.index)
        if not capture.isOpened():
            capture.release()
            return False
        self._capture = capture
        return True

    @property
    def is_open(self) -> bool:
        return self._capture is not None

    def read(self) -> Any | None:
        """The next frame (a BGR numpy array), or None if the camera stopped giving frames."""
        if self._capture is None:
            return None
        ok, frame = self._capture.read()
        if not ok:
            self.release()
            return None
        return frame

    def release(self) -> None:
        if self._capture is not None:
            self._capture.release()
            self._capture = None

    def __enter__(self) -> Camera:
        return self

    def __exit__(self, *_exc: object) -> None:
        self.release()
