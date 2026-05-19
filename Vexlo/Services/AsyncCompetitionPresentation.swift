import Foundation

/// Calm async competition copy for result-overlay Game Center CTAs (Competition 5A).
/// Read-only presentation; does not call Game Center or mutate run/daily state.
enum AsyncCompetitionGamesSlot: Equatable {
    case dailyTable
    case readingChallenge
    case shareRun
    case allTimeScores
}

struct AsyncCompetitionContext: Equatable {
    let isDaily: Bool
    let canPresentDailyActivity: Bool
    let canPresentScoreChallenge: Bool
    let score: Int
    let earnedBestThisRun: Bool
    let canPresentScoreChaseActivity: Bool
    let isAuthenticated: Bool
}

struct AsyncCompetitionPresentation: Equatable {
    let gamesLabel: String?
    let gamesSlot: AsyncCompetitionGamesSlot?

    static func resolve(context: AsyncCompetitionContext) -> AsyncCompetitionPresentation {
        let slot = gamesSlot(for: context)
        return AsyncCompetitionPresentation(
            gamesLabel: slot.map(label(for:)),
            gamesSlot: slot
        )
    }

    static func gamesSlot(for context: AsyncCompetitionContext) -> AsyncCompetitionGamesSlot? {
        if context.isDaily {
            return context.canPresentDailyActivity ? .dailyTable : nil
        }
        if context.canPresentScoreChallenge && context.score > 0 {
            return .readingChallenge
        }
        if context.earnedBestThisRun && context.canPresentScoreChaseActivity {
            return .shareRun
        }
        if context.isAuthenticated {
            return .allTimeScores
        }
        return nil
    }

    static func label(for slot: AsyncCompetitionGamesSlot) -> String {
        switch slot {
        case .dailyTable:
            return VexloStrings.AsyncCompetition.todaysTable
        case .readingChallenge:
            return VexloStrings.AsyncCompetition.sendReadingChallenge
        case .shareRun:
            return VexloStrings.AsyncCompetition.shareThisRun
        case .allTimeScores:
            return VexloStrings.AsyncCompetition.allTimeScores
        }
    }

    static func accessibilityLabel(for slot: AsyncCompetitionGamesSlot) -> String {
        switch slot {
        case .dailyTable:
            return VexloStrings.Accessibility.todaysTable
        case .readingChallenge:
            return VexloStrings.Accessibility.sendReadingChallenge
        case .shareRun:
            return VexloStrings.Accessibility.shareThisRun
        case .allTimeScores:
            return VexloStrings.Accessibility.allTimeScores
        }
    }

    static func accessibilityHint(for slot: AsyncCompetitionGamesSlot) -> String {
        switch slot {
        case .dailyTable:
            return VexloStrings.Accessibility.todaysTableHint
        case .readingChallenge:
            return VexloStrings.Accessibility.sendReadingChallengeHint
        case .shareRun:
            return VexloStrings.Accessibility.shareThisRunHint
        case .allTimeScores:
            return VexloStrings.Accessibility.allTimeScoresHint
        }
    }
}
