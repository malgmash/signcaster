"""The letter model: plain numbers in models/letters.npz, predicted with numpy only.

tools/train.py trains a scikit-learn logistic regression and saves just its numbers here.
Why not save the scikit-learn object with joblib or pickle? Loading a pickle can run any
code that is inside the file, it ties the tracker to scikit-learn, and the M12 download
would carry scikit-learn and scipy. A logistic regression is only a scale step, one matrix
multiply and a softmax, so numpy is enough. np.load(allow_pickle=False) can only read numbers
and text, never code.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import numpy as np

from signtracker.features import FEATURE_SIZE, FEATURE_VERSION

LETTER_MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "letters.npz"
MODEL_FORMAT_VERSION = 1
# How close the top two letters must be for the expect hint to choose between them.
TIE_MARGIN = 0.10
MODEL_KEYS = (
    "format_version",
    "feature_version",
    "letters",
    "mean",
    "scale",
    "coef",
    "intercept",
    "sample_count",
    "signer_count",
)


class LetterModelMissing(RuntimeError):
    """There is no trained letter model yet."""

    def __init__(self, path: Path) -> None:
        super().__init__(
            f"Letter model not found at {path}\n"
            "Record letters with tools/record.py, then train with tools/train.py (see tracker/README.md)."
        )


class BadLetterModel(ValueError):
    """The model file exists but does not fit this version of the tracker."""


def softmax(logits: np.ndarray) -> np.ndarray:
    """Turns scores into probabilities that add up to 1. Subtracting the max avoids overflow."""
    shifted = np.exp(logits - np.max(logits))
    return shifted / shifted.sum()


@dataclass(frozen=True)
class LetterModel:
    letters: tuple[str, ...]
    mean: np.ndarray  # per feature, from the StandardScaler
    scale: np.ndarray
    coef: np.ndarray  # letters x features
    intercept: np.ndarray  # per letter

    @classmethod
    def load(cls, path: Path = LETTER_MODEL_PATH) -> LetterModel:
        """Reads and checks a model file. Raises LetterModelMissing or BadLetterModel."""
        if not path.is_file():
            raise LetterModelMissing(path)
        try:
            with np.load(path, allow_pickle=False) as data:
                fields = {key: data[key] for key in MODEL_KEYS}
        except (KeyError, ValueError, OSError) as error:
            raise BadLetterModel(f"{path} is not a letter model this tracker can read ({error})") from error
        if int(fields["format_version"]) != MODEL_FORMAT_VERSION:
            raise BadLetterModel(
                f"{path} has model format {int(fields['format_version'])}, need {MODEL_FORMAT_VERSION}"
            )
        if int(fields["feature_version"]) != FEATURE_VERSION:
            raise BadLetterModel(
                f"{path} was trained on feature version {int(fields['feature_version'])}, "
                f"this tracker makes version {FEATURE_VERSION}. Train again with tools/train.py."
            )
        model = cls(
            letters=tuple(str(letter) for letter in fields["letters"]),
            mean=fields["mean"].astype(np.float64),
            scale=fields["scale"].astype(np.float64),
            coef=fields["coef"].astype(np.float64),
            intercept=fields["intercept"].astype(np.float64),
        )
        model.check_shapes()
        return model

    def check_shapes(self) -> None:
        count = len(self.letters)
        expected = {
            "mean": (FEATURE_SIZE,),
            "scale": (FEATURE_SIZE,),
            "coef": (count, FEATURE_SIZE),
            "intercept": (count,),
        }
        for name, shape in expected.items():
            if getattr(self, name).shape != shape:
                raise BadLetterModel(f"{name} has shape {getattr(self, name).shape}, expected {shape}")
        if count < 2:
            raise BadLetterModel("a letter model needs at least 2 letters")

    def predict(self, features: np.ndarray) -> np.ndarray:
        """One probability per letter, in the order of self.letters."""
        scaled = (features - self.mean) / self.scale
        return softmax(self.coef @ scaled + self.intercept)


def pick(
    probabilities: np.ndarray, letters: tuple[str, ...], expected: str, margin: float = TIE_MARGIN
) -> tuple[str, float]:
    """The top letter and its probability, using the expect hint only to break a near tie.

    The protocol says the hint may break ties but never invent a letter. So the answer is
    always one of the top two, and the hint only swaps them when they are within `margin`,
    the runner-up is in the expected word and the top one is not. The confidence returned is
    the chosen letter's own probability, never boosted.
    """
    order = np.argsort(probabilities)[::-1]
    first = int(order[0])
    if len(order) > 1 and expected:
        second = int(order[1])
        close = probabilities[first] - probabilities[second] <= margin
        if close and letters[second] in expected and letters[first] not in expected:
            return letters[second], float(probabilities[second])
    return letters[first], float(probabilities[first])


def save_model(
    path: Path,
    letters: list[str],
    mean: np.ndarray,
    scale: np.ndarray,
    coef: np.ndarray,
    intercept: np.ndarray,
    sample_count: int,
    signer_count: int,
) -> None:
    """Writes the model numbers. No signer names go in, so the file is safe to share (ADR 0006)."""
    coef = np.asarray(coef, dtype=np.float64)
    intercept = np.asarray(intercept, dtype=np.float64)
    if len(letters) == 2 and coef.shape[0] == 1:
        # scikit-learn stores a 2-letter model as one score w for the second letter, with
        # probability sigmoid(w). A softmax over [-w/2, w/2] gives exactly the same numbers.
        coef = np.vstack([-coef[0] / 2, coef[0] / 2])
        intercept = np.array([-intercept[0] / 2, intercept[0] / 2])
    path.parent.mkdir(parents=True, exist_ok=True)
    np.savez(
        path,
        format_version=MODEL_FORMAT_VERSION,
        feature_version=FEATURE_VERSION,
        letters=np.array(letters, dtype=str),
        mean=mean,
        scale=scale,
        coef=coef,
        intercept=intercept,
        sample_count=sample_count,
        signer_count=signer_count,
    )
