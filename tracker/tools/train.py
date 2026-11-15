"""Train the letter model: `python tools/train.py [--data data] [--out models/letters.npz]`.

Reads every signer's recordings, scores two models by leaving one signer out at a time
(so the score is about a new person, not the person who recorded), prints the report, then
trains logistic regression on everything and saves its numbers to models/letters.npz.

k-nearest neighbors is scored too, for comparison, but never saved: a k-NN model is a copy
of every recorded sample, and the saved model must be safe to share (docs/adr/0006).
"""

from __future__ import annotations

import argparse
from collections.abc import Callable
from pathlib import Path

import numpy as np

from signtracker.classifier import LETTER_MODEL_PATH, save_model
from signtracker.dataset import (
    DATA_DIR,
    Dataset,
    accuracy_by,
    confusion,
    format_confusion,
    load_all,
    signer_splits,
)

KNN = "k-nearest neighbors"
LOGISTIC = "logistic regression"
NEIGHBORS = 5
MAX_ITERATIONS = 2000
SEED = 0
ONE_SIGNER_TEST_SHARE = 0.25
# How much better k-NN must score before the report mentions it.
NOTABLE_GAP = 0.05


def make_model(name: str, train_size: int) -> object:
    """A fresh scikit-learn pipeline: scale each feature, then classify."""
    from sklearn.linear_model import LogisticRegression
    from sklearn.neighbors import KNeighborsClassifier
    from sklearn.pipeline import make_pipeline
    from sklearn.preprocessing import StandardScaler

    if name == KNN:
        return make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=min(NEIGHBORS, train_size)))
    return make_pipeline(StandardScaler(), LogisticRegression(max_iter=MAX_ITERATIONS, random_state=SEED))


def splits_for(data: Dataset, show: Callable[[str], None]) -> list[tuple[str, np.ndarray, np.ndarray]]:
    """Leave-one-signer-out, or a random split with a warning when there is only one signer."""
    signers = sorted(set(data.signers.tolist()))
    if len(signers) >= 2:
        return signer_splits(data.signers)
    from sklearn.model_selection import train_test_split

    show(
        "\nWARNING: only one signer recorded. The score below tests on other frames of the SAME\n"
        "person, so it says nothing about a new player and will look too good. Record a second signer.\n"
    )
    indexes = np.arange(len(data.letters))
    train, test = train_test_split(indexes, test_size=ONE_SIGNER_TEST_SHARE, random_state=SEED, stratify=data.letters)
    return [(f"{signers[0]} (random frames)", train, test)]


def cross_predict(name: str, data: Dataset, splits: list[tuple[str, np.ndarray, np.ndarray]]) -> np.ndarray:
    """Each sample's prediction from a model that never saw that sample's signer."""
    # "" marks samples no split tested (only happens with the one-signer random split).
    predicted = np.full(len(data.letters), "", dtype=data.letters.dtype)
    for _held, train, test in splits:
        model = make_model(name, len(train))
        model.fit(data.features[train], data.letters[train])
        predicted[test] = model.predict(data.features[test])
    return predicted


def report(
    name: str,
    data: Dataset,
    splits: list[tuple[str, np.ndarray, np.ndarray]],
    predicted: np.ndarray,
    show: Callable[[str], None],
) -> float:
    """Prints one model's scores and returns its overall held-out accuracy."""
    tested = predicted != ""
    truth, said = data.letters[tested], predicted[tested]
    overall = float(np.mean(truth == said))
    show(f"\n== {name}: {overall:.0%} correct on held-out samples ==")
    groups = np.empty(len(data.letters), dtype=object)
    for held, _train, test in splits:
        groups[test] = held
    show("Per held-out signer (the model never saw this person):")
    for signer, score in accuracy_by(groups[tested].astype(str), truth, said).items():
        show(f"  {signer:<24} {score:.0%}")
    show("Per letter:")
    for letter, score in accuracy_by(truth, truth, said).items():
        show(f"  {letter}  {score:.0%}")
    return overall


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="python tools/train.py", description=__doc__.splitlines()[0])
    parser.add_argument("--data", type=Path, default=DATA_DIR, help=f"recordings folder (default {DATA_DIR})")
    parser.add_argument("--out", type=Path, default=LETTER_MODEL_PATH, help=f"model file (default {LETTER_MODEL_PATH})")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None, show: Callable[[str], None] = print) -> int:
    args = parse_args(argv)
    data = load_all(args.data)
    letters = sorted(set(data.letters.tolist()))
    signers = sorted(set(data.signers.tolist()))
    if len(letters) < 2:
        show(f"Need recordings of at least 2 letters in {args.data}, found {letters or 'none'}.")
        show("Record with: python tools/record.py --signer <nickname> --letters ADGMO")
        return 1
    show(f"{len(data.letters)} samples, {len(letters)} letters ({''.join(letters)}), {len(signers)} signer(s).")
    if data.skipped:
        show(f"Skipped {data.skipped} broken samples.")
    splits = splits_for(data, show)
    scores = {}
    for name in (KNN, LOGISTIC):
        predicted = cross_predict(name, data, splits)
        scores[name] = report(name, data, splits, predicted, show)
        if name == LOGISTIC:
            tested = predicted != ""
            show("Confusion (row = letter signed, column = letter the model said):")
            show(format_confusion(confusion(data.letters[tested], predicted[tested], letters), letters))
    if scores[KNN] - scores[LOGISTIC] > NOTABLE_GAP:
        show(
            f"\nNote: k-NN scored {scores[KNN] - scores[LOGISTIC]:.0%} better, but it is not saved because a "
            "k-NN model is a copy of the recordings. More signers usually closes the gap."
        )
    final = make_model(LOGISTIC, len(data.letters)).fit(data.features, data.letters)
    scaler, classifier = final[0], final[-1]
    save_model(
        args.out,
        [str(letter) for letter in classifier.classes_],
        scaler.mean_,
        scaler.scale_,
        classifier.coef_,
        classifier.intercept_,
        sample_count=len(data.letters),
        signer_count=len(signers),
    )
    show(f"\nSaved logistic regression trained on all {len(data.letters)} samples to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
