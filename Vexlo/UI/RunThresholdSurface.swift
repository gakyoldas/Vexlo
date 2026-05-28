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

    /// Pre-threshold still shows full consequence only for real clear-producing placements.
    static func includesClearConsequencesInDragHighlight(
        for phase: RunThresholdPhase,
        clearedLineCount: Int
    ) -> Bool {
        phase == .postThreshold || clearedLineCount > 0
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
