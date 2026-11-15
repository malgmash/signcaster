"""Turns 21 hand landmarks into the numbers the letter model reads. Pure numpy, no camera.

MediaPipe numbers the points like this: 0 is the wrist, then 4 points per finger from the
base to the tip: thumb 1 to 4, index 5 to 8, middle 9 to 12, ring 13 to 16, pinky 17 to 20.
These are positions only. This file says nothing about how any letter is signed.
"""

from __future__ import annotations

from collections.abc import Sequence

import numpy as np

# Bump this whenever feature_vector changes, so an old model is refused instead of guessing.
FEATURE_VERSION = 1
POINT_COUNT = 21
WRIST = 0
MIDDLE_KNUCKLE = 9
FINGER_BASES = (1, 5, 9, 13, 17)  # first point of the thumb, index, middle, ring and pinky
JOINTS_PER_FINGER = 3
FEATURE_SIZE = POINT_COUNT * 3 + len(FINGER_BASES) * JOINTS_PER_FINGER  # 63 + 15 = 78
# Below this the palm has no size, so the points are broken (all in one spot).
MIN_PALM_SIZE = 1e-6

Points = Sequence[Sequence[float]] | np.ndarray


class BadHand(ValueError):
    """The points cannot be turned into features (wrong shape, or all in one spot)."""


def as_array(points: Points) -> np.ndarray:
    """The points as a 21 x 3 float array. Raises BadHand for any other shape."""
    array = np.asarray(points, dtype=np.float64)
    if array.shape != (POINT_COUNT, 3):
        raise BadHand(f"expected {POINT_COUNT} points of [x, y, z], got shape {array.shape}")
    return array


def normalize(points: Points, aspect: float = 1.0, mirror: bool = False) -> np.ndarray:
    """Same hand shape, same numbers, wherever the hand is and however big it looks.

    aspect is the frame width / height. MediaPipe gives x and y as 0 to 1 of the frame, so on a
    16:9 webcam one unit of x is wider than one unit of y. Multiplying x by aspect fixes that.
    mirror flips left and right, so a left-handed signer looks like a right-handed one.
    """
    array = as_array(points).copy()
    array[:, 0] *= aspect
    array -= array[WRIST]
    palm = float(np.linalg.norm(array[MIDDLE_KNUCKLE]))
    if palm < MIN_PALM_SIZE:
        raise BadHand("the palm has no size, all points are in one spot")
    array /= palm
    if mirror:
        array[:, 0] = -array[:, 0]
    return array


def _bend(before: np.ndarray, after: np.ndarray) -> float:
    """Angle in radians between two bones: 0 when they are in a straight line."""
    lengths = float(np.linalg.norm(before) * np.linalg.norm(after))
    if lengths < MIN_PALM_SIZE:
        return 0.0
    cosine = float(np.dot(before, after)) / lengths
    return float(np.arccos(np.clip(cosine, -1.0, 1.0)))


def joint_angles(normalized: np.ndarray) -> np.ndarray:
    """15 bend angles: 3 joints for each finger, from the base out. 0 means straight."""
    angles: list[float] = []
    for base in FINGER_BASES:
        chain = [WRIST, base, base + 1, base + 2, base + 3]
        for joint in range(1, JOINTS_PER_FINGER + 1):
            before = normalized[chain[joint]] - normalized[chain[joint - 1]]
            after = normalized[chain[joint + 1]] - normalized[chain[joint]]
            angles.append(_bend(before, after))
    return np.asarray(angles)


def feature_vector(points: Points, aspect: float = 1.0, mirror: bool = False) -> np.ndarray:
    """The 78 numbers for the model: 63 normalized coordinates, then 15 joint angles."""
    normalized = normalize(points, aspect, mirror)
    return np.concatenate([normalized.ravel(), joint_angles(normalized)])
