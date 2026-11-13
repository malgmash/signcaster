"""The package exposes a version string that the hello message can report."""

import re

import signtracker


def test_version_is_major_minor_patch() -> None:
    assert re.fullmatch(r"\d+\.\d+\.\d+", signtracker.__version__)
