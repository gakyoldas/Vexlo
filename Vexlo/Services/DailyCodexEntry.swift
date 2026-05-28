import Foundation

/// Ritual memory record for one daily board day (Daily Codex v1).
struct DailyCodexEntry: Codable, Equatable {
    static let currentSchemaVersion = 1

    enum CompletionTier: String, Codable {
        case zeroOrNoClear = "zero_or_no_clear"
        case weakRecorded = "weak_recorded"
        case modest = "modest"
        case strong = "strong"
    }

    let schemaVersion: Int
    let dayID: String
    let weekdayTitle: String
    let characterName: String
    let score: Int
    let lastAttemptScore: Int
    let readingDetailKey: String
    let completionTier: CompletionTier
    let isBestToday: Bool
    let streakCount: Int?
    let timestamp: Date
    let lessonFlag: String?
    let recognizedMastery: [String]?

    static func make(
        dayID: String,
        completion: DailyChallengeCompletion,
        didClearAny: Bool,
        residue: RunResidueRecord?,
        recognizedMastery: Set<MasteryCompetency>,
        timestamp: Date = Date()
    ) -> DailyCodexEntry {
        let identity = DailyRitualIdentity.identity(for: dayID)
        let readingDetailKey = DailyRitualClosure.readingDetailKey(
            identity: identity,
            completion: completion,
            didClearAny: didClearAny
        )
        let attemptScore = max(0, completion.score)
        let isBestToday = completion.isNewBestToday && attemptScore > 0
        return DailyCodexEntry(
            schemaVersion: currentSchemaVersion,
            dayID: dayID,
            weekdayTitle: identity.weekdayTitle,
            characterName: identity.characterName,
            score: max(0, completion.todayBest),
            lastAttemptScore: attemptScore,
            readingDetailKey: readingDetailKey,
            completionTier: completionTier(for: readingDetailKey),
            isBestToday: isBestToday,
            streakCount: max(0, completion.streakCount),
            timestamp: timestamp,
            lessonFlag: residue?.lessonFlag.rawValue,
            recognizedMastery: recognizedMastery.map(\.rawValue).sorted()
        )
    }

    static func completionTier(for readingDetailKey: String) -> CompletionTier {
        switch readingDetailKey {
        case "daily_no_clear":
            return .zeroOrNoClear
        case "daily_weak_recorded", "daily_recorded":
            return .weakRecorded
        case "daily_modest_completion":
            return .modest
        case "daily_strong_completion":
            return .strong
        default:
            return .weakRecorded
        }
    }

    func utilityLine() -> String {
        let phrase = RunResidueDisplay.dailyPhrase(
            for: readingDetailKey,
            identity: DailyRitualIdentity.identity(for: dayID)
        )
        var line = VexloStrings.DailyCodex.entryLine(
            weekday: weekdayTitle,
            phrase: phrase,
            score: score
        )
        if isBestToday {
            line += VexloStrings.DailyCodex.bestTodaySuffix
        }
        return line
    }
}
