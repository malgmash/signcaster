"""tools/train.py end to end on made-up signers. The shapes are random points, not real letters."""

from __future__ import annotations

import importlib.util
from pathlib import Path
from types import ModuleType

import numpy as np

from signtracker.classifier import LetterModel
from signtracker.dataset import append_take, sample_path
from signtracker.features import feature_vector

TRAIN_PATH = Path(__file__).resolve().parent.parent / "tools" / "train.py"
LETTERS = "ADG"


def load_train() -> ModuleType:
    spec = importlib.util.spec_from_file_location("train_tool", TRAIN_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def record_fake_signers(data_dir: Path, signers: list[str]) -> dict[str, np.ndarray]:
    """Each letter is a random base shape; each signer adds their own small offset and noise."""
    rng = np.random.default_rng(11)
    shapes = {letter: rng.random((21, 3)) for letter in LETTERS}
    for signer in signers:
        offset = rng.normal(scale=0.01, size=(21, 3))
        for letter, shape in shapes.items():
            frames = shape + offset + rng.normal(scale=0.01, size=(30, 21, 3))
            append_take(sample_path(data_dir, signer, letter), frames, 1.0, "right", letter)
    return shapes


def test_trains_scores_by_signer_and_saves_a_model(tmp_path: Path) -> None:
    shapes = record_fake_signers(tmp_path / "data", ["amy", "ben", "cal"])
    out = tmp_path / "models" / "letters.npz"
    lines: list[str] = []
    assert load_train().main(["--data", str(tmp_path / "data"), "--out", str(out)], show=lines.append) == 0
    text = "\n".join(lines)
    assert "3 signer(s)" in text
    assert "Per held-out signer" in text and "amy" in text and "cal" in text
    assert "WARNING" not in text
    model = LetterModel.load(out)
    assert model.letters == tuple(LETTERS)
    for letter, shape in shapes.items():
        probabilities = model.predict(feature_vector(shape))
        assert model.letters[int(np.argmax(probabilities))] == letter


def test_one_signer_warns_that_the_score_is_too_kind(tmp_path: Path) -> None:
    record_fake_signers(tmp_path / "data", ["amy"])
    lines: list[str] = []
    out = tmp_path / "letters.npz"
    assert load_train().main(["--data", str(tmp_path / "data"), "--out", str(out)], show=lines.append) == 0
    assert any("WARNING: only one signer" in line for line in lines)
    assert out.is_file()


def test_no_recordings_explains_what_to_do(tmp_path: Path) -> None:
    lines: list[str] = []
    assert load_train().main(["--data", str(tmp_path), "--out", str(tmp_path / "x.npz")], show=lines.append) == 1
    assert any("tools/record.py" in line for line in lines)
