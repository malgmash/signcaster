# ADR 0001: Godot 4 with GDScript

**Status:** Accepted
**Date:** 2026-11-12

## Context

We need a free game engine that runs well on a MacBook (Apple M5) and an HP Envy (Intel Core i5, integrated graphics), that two students can learn quickly, and that AI agents can work with through plain text files.

## Decision

Use Godot 4 (latest stable) with GDScript.

## Why

- Free and open source (MIT license), no revenue terms to worry about.
- Light enough for integrated graphics. Uses Metal on Apple Silicon and Vulkan or Direct3D 12 on Windows.
- GDScript reads like Python, which we already know.
- Scenes and scripts are text files, so diffs are readable and agents can edit them.

## Trade-offs

- Smaller ecosystem than Unity. Fewer tutorials for advanced topics.
- Calling Python ML code directly from Godot is awkward. See ADR 0002.

## Alternatives considered

- Unity (C#): bigger ecosystem, heavier editor, more setup for a 2D game, license terms to track.
- A web game (JavaScript): easy sharing, but webcam ML and performance on the Intel laptop are harder to control.
