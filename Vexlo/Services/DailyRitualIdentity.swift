import Foundation

/// Editorial daily identity derived from existing `dayID` / tone truth (Phase 3A).
/// Read-only presentation layer; does not mutate daily state or generation.
struct DailyRitualIdentity: Equatable {
    let dayID: String
    let weekdayTitle: String
    let tone: DailyToneVariant
    let characterName: String
    let ritualHeadline: String
    let resultDetailLine: String

    static func identity(for dayID: String) -> DailyRitualIdentity {
        identity(
            for: dayID,
            weekdayTitle: DailyChallengeService.shared.weekdayTitle(for: dayID),
            tone: DailyChallengeService.shared.toneVariant(for: dayID)
        )
    }

    static func identity(
        for dayID: String,
        weekdayTitle: String,
        tone: DailyToneVariant
    ) -> DailyRitualIdentity {
        let characterName = VexloStrings.DailyRitual.characterName(for: tone)
        return DailyRitualIdentity(
            dayID: dayID,
            weekdayTitle: weekdayTitle,
            tone: tone,
            characterName: characterName,
            ritualHeadline: VexloStrings.DailyRitual.ritualHeadline(
                weekday: weekdayTitle,
                characterName: characterName
            ),
            resultDetailLine: VexloStrings.DailyRitual.resultDetail(characterName: characterName)
        )
    }

    func continuityLine(streakCount: Int) -> String {
        VexloStrings.DailyRitual.continuity(days: streakCount)
    }

    var shareCardHeadline: String {
        ritualHeadline.uppercased(with: Locale.current)
    }
}
