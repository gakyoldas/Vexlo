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

## Rewarded ads configuration (Phase 3)

Rewarded-only policy:

- Allowed: rewarded continue after terminal loss (`continueAfterLoss`)
- Allowed: rewarded tray reroll (`rerollTrayPiece`)
- Forbidden: banners, interstitials, active gameplay ad interruptions, forced ads

Required Info.plist keys (no production values in source — supply at release via plist or build settings):

- `GADApplicationIdentifier` — AdMob app ID
- `VexloRewardedContinueAdUnitID` — rewarded unit for terminal continue
- `VexloRewardedRerollAdUnitID` — rewarded unit for tray reroll

Placeholder empty strings in `Vexlo/Info.plist` are intentional until release IDs are set. Empty values mean unavailable in release builds.

Debug behavior:

- DEBUG builds may fall back to Google test ad unit IDs only when a placement plist value is missing.
- Release builds never use debug test IDs; missing plist values keep that placement unconfigured.
- `RewardedAdsConfiguration.usesDebugTestAdUnits` records whether debug fallback is active.

Capability matrix (rewarded commerce path):

- Available: SDK present, plist fully configured, ad preloaded, MonetizationService policy allows, ethical gate allows, supporter bypass not used yet.
- Unavailable (config): missing app ID and/or placement unit ID, SDK module absent, or ad not yet loaded.
- Bypassed (entitlement): `EntitlementSnapshot.removesRewardedAdRequirement` (supporter today) — offer may proceed without showing rewarded ad; same per-run caps apply.
- Hidden (ethics/policy): daily mode, early-player suppression, insufficient reading value (continue), run state, offer caps — independent of ad config; EthicalMonetizationAttachment + MonetizationService gates unchanged.

Diagnostics: `RewardedAdsService.configurationDiagnostic` and `RewardedAdsConfiguration.diagnostic` expose blockers without user-facing copy.

## Atelier catalog v1 (Phase 4 — persistence only)

Purpose: stable cosmetic IDs, default ownership, and UserDefaults persistence for future ownership and calm aesthetic expression. No UI, StoreKit, visual application, or gameplay effect in this phase.

Non-pay-to-win: cosmetics are presentation-only. They must never grant score, combo, board power, continue/reroll capacity, mastery, codex, reader profile, or difficulty advantage.

Current scope:

- `AtelierCatalog` — seed catalog and category defaults
- `AtelierPersistenceService` — granted ownership + per-category selection
- Categories reuse `AtelierCosmeticCategory` from ethical monetization policy (`boardFrameFinish`, `pieceMineralPalette`, `hudAccentTone`, `shareCardFinish`, `trayRestMarkFinish`)
- Default/free cosmetics are effectively owned without persistence; locked seed items stay unowned until granted
- Invalid or unowned selections resolve to the category default

Deferred: atelier/gallery UI, cosmetic StoreKit products, visual application to board/HUD/share/tray, entitlement wiring from live persistence into `MonetizationService` (compose via `EntitlementCatalog.liveSnapshot(grantedAtelierCosmeticIDs:)` when product approves).

Forbidden grants (unchanged): score/combo power, extra continue, mastery/codex/reader unlocks, streak insurance, scarcity timers, gameplay hints.

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
