---
name: build-step
description: Run one numbered milestone prompt from docs/prompts (for example 03 for the QB skin) end to end in Signcaster. Use when the user says build step N, run prompt N, or names a milestone like M3.
---
<!-- Generated from .agents/skills by scripts/sync_skills.py. Edit the source, not this copy. -->

# Build a milestone step

1. Find the prompt file in docs/prompts/ whose name starts with the number the user gave (for example "03" means docs/prompts/03-qb-skin-v1.md). If no number was given, ask for one and list the files.
2. Check the "Needs" row at the top of that file. If an earlier milestone is not merged into the current branch, warn the user and stop.
3. Check the current git branch. If it is main, suggest the branch name from the file and ask before creating it.
4. Read the prompt inside the `text` block and follow it exactly as if the user had pasted it. Ignore the notes outside the block.
5. The prompt asks for a plan first. Give the plan and wait for approval before editing.
6. After building, run the commands from AGENTS.md that apply (tests, lint, content validator, boundary check) and report the results honestly, including failures.
7. Finish by showing the "After the agent finishes" checklist from the prompt file so the user can do it by hand.
