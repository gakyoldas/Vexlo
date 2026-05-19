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
        completion: DailyChallengeCompletion?
    ) -> DailyRitualClosure {
        let streakCount = max(0, completion?.streakCount ?? 0)
        let isNewBestToday = completion?.isNewBestToday == true
        return DailyRitualClosure(
            completionCaption: VexloStrings.DailyRitual.completionCaption(weekday: identity.weekdayTitle),
            closureDetail: VexloStrings.DailyRitual.closureDetail(characterName: identity.characterName),
            badge: isNewBestToday
                ? VexloStrings.Overlay.bestToday
                : VexloStrings.DailyRitual.todayRecorded,
            progress: streakCount > 0 ? identity.continuityLine(streakCount: streakCount) : "",
            replayLabel: VexloStrings.Overlay.dailyReplayForBest
        )
    }
}
