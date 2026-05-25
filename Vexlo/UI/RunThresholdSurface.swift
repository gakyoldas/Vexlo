import Foundation

/// Normal-mode early-run surface phases. Daily mode is always post-threshold for policy purposes.
enum RunThresholdPhase: Equatable {
    case preThreshold
    case postThreshold
}

/// Product policy for the first score / first clear threshold in normal mode.
enum RunThresholdSurface {
    static func phase(isDailyChallenge: Bool, score: Int, didClearAny: Bool) -> RunThresholdPhase {
        guard !isDailyChallenge else { return .postThreshold }
        if score == 0, !didClearAny {
            return .preThreshold
        }
        return .postThreshold
    }

    static func isThresholdCrossing(previousScore: Int, newScore: Int, clearedCellCount: Int) -> Bool {
        previousScore == 0 && newScore > 0 && clearedCellCount > 0
    }

    /// Pre-threshold drag highlights footprint only — no line-wide clear bait.
    static func includesClearConsequencesInDragHighlight(for phase: RunThresholdPhase) -> Bool {
        phase == .postThreshold
    }

    static func includesBoardReliefContactsInDragHighlight(
        for phase: RunThresholdPhase,
        isGentleOpeningPhase: Bool
    ) -> Bool {
        phase == .postThreshold && !isGentleOpeningPhase
    }

    static func shouldPresentThresholdCeremony(
        isDailyChallenge: Bool,
        isCaptureMode: Bool,
        isThresholdCrossing: Bool,
        hasPresentedCeremony: Bool
    ) -> Bool {
        !isDailyChallenge &&
            !isCaptureMode &&
            isThresholdCrossing &&
            !hasPresentedCeremony
    }

    static func shouldApplyThresholdScoreAwakening(
        isDailyChallenge: Bool,
        isThresholdCrossing: Bool
    ) -> Bool {
        !isDailyChallenge && isThresholdCrossing
    }
}
