# Template: refactor without changing behavior

```text
Refactor [file or folder] in Signcaster. Follow AGENTS.md.

Goal: [for example "split challenge_manager.gd into smaller functions" or "remove duplicate code between the QB and Wizard bubbles"]

Rules:
- Behavior must not change. All existing tests must pass before and after.
- If tests are missing for the code you are touching, add them first, in a separate commit.
- No new features, no renamed EventBus signals, no content changes.

Before editing, show me the before and after structure. Wait for my OK.
Report: what moved where and why it is easier to understand now.
```
