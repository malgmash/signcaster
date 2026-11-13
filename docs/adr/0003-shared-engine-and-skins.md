# ADR 0003: One shared engine, swappable skins, connected by an event bus

**Status:** Accepted
**Date:** 2026-11-12

## Context

QB mode and Wizard mode have the same rules (study, pressure, recall, result) with different stories and art. We want to write the hard parts once.

## Decision

All rules live in engine autoloads. Skins are scenes that only listen to `EventBus` signals and call the `Game` facade. The signal list in EVENTS.md is the contract.

## Why

- Wizard mode becomes mostly art and animation work once QB mode works.
- Engine logic can be unit tested without any scenes.
- Clear boundaries make it safer for AI agents to work on one side without breaking the other.

## Trade-offs

- Some features need a new signal, which means updating EVENTS.md and the debug skin too.
- Signals are less obvious to follow than direct calls. The sequence diagram in ARCHITECTURE.md helps.

## Rules that follow from this

- `engine/` never references `skins/` or `ui/` (CI checks this).
- A feature is not done until the debug skin can show it.
