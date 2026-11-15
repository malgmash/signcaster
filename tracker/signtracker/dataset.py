"""Recorded letter samples: where they live, what is in them, and how we score a model on them.

A sample is the 21 hand points from one camera frame. Never an image. Samples are saved per
signer and letter in tracker/data/<signer>/<letter>.npz (gitignored, see docs/DATA_FORMATS.md).
Pure helpers used by tools/record.py and tools/train.py, so they can be tested without a camera.
"""

from __future__ import annotations

import os
import re
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path

import numpy as np

from signtracker.features import FEATURE_SIZE, POINT_COUNT, BadHand, feature_vector

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
FORMAT_VERSION = 1
# The only things a sample file may hold. tests/test_dataset.py checks nothing else gets in.
SAMPLE_KEYS = ("format_version", "letter", "signing_hand", "points", "aspect", "take")
SIGNING_HANDS = ("right", "left")
# J and Z need motion, so they wait for a model that reads a few frames at a time.
STATIC_LETTERS = "ABCDEFGHIKLMNOPQRSTUVWXY"
SIGNER_ID = re.compile(r"^[a-z0-9_]{2,20}$")


def check_signer_id(value: str) -> str:
    """A nickname like 'malama' or 'tester_2'. Raises ValueError otherwise."""
    if not SIGNER_ID.match(value):
        raise ValueError(
            f"signer id {value!r} must be 2 to 20 characters of a to z, 0 to 9 or _. Use a nickname, not a real name."
        )
    return value


def check_letter(value: str) -> str:
    """One static letter, uppercased. Raises ValueError for J, Z or anything else."""
    letter = value.upper()
    if len(letter) != 1 or letter not in STATIC_LETTERS:
        raise ValueError(f"{value!r} is not a static letter. Use one of {STATIC_LETTERS} (J and Z come later).")
    return letter


def sample_path(data_dir: Path, signer: str, letter: str) -> Path:
    return data_dir / check_signer_id(signer) / f"{check_letter(letter)}.npz"


def read_samples(path: Path) -> dict[str, np.ndarray]:
    """Everything in one sample file. allow_pickle=False, so a file can never run code."""
    with np.load(path, allow_pickle=False) as data:
        return {key: data[key] for key in SAMPLE_KEYS}


def append_take(path: Path, points: np.ndarray, aspect: float, signing_hand: str, letter: str) -> int:
    """Adds one take (N frames of 21 points) to a letter file. Returns the take number, from 1."""
    points = np.asarray(points, dtype=np.float32)
    if points.ndim != 3 or points.shape[1:] != (POINT_COUNT, 3) or len(points) == 0:
        raise ValueError(f"a take is N x {POINT_COUNT} x 3 points, got shape {points.shape}")
    if signing_hand not in SIGNING_HANDS:
        raise ValueError(f"signing_hand must be one of {SIGNING_HANDS}")
    take = 1
    all_points, all_aspect, all_take = points, np.full(len(points), aspect, dtype=np.float32), None
    if path.is_file():
        old = read_samples(path)
        if str(old["signing_hand"]) != signing_hand or str(old["letter"]) != letter:
            raise ValueError(f"{path} holds {old['letter']} signed with the {old['signing_hand']} hand")
        take = int(old["take"].max()) + 1
        all_points = np.concatenate([old["points"], points])
        all_aspect = np.concatenate([old["aspect"], all_aspect])
        all_take = old["take"]
    new_take = np.full(len(points), take, dtype=np.int32)
    all_take = new_take if all_take is None else np.concatenate([all_take, new_take])
    path.parent.mkdir(parents=True, exist_ok=True)
    # Write a temporary file first, then swap it in, so a crash never leaves half a file.
    temporary = path.with_name(path.stem + ".tmp.npz")
    np.savez(
        temporary,
        format_version=FORMAT_VERSION,
        letter=letter,
        signing_hand=signing_hand,
        points=all_points,
        aspect=all_aspect,
        take=all_take,
    )
    os.replace(temporary, path)
    return take


@dataclass
class Dataset:
    features: np.ndarray  # samples x FEATURE_SIZE
    letters: np.ndarray  # one letter per sample
    signers: np.ndarray  # one signer id per sample
    skipped: int = 0  # samples whose points were broken


def sample_files(data_dir: Path) -> Iterator[tuple[str, Path]]:
    """(signer, file) for every letter file, in a stable order."""
    if not data_dir.is_dir():
        return
    for signer_dir in sorted(p for p in data_dir.iterdir() if p.is_dir()):
        for path in sorted(signer_dir.glob("*.npz")):
            if not path.name.endswith(".tmp.npz"):
                yield signer_dir.name, path


def load_all(data_dir: Path = DATA_DIR) -> Dataset:
    """Every recorded sample as features. Left-handed signing is mirrored to look right-handed."""
    features: list[np.ndarray] = []
    letters: list[str] = []
    signers: list[str] = []
    skipped = 0
    for signer, path in sample_files(data_dir):
        samples = read_samples(path)
        mirror = str(samples["signing_hand"]) == "left"
        letter = str(samples["letter"])
        for points, aspect in zip(samples["points"], samples["aspect"], strict=True):
            try:
                features.append(feature_vector(points, float(aspect), mirror))
            except BadHand:
                skipped += 1
                continue
            letters.append(letter)
            signers.append(signer)
    stacked = np.array(features) if features else np.zeros((0, FEATURE_SIZE))
    return Dataset(stacked, np.array(letters, dtype=str), np.array(signers, dtype=str), skipped)


def signer_splits(signers: np.ndarray) -> list[tuple[str, np.ndarray, np.ndarray]]:
    """Leave one signer out: (held-out signer, train indexes, test indexes) for each signer.

    Testing on someone the model never saw is the honest score for a new player.
    """
    splits = []
    for signer in sorted(set(signers.tolist())):
        test = np.flatnonzero(signers == signer)
        train = np.flatnonzero(signers != signer)
        splits.append((signer, train, test))
    return splits


def accuracy_by(groups: np.ndarray, truth: np.ndarray, predicted: np.ndarray) -> dict[str, float]:
    """Share of correct predictions inside each group (a signer, or a letter)."""
    return {
        group: float(np.mean(truth[groups == group] == predicted[groups == group]))
        for group in sorted(set(groups.tolist()))
    }


def confusion(truth: np.ndarray, predicted: np.ndarray, letters: list[str]) -> np.ndarray:
    """Counts: row = the letter that was signed, column = the letter the model said."""
    index = {letter: i for i, letter in enumerate(letters)}
    matrix = np.zeros((len(letters), len(letters)), dtype=int)
    for real, said in zip(truth, predicted, strict=True):
        matrix[index[str(real)], index[str(said)]] += 1
    return matrix


def format_confusion(matrix: np.ndarray, letters: list[str]) -> str:
    """The confusion matrix as text, with the signed letter down the side."""
    width = max(4, len(str(matrix.max())) + 1)
    lines = ["signed \\ said".ljust(14) + "".join(letter.rjust(width) for letter in letters)]
    for letter, row in zip(letters, matrix, strict=True):
        lines.append(letter.ljust(14) + "".join(str(count).rjust(width) for count in row))
    return "\n".join(lines)
