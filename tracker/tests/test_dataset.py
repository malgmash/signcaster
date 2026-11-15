"""Sample files, nicknames, signer splits and the report helpers. Random points, no camera."""

from __future__ import annotations

from pathlib import Path

import numpy as np
import pytest

from signtracker.dataset import (
    SAMPLE_KEYS,
    accuracy_by,
    append_take,
    check_letter,
    check_signer_id,
    confusion,
    format_confusion,
    load_all,
    read_samples,
    sample_path,
    signer_splits,
)
from signtracker.features import feature_vector

RNG = np.random.default_rng(3)


def take(frames: int = 5) -> np.ndarray:
    return RNG.random((frames, 21, 3)).astype(np.float32)


@pytest.mark.parametrize("good", ["malama", "tester_2", "ab"])
def test_good_nicknames(good: str) -> None:
    assert check_signer_id(good) == good


@pytest.mark.parametrize("bad", ["", "a", "Malama", "first last", "../escape", "x" * 21, "me@mail"])
def test_bad_nicknames_are_refused(bad: str) -> None:
    with pytest.raises(ValueError, match="nickname"):
        check_signer_id(bad)


def test_letters_are_static_and_uppercased() -> None:
    assert check_letter("a") == "A"
    for bad in ("J", "Z", "AB", "1", ""):
        with pytest.raises(ValueError):
            check_letter(bad)


def test_sample_path_is_per_signer_and_letter(tmp_path: Path) -> None:
    assert sample_path(tmp_path, "malama", "d") == tmp_path / "malama" / "D.npz"


def test_takes_append_and_count_up(tmp_path: Path) -> None:
    path = sample_path(tmp_path, "malama", "A")
    assert append_take(path, take(5), 16 / 9, "right", "A") == 1
    assert append_take(path, take(3), 4 / 3, "right", "A") == 2
    samples = read_samples(path)
    assert samples["points"].shape == (8, 21, 3)
    assert samples["take"].tolist() == [1] * 5 + [2] * 3
    assert np.allclose(samples["aspect"], [16 / 9] * 5 + [4 / 3] * 3)
    assert not list(path.parent.glob("*.tmp.npz"))


def test_a_sample_file_holds_only_the_allowed_keys(tmp_path: Path) -> None:
    path = sample_path(tmp_path, "malama", "A")
    append_take(path, take(), 1.0, "right", "A")
    with np.load(path, allow_pickle=False) as data:
        assert sorted(data.files) == sorted(SAMPLE_KEYS)
        assert data["points"].shape[1:] == (21, 3)  # points, not pixels


def test_mixing_hands_in_one_file_is_refused(tmp_path: Path) -> None:
    path = sample_path(tmp_path, "malama", "A")
    append_take(path, take(), 1.0, "right", "A")
    with pytest.raises(ValueError, match="right hand"):
        append_take(path, take(), 1.0, "left", "A")


def test_bad_takes_are_refused(tmp_path: Path) -> None:
    path = sample_path(tmp_path, "malama", "A")
    with pytest.raises(ValueError):
        append_take(path, np.zeros((0, 21, 3)), 1.0, "right", "A")
    with pytest.raises(ValueError):
        append_take(path, np.zeros((4, 20, 3)), 1.0, "right", "A")
    with pytest.raises(ValueError):
        append_take(path, take(), 1.0, "both", "A")


def test_load_all_mirrors_left_handed_signers(tmp_path: Path) -> None:
    points = take(2)
    append_take(sample_path(tmp_path, "righty", "A"), points, 1.0, "right", "A")
    append_take(sample_path(tmp_path, "lefty", "B"), points, 1.0, "left", "B")
    data = load_all(tmp_path)
    assert data.signers.tolist() == ["lefty", "lefty", "righty", "righty"]
    assert data.letters.tolist() == ["B", "B", "A", "A"]
    assert np.allclose(data.features[0], feature_vector(points[0], 1.0, mirror=True))
    assert np.allclose(data.features[2], feature_vector(points[0], 1.0, mirror=False))


def test_broken_samples_are_skipped_and_counted(tmp_path: Path) -> None:
    points = take(3)
    points[1] = 0.5  # every point in one spot
    append_take(sample_path(tmp_path, "malama", "A"), points, 1.0, "right", "A")
    data = load_all(tmp_path)
    assert (len(data.letters), data.skipped) == (2, 1)


def test_an_empty_or_missing_folder_has_no_samples(tmp_path: Path) -> None:
    assert len(load_all(tmp_path / "nothing").letters) == 0


def test_each_split_keeps_one_signer_out_of_training() -> None:
    signers = np.array(["a", "b", "a", "c", "b"])
    splits = signer_splits(signers)
    assert [held for held, _train, _test in splits] == ["a", "b", "c"]
    for held, train, test in splits:
        assert set(signers[test]) == {held}
        assert held not in set(signers[train])
        assert len(train) + len(test) == len(signers)


def test_accuracy_and_confusion() -> None:
    truth = np.array(["A", "A", "B", "B"])
    said = np.array(["A", "B", "B", "B"])
    signers = np.array(["x", "x", "y", "y"])
    assert accuracy_by(signers, truth, said) == {"x": 0.5, "y": 1.0}
    assert accuracy_by(truth, truth, said) == {"A": 0.5, "B": 1.0}
    matrix = confusion(truth, said, ["A", "B"])
    assert matrix.tolist() == [[1, 1], [0, 2]]
    text = format_confusion(matrix, ["A", "B"])
    assert text.splitlines()[1].split() == ["A", "1", "1"]
