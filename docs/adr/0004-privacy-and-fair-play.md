# ADR 0004: Privacy and fair play by default

**Status:** Accepted
**Date:** 2026-11-12

## Context

The game uses a webcam and has a kids mode. In the U.S., the FTC's COPPA rule applies to apps and online games aimed at children under 13 that collect personal information, and requires verifiable parental consent before collecting it. We also want a store that motivates players without being unfair.

## Decision

- Webcam frames are processed in memory by the tracker and never saved or sent anywhere.
- No accounts, no names, no analytics, no network use besides the localhost tracker socket in v1.
- Saves hold only progress and settings, on the device.
- The store is cosmetic only. Coins are earned by playing. No real-money purchases and no loot boxes.

## Why

- The simplest way to respect players, especially kids, is to not collect anything.
- Cosmetic-only items keep the learning honest: nobody can buy an easier game.

## Trade-offs

- No cloud saves or online leaderboards in v1.
- If we ever add accounts or online features, we must revisit this ADR and check COPPA requirements first. We are not lawyers.
