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

    static func summary(context: RunReadingContext) -> RunReadingSummary {
        let isNewBest = context.score >= context.best && context.score > context.runStartBest
        return RunReadingSummary(
            caption: VexloStrings.RunReading.runComplete,
            readingDetail: readingDetail(for: context),
            badge: isNewBest ? VexloStrings.Overlay.newBest : "",
            progress: progressLine(for: context, isNewBest: isNewBest)
        )
    }

    static func readingDetail(for context: RunReadingContext) -> String {
        if context.hasUsedContinue {
            return VexloStrings.Overlay.runRecoveredLate
        }
        if context.maxCombo >= 2, context.didClearAny {
            return VexloStrings.RunReading.chainLedReading
        }
        if context.didClearAny,
           context.terminalPressureBand == .taut
               || context.occupiedCellCount >= BoardPressure.tautOccupancyLowerBound {
            return VexloStrings.RunReading.readUnderPressure
        }
        if context.didClearAny {
            return VexloStrings.Overlay.runSteadyClears
        }
        return VexloStrings.Overlay.runTightBoard
    }

    static func progressLine(for context: RunReadingContext, isNewBest: Bool) -> String {
        if let nearMiss = quietNearMissMasteryLine(
            score: context.score,
            best: context.best,
            maxCombo: context.maxCombo,
            didClearAny: context.didClearAny,
            hasUsedContinue: context.hasUsedContinue
        ) {
            return nearMiss
        }
        if let gapLine = credibleGapToBestLine(
            score: context.score,
            best: context.best,
            didClearAny: context.didClearAny,
            hasUsedContinue: context.hasUsedContinue,
            isNewBest: isNewBest
        ) {
            return gapLine
        }
        if context.completedRuns > 0 {
            return VexloStrings.Overlay.runCount(context.completedRuns)
        }
        return ""
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
        return VexloStrings.Overlay.oneCleanerRun
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
