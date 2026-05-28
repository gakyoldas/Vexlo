import Foundation

/// Terminal facts for normal-run reading summary (Phase 4.1).
struct RunReadingContext: Equatable {
    let score: Int
    let best: Int
    let runStartBest: Int
    let maxCombo: Int
    let didClearAny: Bool
    let hasUsedContinue: Bool
    let terminalPressureBand: BoardPressureBand
    let occupiedCellCount: Int
    let completedRuns: Int
}

/// Editorial normal-run result copy from existing terminal signals only (Phase 4.1).
struct RunReadingSummary: Equatable {
    let caption: String
    let readingDetail: String
    let badge: String
    let progress: String
    let replayLabel: String

    static func summary(context: RunReadingContext) -> RunReadingSummary {
        let isNewBest = context.score >= context.best && context.score > context.runStartBest
        let mapping = mappingForContext(context, isNewBest: isNewBest)
        return RunReadingSummary(
            caption: VexloStrings.RunReading.runComplete,
            readingDetail: mapping.primary,
            badge: isNewBest ? VexloStrings.Overlay.newBest : "",
            progress: mapping.secondary,
            replayLabel: mapping.replayLabel
        )
    }

    static func readingDetail(for context: RunReadingContext) -> String {
        let isNewBest = context.score >= context.best && context.score > context.runStartBest
        return mappingForContext(context, isNewBest: isNewBest).primary
    }

    /// Stable residue / archive key aligned with `mappingForContext` priority.
    static func readingDetailKey(for context: RunReadingContext) -> String {
        let isNewBest = context.score >= context.best && context.score > context.runStartBest
        if isNewBest {
            return "your_best_run_yet"
        }
        if context.hasUsedContinue {
            return "run_recovered_late"
        }
        if isPressureCollapse(context) {
            return "read_under_pressure"
        }
        if isNearBestMiss(context, isNewBest: isNewBest) {
            return "close_to_best"
        }
        if context.didClearAny, context.maxCombo >= 2 {
            return "chain_led_reading"
        }
        if context.didClearAny {
            if shouldClassifyAsBoardClosedEarly(context) {
                return "board_closed_early"
            }
            return "clear_rhythm_held"
        }
        return "no_clear_found"
    }

    static func progressLine(for context: RunReadingContext, isNewBest: Bool) -> String {
        mappingForContext(context, isNewBest: isNewBest).secondary
    }

    static func replayLabel(for context: RunReadingContext) -> String {
        let isNewBest = context.score >= context.best && context.score > context.runStartBest
        return mappingForContext(context, isNewBest: isNewBest).replayLabel
    }

    private static let lowScoreBoardClosureThreshold = 150
    private static let boardClosureSoftBandUpper = 170
    private static let boardClosureSoftBandMinimumOccupancy = 12
    private static let clearRhythmLowMidUpper = 500
    private static let clearRhythmHighMidUpper = 700
    private static let chainLedMidBandUpper = 700
    private static let pressureCollapseMinimumScore = 150
    private static let pressureCollapseMaximumScore = 450
    private static let pressureCollapseMinimumCombo = 2
    private static let pressureCollapseMinimumOccupancy = BoardPressure.tautOccupancyLowerBound + 1

    private struct Mapping {
        let primary: String
        let secondary: String
        let replayLabel: String
    }

    private static func mappingForContext(_ context: RunReadingContext, isNewBest: Bool) -> Mapping {
        if isNewBest {
            let secondary = hasCleanerRunImplication(context)
                ? VexloStrings.Overlay.oneCleanerReadGoesFartherStill
                : ""
            return Mapping(
                primary: VexloStrings.Overlay.yourBestRunYet,
                secondary: secondary,
                replayLabel: context.didClearAny ? VexloStrings.Overlay.playCleanerRun : VexloStrings.Overlay.playAgain
            )
        }

        if context.hasUsedContinue {
            return Mapping(
                primary: VexloStrings.Overlay.runRecoveredLate,
                secondary: VexloStrings.Overlay.stabilizeOneTurnEarlier,
                replayLabel: VexloStrings.Overlay.playCleanerRun
            )
        }

        if isPressureCollapse(context) {
            return Mapping(
                primary: VexloStrings.Overlay.readUnderPressure,
                secondary: VexloStrings.Overlay.rematchReleaseEarlier,
                replayLabel: VexloStrings.Overlay.playCleanerRun
            )
        }

        if isNearBestMiss(context, isNewBest: isNewBest) {
            let secondary = quietNearMissMasteryLine(
                score: context.score,
                best: context.best,
                maxCombo: context.maxCombo,
                didClearAny: context.didClearAny,
                hasUsedContinue: context.hasUsedContinue
            ) ?? credibleGapToBestLine(
                score: context.score,
                best: context.best,
                didClearAny: context.didClearAny,
                hasUsedContinue: context.hasUsedContinue,
                isNewBest: isNewBest
            ) ?? VexloStrings.Overlay.oneCleanerReadGoesFarther
            return Mapping(
                primary: VexloStrings.Overlay.closeToBest,
                secondary: secondary,
                replayLabel: VexloStrings.Overlay.playCleanerRun
            )
        }

        if context.didClearAny, context.maxCombo >= 2 {
            return Mapping(
                primary: VexloStrings.RunReading.chainLedReading,
                secondary: chainLedSecondary(for: context),
                replayLabel: VexloStrings.Overlay.playCleanerRun
            )
        }

        if context.didClearAny {
            if shouldClassifyAsBoardClosedEarly(context) {
                return Mapping(
                    primary: VexloStrings.Overlay.boardClosedEarly,
                    secondary: VexloStrings.Overlay.rematchOpenLaneEarlier,
                    replayLabel: VexloStrings.Overlay.playCleanerRun
                )
            }
            return Mapping(
                primary: VexloStrings.Overlay.runSteadyClears,
                secondary: clearRhythmSecondary(for: context),
                replayLabel: VexloStrings.Overlay.playCleanerRun
            )
        }

        return Mapping(
            primary: VexloStrings.Overlay.runTightBoard,
            secondary: VexloStrings.Overlay.rematchOpenLaneEarlier,
            replayLabel: VexloStrings.Overlay.playAgain
        )
    }

    private static let clearRhythmUnderConvertedScoreUpper = 300

    private static func clearRhythmSecondary(for context: RunReadingContext) -> String {
        if context.score <= clearRhythmLowMidUpper {
            if isClosingBoardShape(context) {
                return VexloStrings.Overlay.clearRhythmLanesClosedIn
            }
            if context.score <= clearRhythmUnderConvertedScoreUpper,
               context.terminalPressureBand == .calm {
                return VexloStrings.Overlay.clearRhythmConversionStillThin
            }
            return VexloStrings.Overlay.rematchKeepAnchorOpen
        }
        if context.score <= clearRhythmHighMidUpper {
            if isClosingBoardShape(context) {
                return VexloStrings.Overlay.keepOneLaneOpenEarlier
            }
            if context.terminalPressureBand == .calm,
               context.occupiedCellCount <= BoardPressure.calmOccupancyUpperBound {
                return VexloStrings.Overlay.clearRhythmNotExtended
            }
            return VexloStrings.Overlay.keepOneLaneOpenEarlier
        }
        return VexloStrings.Overlay.keepOneAnchorFree
    }

    private static func chainLedSecondary(for context: RunReadingContext) -> String {
        if context.score > chainLedMidBandUpper {
            return context.terminalPressureBand == .attentive
                ? VexloStrings.Overlay.keepOneLaneOpenEarlier
                : ""
        }
        if context.terminalPressureBand == .taut {
            return VexloStrings.Overlay.chainLedOpennessSlipped
        }
        if context.maxCombo == 2, context.score <= 400 {
            return VexloStrings.Overlay.chainLedConversionStillThin
        }
        if context.maxCombo >= 3, context.terminalPressureBand == .attentive {
            return VexloStrings.Overlay.chainLedPaceDidNotHold
        }
        if context.terminalPressureBand == .attentive {
            return VexloStrings.Overlay.chainLedOpennessSlipped
        }
        if context.maxCombo == 2 {
            return VexloStrings.Overlay.chainLedPaceDidNotHold
        }
        return VexloStrings.Overlay.keepOneLaneOpenEarlier
    }

    private static func isClosingBoardShape(_ context: RunReadingContext) -> Bool {
        context.terminalPressureBand == .taut
            || context.occupiedCellCount >= BoardPressure.attentiveOccupancyUpperBound
    }

    private static func shouldClassifyAsBoardClosedEarly(_ context: RunReadingContext) -> Bool {
        if context.score < lowScoreBoardClosureThreshold,
           context.terminalPressureBand == .taut,
           context.occupiedCellCount >= boardClosureSoftBandMinimumOccupancy {
            return true
        }
        guard context.score >= lowScoreBoardClosureThreshold,
              context.score <= boardClosureSoftBandUpper else {
            return false
        }
        // Boundary smoothing around 150: preserve weak-shape truth
        // for low-combo, low-occupancy, non-taut terminal states.
        return context.maxCombo < 2
            && context.terminalPressureBand != .taut
            && context.occupiedCellCount < boardClosureSoftBandMinimumOccupancy
    }

    private static func hasCleanerRunImplication(_ context: RunReadingContext) -> Bool {
        isNearBestMiss(context, isNewBest: false) || (context.maxCombo >= 2 && context.didClearAny && !context.hasUsedContinue)
    }

    private static func isNearBestMiss(_ context: RunReadingContext, isNewBest: Bool) -> Bool {
        quietNearMissMasteryLine(
            score: context.score,
            best: context.best,
            maxCombo: context.maxCombo,
            didClearAny: context.didClearAny,
            hasUsedContinue: context.hasUsedContinue
        ) != nil || credibleGapToBestLine(
            score: context.score,
            best: context.best,
            didClearAny: context.didClearAny,
            hasUsedContinue: context.hasUsedContinue,
            isNewBest: isNewBest
        ) != nil
    }

    private static func isPressureCollapse(_ context: RunReadingContext) -> Bool {
        guard context.didClearAny,
              context.score >= pressureCollapseMinimumScore,
              context.score <= pressureCollapseMaximumScore,
              context.maxCombo >= pressureCollapseMinimumCombo,
              context.terminalPressureBand == .taut,
              context.occupiedCellCount >= pressureCollapseMinimumOccupancy else {
            return false
        }
        return true
    }

    static func quietNearMissMasteryLine(
        score: Int,
        best: Int,
        maxCombo: Int,
        didClearAny: Bool,
        hasUsedContinue: Bool
    ) -> String? {
        let gap = best - score
        guard gap > 0,
              gap <= 30,
              maxCombo >= 2,
              didClearAny,
              !hasUsedContinue else {
            return nil
        }
        return VexloStrings.Overlay.oneCleanerReadGoesFarther
    }

    static func credibleGapToBestLine(
        score: Int,
        best: Int,
        didClearAny: Bool,
        hasUsedContinue: Bool,
        isNewBest: Bool
    ) -> String? {
        guard !isNewBest,
              didClearAny,
              !hasUsedContinue,
              score > 0 else {
            return nil
        }
        let gap = best - score
        guard gap > 0, gap <= 30 else { return nil }
        return VexloStrings.Overlay.gapToBest(gap)
    }
}
