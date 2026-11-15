"""MediaPipe Hand Landmarker wrapper: one frame in, one hand (or None) out.

MediaPipe is imported inside the functions so tests and CI run without it loading a model.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any

MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "hand_landmarker.task"
MODEL_URL = (
    "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/latest/"
    "hand_landmarker.task"
)


class ModelMissing(RuntimeError):
    """The MediaPipe model file is not where we expect it."""

    def __init__(self, path: Path) -> None:
        super().__init__(
            f"Hand model not found at {path}\n"
            f"Download it from {MODEL_URL}\n"
            f"and save it as {path} (the folder is gitignored)."
        )


@dataclass(frozen=True)
class Hand:
    handedness: str
    points: list[list[float]]  # 21 [x, y, z]; x and y are 0 to 1 across the frame
    aspect: float = 1.0  # frame width / height, so features.py can undo the squash of 0 to 1


class HandFinder:
    """Finds at most one hand per frame. Frames must come in time order (VIDEO mode)."""

    def __init__(self, model_path: Path = MODEL_PATH) -> None:
        if not model_path.is_file():
            raise ModelMissing(model_path)
        from mediapipe.tasks.python import vision
        from mediapipe.tasks.python.core.base_options import BaseOptions

        options = vision.HandLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=str(model_path)),
            running_mode=vision.RunningMode.VIDEO,
            num_hands=1,
        )
        self._landmarker = vision.HandLandmarker.create_from_options(options)
        self._last_ms = -1

    def find(self, frame_bgr: Any, timestamp_ms: int) -> Hand | None:
        """The hand in a BGR frame, or None if there is no hand."""
        import cv2
        import mediapipe as mp

        # MediaPipe wants strictly increasing timestamps.
        timestamp_ms = max(timestamp_ms, self._last_ms + 1)
        self._last_ms = timestamp_ms
        rgb = cv2.cvtColor(frame_bgr, cv2.COLOR_BGR2RGB)
        image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        result = self._landmarker.detect_for_video(image, timestamp_ms)
        if not result.hand_landmarks:
            return None
        points = [[p.x, p.y, p.z] for p in result.hand_landmarks[0]]
        handedness = result.handedness[0][0].category_name if result.handedness else "Unknown"
        height, width = frame_bgr.shape[:2]
        return Hand(handedness=handedness, points=points, aspect=width / height)

    def close(self) -> None:
        self._landmarker.close()
