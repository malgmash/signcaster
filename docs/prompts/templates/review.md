# Template: review a pull request

Use this when you are not using the `review-diff` skill, or to review someone else's PR.

```text
Review the changes on this branch compared with main. Follow AGENTS.md. Do not edit files; only report.

Check, in this order:
1. Correctness: logic errors, off-by-one mistakes, timers, state machine transitions, null or missing data.
2. Golden rules from AGENTS.md: engine and skin separation, EventBus contract matches docs/EVENTS.md, content in JSON, privacy, cosmetic-only store, sign accuracy.
3. Tests: do they exist for new logic, and would they fail if the logic broke?
4. Docs: did any signal, data format or design rule change without a doc update?
5. Performance: anything heavy per frame, especially on Intel integrated graphics.
6. Readability for two CS students who will maintain this.

Format: a list of findings, most important first. For each: file and line, what is wrong, why it matters, and a suggested fix. Say clearly if you found nothing serious.
```
