"""tools/record.py: the checks that run before any camera opens."""

from __future__ import annotations

import importlib.util
from pathlib import Path
from types import ModuleType

import pytest

RECORD_PATH = Path(__file__).resolve().parent.parent / "tools" / "record.py"


def load_record() -> ModuleType:
    spec = importlib.util.spec_from_file_location("record_tool", RECORD_PATH)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_letters_are_checked_and_deduplicated() -> None:
    record = load_record()
    assert record.unique_letters("adgmoa") == ["A", "D", "G", "M", "O"]
    with pytest.raises(ValueError):
        record.unique_letters("AJ")


def test_consent_needs_the_word_yes() -> None:
    record = load_record()
    shown: list[str] = []
    assert record.ask_consent(Path("data/malama"), read=lambda _prompt: " YES ", show=shown.append)
    assert "never saves images" in shown[0]
    for answer in ("", "y", "no", "yes please"):
        assert not record.ask_consent(Path("data/x"), read=lambda _prompt, a=answer: a, show=shown.append)


def test_no_consent_records_nothing(tmp_path: Path) -> None:
    record = load_record()
    argv = ["--signer", "malama", "--letters", "A", "--data", str(tmp_path)]
    assert record.main(argv, read=lambda _prompt: "no") == 1
    assert not any(tmp_path.iterdir())


def test_a_real_name_style_id_is_refused_before_consent(tmp_path: Path) -> None:
    record = load_record()
    asked: list[str] = []
    argv = ["--signer", "First Last", "--letters", "A", "--data", str(tmp_path)]
    assert record.main(argv, read=lambda prompt: asked.append(prompt) or "yes") == 2
    assert asked == []
