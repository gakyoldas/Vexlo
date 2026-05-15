# VEXLO Constitution

## Mission

Vexlo is being built as a premium, category-defining puzzle game.

The target is not incremental polish. The target is a product that can redefine expectations for what a modern premium puzzle game can feel like in taste, coherence, retention quality, and commercial dignity.

The business target is at least `$10K/month` in sustainable revenue. Every meaningful product decision should support at least one of these outcomes without cheapening the game:
- higher product quality
- stronger retention
- clearer differentiation
- healthier revenue visibility

Vexlo is not trying to win through noise, compulsion, or derivative gimmicks. It should win through quality, strategy, ritual, polish, and restraint.

## Non-Negotiables

The following are non-negotiable:
- masterpiece architecture
- sterile repo and file structure
- no bloated or sprawling code
- no unrelated systems added opportunistically
- no speculative abstractions
- no deferred "fix later" debt as a default habit
- no hallucinated features or invented product needs
- no dead branches left behind after a product decision is rejected

Every change must justify its existence in a codebase that is supposed to remain small, coherent, and premium.

## Product Identity

Vexlo is a calm, premium, adult, strategic puzzle product.

Its aesthetic is jewel-toned, dark, mineral, and composed. It should feel intentional and sophisticated rather than playful, childish, loud, or disposable.

Vexlo should feel like a grown-up puzzle game.

Its difference should come from:
- quality
- strategic depth
- remembered ritual
- restraint
- taste

Its difference must not come from:
- cheap stimulation
- fake progression pressure
- casino energy
- noisy spectacle
- toy-like feedback excess

## Visual Constitution

The current premium visual family across opening, midgame, result, utility, and share surfaces must be preserved.

Visual rules:
- maintain Apple-premium restraint
- preserve the dark mineral family and jewel-toned discipline
- preserve calm, high-end composition across all surfaces
- no spammy badges, banners, or attention traps
- no noisy gradients or decorative clutter added casually
- no gratuitous particle storms or spectacle layers
- no arcade-style combo fireworks
- no social-spam share-card drift

Mode distinctions:
- normal mode should remain more evergreen, quieter, and more purely Vexlo
- daily mode should carry the ritual layer
- share cards should remain premium artifacts, not viral gimmick cards

## UX Constitution

Vexlo is direct-to-game by default.

UX rules:
- resume-first behavior stays
- no lobby or home screen unless leadership explicitly re-decides the product
- no second utility menu
- no full-screen onboarding
- only minimal contextual first-use teaching
- utility should remain low-weight, premium, and subordinate to play
- `Start New Run` in utility is an allowed deliberate escape hatch
- player control should be available without breaking calmness

The UX should consistently honor immediacy, dignity, and low friction.

## Gameplay / Engine Constitution

The core engine is not to be destabilized casually.

Rules:
- preserve board geometry and placement correctness
- preserve tray logic unless an explicit targeted engine decision is made
- do not casually rewrite generation logic
- do not disturb scoring or progression semantics without explicit product intent
- do not introduce gimmicks to fake depth

Category-defining quality should come from smart, visible depth rather than novelty clutter.

## Growth / Retention Constitution

Growth should come from premium shareability, visible daily ritual, visible mastery where justified, and elegant retention loops.

Rules:
- no manipulative urgency
- no shame language
- no spam loops
- no cheap gamification layers
- daily ritual should be visible but calm
- mastery or progression should be surfaced only when it materially improves product meaning
- growth mechanics must feel native to Vexlo, never bolted on

If a growth idea feels like a second app layered onto the puzzle, it is wrong by default.

## Monetization Constitution

Monetization must remain ethical, premium, and low-pressure.

Rules:
- no loud free-to-play surfaces
- no banners
- no countdowns
- no scarcity theater
- no shame language
- no pressure copy
- no monetization that breaks emotional tone

`Supporter Pack` and ad-free value may be clarified, but only in respectful, low-noise contexts consistent with the product family.

Revenue visibility matters because the `$10K/month` target is real. But revenue must never be pursued in ways that damage product dignity.

## Apple / Editorial Constitution

Vexlo should support Apple-level product quality.

Rules:
- decisions should support Human Interface Guidelines quality
- aim for Editors’ Choice / feature-worthiness
- aim toward Apple Design Award quality standards without theatrics
- accessibility, semantics, and coherence matter
- polish in sound, feel, motion, and engineering is part of the product’s differentiator

The product should feel worthy of being highlighted by Apple because it is genuinely excellent, not because it performs trend compliance.

## Sound Constitution

Vexlo audio should feel dark mineral, soft glass, premium, and restrained.

Rules:
- no cartoon UI sounds
- no casino reward sounds
- no loud sci-fi toy sounds
- preserve silence discipline
- every sound should feel like it belongs to the same premium family

Audio is part of the identity system, not an afterthought.

## Engineering Process Rules

Engineering rules are strict:
- inspect first
- change one thing at a time
- keep scope surgical
- prefer one-file or smallest-file-set changes
- do not broaden scope opportunistically
- do not clean unrelated code as a side quest
- validate with build, tests, and preflight when relevant
- if a product decision proves weak, revert it cleanly instead of leaving dead support behind

When a task can be solved with a tiny local refinement, solve it there.

## Testing / Release Integrity

Release integrity is a product requirement.

Rules:
- preserve critical regression tests
- preserve preflight script integrity
- preserve sealed premium surfaces through regression coverage where appropriate
- release quality means both aesthetic quality and technical hardening

Do not trade reliability away for speed of iteration.

## Accepted Current Product Decisions

The following directions are accepted and should be preserved unless leadership explicitly changes them:
- direct-to-game opening
- resume-first behavior
- one utility panel only
- no full-screen onboarding
- premium result hierarchy
- premium share-card direction
- quiet daily ritual visibility
- `Start New Run` escape hatch in utility
- masterpiece architecture as a primary constraint

These are not temporary preferences. They are active product decisions.

## Rejected / Avoided Directions

The following directions are rejected or should be treated as hostile by default:
- broad UI redesigns
- lobby or home-screen drift
- additional utility layers
- loud monetization surfaces
- cheap viral gimmicks
- overbuilt progression systems
- noisy onboarding
- casino or arcade effect creep
- speculative code architecture
- feature branches left half-alive in production code

If such a direction is requested implicitly, agents should stop, clarify, or refuse to invent it into the product.

## How Future Agents Must Work

Future agents must follow this contract:
- read `AGENTS.md` and `Docs/VEXLO_CONSTITUTION.md` first
- inspect current source before proposing or making changes
- do not invent problems
- if the requested issue is already solved well enough, say so and make no code changes
- when fixing something, preserve accepted decisions
- keep changes surgical and minimal
- report exact files changed
- report the exact rule adjusted
- report validation performed
- report any remaining risk plainly

If uncertain, stop and report instead of improvising architecture or product direction.
