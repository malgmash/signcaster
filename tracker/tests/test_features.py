"""features.py with hand-made point sets. The shapes are geometry, not real letters."""

from __future__ import annotations

import math

import numpy as np
import pytest

from signtracker.features import (
    FEATURE_SIZE,
    FINGER_BASES,
    MIDDLE_KNUCKLE,
    BadHand,
    feature_vector,
    joint_angles,
    normalize,
)


def straight_hand() -> np.ndarray:
    """Wrist at the origin, five straight fingers pointing up (negative y, like image rows)."""
    points = np.zeros((21, 3))
    for finger, base in enumerate(FINGER_BASES):
        x = (finger - 2) * 0.2
        for step in range(4):
            points[base + step] = [x, -1.0 - step * 0.3, 0.0]
    points[MIDDLE_KNUCKLE] = [0.0, -1.0, 0.0]
    return points


def test_moving_and_resizing_the_hand_changes_nothing() -> None:
    hand = straight_hand()
    moved_and_bigger = hand * 3.0 + np.array([0.4, 0.2, 0.1])
    assert np.allclose(normalize(hand), normalize(moved_and_bigger))
    assert np.allclose(feature_vector(hand), feature_vector(moved_and_bigger))


def test_wrist_is_the_origin_and_the_palm_is_one_unit() -> None:
    normalized = normalize(straight_hand() + 5.0)
    assert np.allclose(normalized[0], 0.0)
    assert math.isclose(float(np.linalg.norm(normalized[MIDDLE_KNUCKLE])), 1.0)


def test_mirror_flips_left_and_right_only() -> None:
    hand = straight_hand()
    hand[5] = [0.3, -0.9, 0.05]
    plain, mirrored = normalize(hand), normalize(hand, mirror=True)
    assert np.allclose(mirrored[:, 0], -plain[:, 0])
    assert np.allclose(mirrored[:, 1:], plain[:, 1:])


def test_aspect_undoes_a_wide_frame() -> None:
    hand = straight_hand()
    squashed = hand.copy()
    squashed[:, 0] /= 16 / 9  # what a 16:9 frame does to x when it maps to 0..1
    assert np.allclose(normalize(squashed, aspect=16 / 9), normalize(hand))


def test_straight_fingers_have_no_bend() -> None:
    angles = joint_angles(normalize(straight_hand()))
    assert angles.shape == (15,)
    # The base joint bends a little where each finger leaves the palm; the others are straight.
    assert np.allclose(angles.reshape(5, 3)[:, 1:], 0.0)


def test_a_right_angle_is_ninety_degrees() -> None:
    hand = straight_hand()
    base = FINGER_BASES[1]
    hand[base + 2] = hand[base + 1] + [0.3, 0.0, 0.0]  # turn sideways at the middle joint
    hand[base + 3] = hand[base + 2] + [0.3, 0.0, 0.0]
    angles = joint_angles(normalize(hand)).reshape(5, 3)
    assert math.isclose(math.degrees(angles[1][1]), 90.0, abs_tol=1e-6)
    assert math.isclose(angles[1][2], 0.0, abs_tol=1e-6)


def test_feature_vector_is_coordinates_then_angles() -> None:
    features = feature_vector(straight_hand())
    assert features.shape == (FEATURE_SIZE,)
    assert np.allclose(features[:63], normalize(straight_hand()).ravel())


def test_broken_points_are_refused() -> None:
    with pytest.raises(BadHand):
        normalize(np.ones((21, 3)))  # every point in one spot
    with pytest.raises(BadHand):
        normalize(np.zeros((20, 3)))
