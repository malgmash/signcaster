---
name: plan-feature
description: Plan a Signcaster feature against the design docs before any code is written. Use when the user asks to plan, design or think through a feature, or before any change that touches more than three files. Produces a plan only, never edits files.
---

# Plan a feature

You are planning, not building. Do not edit any files.

1. Restate the feature in one sentence. If what the user wants is unclear, ask up to three short questions and stop.
2. Read only the docs that matter, using the "Sources of truth" table in AGENTS.md. Usually docs/GAME_DESIGN.md, docs/ARCHITECTURE.md and docs/EVENTS.md.
3. Check the feature against the golden rules in AGENTS.md. Call out any rule it would bend (engine and skin separation, privacy, cosmetic-only store, sign accuracy).
4. Write the plan:
   - Files to create and files to change, with one line each on why.
   - EventBus signals used, added or changed (changes mean docs/EVENTS.md must change too).
   - Content or config changes in game/content/ and whether the validator needs a new rule.
   - Tests to add (GUT or pytest) and the edge cases they cover.
   - Manual playtest steps.
   - Risks and open questions, especially about game feel.
5. Estimate the size: small (one sitting), medium (two or three), large (split it). If large, propose how to split it into separate PRs.
6. End by asking the user to approve, change or split the plan.
