# Monetization Spine v1

Contract for ethical commerce boundaries in Vexlo. Code truth for live behavior remains in services; this document defines product rules and reopen discipline.

## Principles

- Premium core, stronger business shell — revenue must not cheapen the puzzle.
- Monetization is optional, outside active gameplay, and non-predatory.
- No pay-to-win, no board-power grants, no difficulty manipulation for commerce.
- No forced ads, banners, interstitials, or active-gameplay ad interruptions.
- No manipulative scarcity, streak pressure, shame language, or FOMO commerce.
- Daily ritual stays calm; commerce does not colonize daily interpretation.
- Retention spine (residue, mastery, codex, reader) stays earned — not sold.

## Live today (StoreKit / ads)

**Supporter Pack** — only live StoreKit-backed entitlement.

- Product ID: `com.northfall.vexlo.supporterpack`
- Grants: supporter ownership; bypasses rewarded ad for continue-after-loss and tray reroll when offers are otherwise eligible.
- Surfaces: utility menu (purchase + restore), terminal continue, tray reroll (via existing gates).
- Does not grant score, combo, mastery, codex, or reader unlocks.

**Rewarded continue / reroll** — optional commerce paths (AdMob rewarded when configured; unavailable when SDK/units missing).

- Placements: terminal loss continue, mid-run tray reroll.
- Policy: early-player suppression, per-run caps, daily exclusion, ethical reading-value gate for continue.
- Supporter-owned players skip the ad presentation but use the same offer caps.

## Reserved future (not implemented)

Document only — do not treat as live without product + engineering decision:

- `noAds` — standalone remove-ads entitlement if split from Supporter Pack
- `allAccess` — optional bundle for ads + cosmetic access
- `founder` — optional patron/founder unlock
- `atelierCosmetic` — stable cosmetic/theme IDs; presentation-only, never power

Reserved product ID namespace (examples, not App Store active):

- `com.northfall.vexlo.noads` (reserved)
- `com.northfall.vexlo.allaccess` (reserved)
- `com.northfall.vexlo.founder` (reserved)
- `com.northfall.vexlo.atelier.*` (reserved pattern)

## Allowed surfaces

- Terminal loss overlay: continue (rewarded or supporter bypass)
- Active tray slot: reroll badge (mid-run, gated)
- Utility menu: Supporter Pack, Restore Purchases
- Future: atelier/gallery (calm, editorial)
- Future: settings / restore (low-noise)

## Forbidden surfaces

- Active gameplay ad breaks or banners
- Result interpretation stack paywall nudges (Share / copy / spacing locked separately)
- Board generation, scoring, or difficulty tuned for monetization
- Daily pressure monetization or streak-insurance commerce
- Forced full-screen post-run paywall before Play Again
- Monetization that unlocks mastery, codex, or reader profile

## Engineering boundaries

- `EntitlementCatalog` + `EntitlementSnapshot`: read model only; no StoreKit here.
- `SupporterPackService`: sole live StoreKit writer for entitlements today.
- `MonetizationService`: orchestration and capabilities; reads snapshot from catalog boundary.
- `EthicalMonetizationAttachment`: ethics-only gates; unchanged by spine v1 foundation.
- Engine / GameMath: no monetization awareness.

## Reopen rules

Reopen monetization policy or spine contract only for:

- Telemetry or structured user-test evidence
- App Store / legal / privacy requirements
- Explicit product decision recorded in this doc or constitution

Do not reopen locked result/utility visual polish (`Docs/RESULT_UTILITY_VISUAL_POLISH_V1.md`) for monetization convenience.

Do not add visible commerce or SDK work under “spine doc” edits alone.
