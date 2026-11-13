# ADR 0005: Game content as validated JSON files

**Status:** Accepted
**Date:** 2026-11-12

## Context

Word packs, store items, prices and difficulty numbers will change constantly during playtesting. Both humans and AI agents edit them.

## Decision

Keep all content and tuning numbers in JSON under `game/content/`, with a version field, and validate it with `scripts/validate_content.py` locally and in CI.

## Why

- Tuning the game does not require code changes.
- JSON diffs are easy to review in pull requests.
- The validator catches mistakes early, including rules like "store items have no gameplay stats" and "kid mode words are kid safe".

## Trade-offs

- No editor UI for content. Godot custom resources would give one, but are harder to diff and validate outside Godot.
