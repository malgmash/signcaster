"""The numpy letter model and the expect hint. Synthetic numbers only, no recordings."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from signtracker.classifier import (
    BadLetterModel,
    LetterModel,
    LetterModelMissing,
    pick,
    save_model,
    softmax,
)
from signtracker.features import FEATURE_SIZE


def train_sklearn(letter_count: int) -> tuple[object, object, np.ndarray, list[str]]:
    from sklearn.linear_model import LogisticRegression
    from sklearn.preprocessing import StandardScaler

    rng = np.random.default_rng(7)
    letters = [chr(ord("A") + i) for i in range(letter_count)]
    centers = rng.normal(size=(letter_count, FEATURE_SIZE)) * 3
    x = np.vstack([center + rng.normal(size=(40, FEATURE_SIZE)) for center in centers])
    y = np.repeat(letters, 40)
    scaler = StandardScaler().fit(x)
    clf = LogisticRegression(max_iter=2000).fit(scaler.transform(x), y)
    return scaler, clf, x, letters


def save_from_sklearn(path: Path, scaler: object, clf: object) -> None:
    save_model(path, list(clf.classes_), scaler.mean_, scaler.scale_, clf.coef_, clf.intercept_, 80, 2)


@pytest.mark.parametrize("letter_count", [2, 5])
def test_numpy_predictions_match_scikit_learn(tmp_path: Path, letter_count: int) -> None:
    scaler, clf, x, letters = train_sklearn(letter_count)
    path = tmp_path / "letters.npz"
    save_from_sklearn(path, scaler, clf)
    model = LetterModel.load(path)
    assert model.letters == tuple(letters)
    expected = clf.predict_proba(scaler.transform(x[:20]))
    ours = np.array([model.predict(row) for row in x[:20]])
    assert np.allclose(ours, expected, atol=1e-9)


def test_the_file_holds_no_pickled_objects(tmp_path: Path) -> None:
    scaler, clf, _x, _letters = train_sklearn(3)
    path = tmp_path / "letters.npz"
    save_from_sklearn(path, scaler, clf)
    with np.load(path, allow_pickle=False) as data:
        assert all(data[key].dtype != object for key in data.files)


def test_a_missing_model_says_how_to_make_one(tmp_path: Path) -> None:
    with pytest.raises(LetterModelMissing, match="tools/train.py"):
        LetterModel.load(tmp_path / "nope.npz")


def test_a_model_from_other_features_is_refused(tmp_path: Path) -> None:
    scaler, clf, _x, _letters = train_sklearn(3)
    path = tmp_path / "letters.npz"
    save_from_sklearn(path, scaler, clf)
    with np.load(path) as data:
        fields = dict(data)
    fields["feature_version"] = 99
    np.savez(path, **fields)
    with pytest.raises(BadLetterModel, match="feature version"):
        LetterModel.load(path)


def test_wrong_shapes_and_junk_files_are_refused(tmp_path: Path) -> None:
    scaler, clf, _x, _letters = train_sklearn(3)
    path = tmp_path / "letters.npz"
    save_from_sklearn(path, scaler, clf)
    with np.load(path) as data:
        fields = dict(data)
    fields["mean"] = fields["mean"][:10]
    np.savez(path, **fields)
    with pytest.raises(BadLetterModel, match="mean"):
        LetterModel.load(path)
    junk = tmp_path / "junk.npz"
    junk.write_bytes(b"not a model")
    with pytest.raises(BadLetterModel):
        LetterModel.load(junk)


def test_softmax_adds_up_to_one_even_for_big_scores() -> None:
    probabilities = softmax(np.array([1000.0, 999.0, -5.0]))
    assert np.isclose(probabilities.sum(), 1.0)
    assert probabilities[0] > probabilities[1] > probabilities[2]


LETTERS = ("A", "B", "C")


def test_pick_without_a_hint_is_the_top_letter() -> None:
    assert pick(np.array([0.2, 0.7, 0.1]), LETTERS, "") == ("B", 0.7)


def test_the_hint_breaks_a_near_tie() -> None:
    letter, confidence = pick(np.array([0.46, 0.44, 0.10]), LETTERS, "AB")
    assert letter == "A"  # the top letter is expected too, so no swap
    letter, confidence = pick(np.array([0.46, 0.44, 0.10]), LETTERS, "B")
    assert (letter, confidence) == ("B", 0.44)  # real probability, not boosted


def test_the_hint_never_overrides_a_clear_winner() -> None:
    assert pick(np.array([0.80, 0.15, 0.05]), LETTERS, "B") == ("A", 0.80)


def test_the_hint_never_invents_a_letter_outside_the_top_two() -> None:
    assert pick(np.array([0.45, 0.44, 0.11]), LETTERS, "C") == ("A", 0.45)
