import Foundation

/// Editorial daily completion copy derived from identity + completion facts (Phase 3C.1).
/// Read-only presentation layer; does not mutate daily state or generation.
struct DailyRitualClosure: Equatable {
    let completionCaption: String
    let closureDetail: String
    let badge: String
    let progress: String
    let replayLabel: String

    static func closure(
        identity: DailyRitualIdentity,
        completion: DailyChallengeCompletion?,
        didClearAny: Bool
    ) -> DailyRitualClosure {
        let streakCount = max(0, completion?.streakCount ?? 0)
        let score = max(0, completion?.score ?? 0)
        let isNewBestToday = completion?.isNewBestToday == true && score > 0
        let strongCompletionThreshold = 320
        let modestCompletionThreshold = 220
        let modestCompletionSoftThreshold = 240
        let modestCompletionReplayLiftThreshold = 280
        let strongContinuitySoftThreshold = 360
        let isZeroOrNoClear = score == 0 || !didClearAny
        let isStrongCompletion = !isZeroOrNoClear && score >= strongCompletionThreshold
        let isModestCompletion = !isZeroOrNoClear
            && (score >= modestCompletionSoftThreshold
                || (score >= modestCompletionThreshold && isNewBestToday))
        let isContinuityEligible = isStrongCompletion
            && streakCount > 0
            && (score >= strongContinuitySoftThreshold || isNewBestToday)
        let isCompletionQuality = isStrongCompletion || isModestCompletion
        let isWeakRecorded = !isCompletionQuality && !isZeroOrNoClear

        let caption: String
        let badge: String
        let detail: String
        let progress: String

        if isZeroOrNoClear {
            caption = VexloStrings.DailyRitual.todayRecorded
            badge = ""
            detail = VexloStrings.Overlay.runTightBoard
            progress = VexloStrings.Overlay.rematchOpenLaneEarlier
        } else if isWeakRecorded {
            caption = VexloStrings.DailyRitual.todayRecorded
            badge = ""
            detail = VexloStrings.Overlay.oneCleanerBoardGoesFarther
            progress = didClearAny ? VexloStrings.Overlay.rematchOpenLaneEarlier : ""
        } else if isCompletionQuality {
            caption = VexloStrings.DailyRitual.completionCaption(weekday: identity.weekdayTitle)
            badge = isNewBestToday ? VexloStrings.Overlay.bestToday : ""
            if isStrongCompletion {
                detail = VexloStrings.DailyRitual.closureDetail(characterName: identity.characterName)
                progress = isContinuityEligible ? identity.continuityLine(streakCount: streakCount) : ""
            } else {
                detail = VexloStrings.DailyRitual.modestFootholdDetail
                progress = score >= modestCompletionReplayLiftThreshold
                    ? VexloStrings.Overlay.oneCleanerBoardPressesBest
                    : VexloStrings.Overlay.dailyModestBoardStillHasMore
            }
        } else {
            caption = VexloStrings.DailyRitual.todayRecorded
            badge = ""
            detail = VexloStrings.Overlay.oneCleanerBoardGoesFarther
            progress = ""
        }

        return DailyRitualClosure(
            completionCaption: caption,
            closureDetail: detail,
            badge: badge,
            progress: progress,
            replayLabel: VexloStrings.Overlay.dailyReplayForBest
        )
    }
}
