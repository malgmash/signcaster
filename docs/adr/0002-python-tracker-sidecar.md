# ADR 0002: Hand tracking runs in a separate Python process

**Status:** Accepted
**Date:** 2026-11-12

## Context

Sign it needs hand tracking and a letter classifier. The best free tools (MediaPipe, scikit-learn, PyTorch) are in Python. Godot runs GDScript.

## Decision

Run the tracker as its own Python process (`signtracker`) that sends small JSON messages to the game over UDP on localhost. See TRACKER_PROTOCOL.md.

## Why

- Full access to the Python ML ecosystem without writing native Godot extensions.
- If the tracker crashes, the game keeps running and falls back to Read it.
- We can swap the tracker later (for example an Apple Vision helper on the Mac) without changing the game, as long as it speaks the same protocol.
- A fake tracker makes Sign it testable without a webcam.

## Trade-offs

- Two processes to start. We will add a launcher script in M11.
- A small amount of extra latency from the socket (well under our 300 ms budget).

## Alternatives considered

- GDExtension in C++ with MediaPipe: fastest, but much harder to build on two operating systems.
- Running everything in a browser with MediaPipe for JavaScript: simpler install, but a different engine and weaker control over performance.
