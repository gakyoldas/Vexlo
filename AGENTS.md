# Vexlo Agent Rules

This repository is governed by [Docs/VEXLO_CONSTITUTION.md](Docs/VEXLO_CONSTITUTION.md).

Before making changes, every agent must read that constitution.

Operational rules:
- Inspect current source first.
- Keep every change surgical and minimal.
- Touch the fewest files possible.
- Do not invent systems, problems, or architecture.
- Do not broaden scope or refactor unrelated code.
- Preserve masterpiece architecture and a sterile file tree.
- Preserve accepted product decisions unless the task explicitly changes them.
- Preserve the current strategic thesis:
  - business ambition is now at least `$75K/month`
  - this does not justify cheapening the product, copying competitors, or abandoning masterpiece architecture
  - Vexlo must differentiate through board reading, calm intensity, and ritual mastery
  - the product should evolve toward a reading puzzle, where players increasingly read board pressure, future clear potential, and move quality rather than mere legality
  - mastery should become more visible through meaning and product response, not loudness, gimmicks, or spectacle
  - daily should evolve toward a real ritual with subtle day-character
  - a future run-identity or playstyle layer may be valid only if it remains calm, editorial, premium, and non-spammy
  - subtle semantic board response may become a signature surface only if handled with restraint
  - forbidden directions include feature spam, gimmick clutter, booster pressure, fake urgency, manipulative retention tricks, flashy full-3D spectacle, casino-style reward noise, and copycat product drift
  - pursue these directions step by step without forgetting constitution-level architecture, premium restraint, and ethical neuromarketing
- When uncertain, stop and report instead of guessing.

## Simulator discipline (local build / test)

Use the project’s canonical simulator only — see `Scripts/simulator.env` and `run_vexlo_sim.sh`:

- **Device:** iPhone 17 Pro Max (`VEXLO_SIM_ID`)
- **xcodebuild:** `-destination 'platform=iOS Simulator,id=<VEXLO_SIM_ID>'` or `./Scripts/run_tests.sh`
- **Do not** run `simctl erase`, mass `shutdown`, or boot iPhone 17 / iPhone 17 Pro for routine validation unless the user asks.
- **Do not** reset or restart the simulator between normal builds/tests; reuse the already-booted Pro Max.
