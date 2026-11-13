# Template: write tests for existing code

```text
Write tests for [file or function, for example game/engine/difficulty.gd]. Follow AGENTS.md.

Use GUT for game code (game/tests/) and pytest for tracker code (tracker/tests/).
Control time with the Clock autoload and randomness with a seeded RandomNumberGenerator so tests never flake.

Cover:
- the normal case
- boundaries (exact thresholds like remaining_ratio == 0.5, caps, empty lists)
- error cases (bad content, missing tracker, corrupt input)
- [anything specific I am worried about]

Do not change the code under test. If you find a bug, write a failing test, mark it clearly, and tell me instead of fixing it.

Report: what each test checks in one line each, and which cases you think are still untested.
```
