import Foundation

/// Durable terminal trace for one completed run (Run Residue v1).
struct RunResidueRecord: Codable, Equatable {
    static let currentSchemaVersion = 1

    enum Mode: String, Codable {
        case normal
        case daily
    }

    enum LessonFlag: String, Codable {
        case laneOpening = "lane_opening"
        case anchorDiscipline = "anchor_discipline"
        case pressureRelease = "pressure_release"
        case chainConversion = "chain_conversion"
        case recoveryTiming = "recovery_timing"
        case noClear = "no_clear"
    }

    let schemaVersion: Int
    let timestamp: Date
    let mode: Mode
    let score: Int
    let didClearAny: Bool
    let maxCombo: Int
    let terminalPressureBand: String
    let readingDetailKey: String
    let lessonFlag: LessonFlag
    let dailyDayID: String?
    let dailyStreakCount: Int?

    static func makeNormal(context: RunReadingContext, timestamp: Date = Date()) -> RunResidueRecord {
        let readingDetailKey = RunReadingSummary.readingDetailKey(for: context)
        return RunResidueRecord(
            schemaVersion: currentSchemaVersion,
            timestamp: timestamp,
            mode: .normal,
            score: context.score,
            didClearAny: context.didClearAny,
            maxCombo: context.maxCombo,
            terminalPressureBand: context.terminalPressureBand.residueToken,
            readingDetailKey: readingDetailKey,
            lessonFlag: lessonFlag(
                readingDetailKey: readingDetailKey,
                didClearAny: context.didClearAny,
                hasUsedContinue: context.hasUsedContinue
            ),
            dailyDayID: nil,
            dailyStreakCount: nil
        )
    }

    static func makeDaily(
        dayID: String,
        completion: DailyChallengeCompletion?,
        didClearAny: Bool,
        score: Int,
        maxCombo: Int,
        terminalPressureBand: BoardPressureBand,
        timestamp: Date = Date()
    ) -> RunResidueRecord {
        let identity = DailyRitualIdentity.identity(for: dayID)
        let readingDetailKey = DailyRitualClosure.readingDetailKey(
            identity: identity,
            completion: completion,
            didClearAny: didClearAny
        )
        let streakCount = completion.map { max(0, $0.streakCount) }
        return RunResidueRecord(
            schemaVersion: currentSchemaVersion,
            timestamp: timestamp,
            mode: .daily,
            score: score,
            didClearAny: didClearAny,
            maxCombo: maxCombo,
            terminalPressureBand: terminalPressureBand.residueToken,
            readingDetailKey: readingDetailKey,
            lessonFlag: lessonFlag(
                readingDetailKey: readingDetailKey,
                didClearAny: didClearAny,
                hasUsedContinue: false
            ),
            dailyDayID: dayID,
            dailyStreakCount: streakCount
        )
    }

    func utilityResidueLine() -> String {
        switch mode {
        case .normal:
            return VexloStrings.RunResidue.lastRead(
                phrase: RunResidueDisplay.readingPhrase(for: readingDetailKey)
            )
        case .daily:
            let identity = dailyDayID.map { DailyRitualIdentity.identity(for: $0) }
            let weekday = identity?.weekdayTitle ?? ""
            let phrase = RunResidueDisplay.dailyPhrase(
                for: readingDetailKey,
                identity: identity
            )
            return VexloStrings.RunResidue.lastDaily(weekday: weekday, phrase: phrase)
        }
    }

    static func lessonFlag(
        readingDetailKey: String,
        didClearAny: Bool,
        hasUsedContinue: Bool
    ) -> LessonFlag {
        if !didClearAny || readingDetailKey == "no_clear_found" || readingDetailKey == "daily_no_clear" {
            return .noClear
        }
        if hasUsedContinue || readingDetailKey == "run_recovered_late" {
            return .recoveryTiming
        }
        switch readingDetailKey {
        case "read_under_pressure":
            return .pressureRelease
        case "chain_led_reading":
            return .chainConversion
        case "board_closed_early":
            return .laneOpening
        default:
            return .anchorDiscipline
        }
    }
}

enum RunResidueDisplay {
    static func dailyPhrase(for key: String, identity: DailyRitualIdentity?) -> String {
        if key == "daily_strong_completion", let identity {
            return "\(identity.characterName) board"
        }
        return readingPhrase(for: key)
    }

    static func readingPhrase(for key: String) -> String {
        switch key {
        case "your_best_run_yet":
            return VexloStrings.Overlay.yourBestRunYet
        case "run_recovered_late":
            return VexloStrings.Overlay.runRecoveredLate
        case "read_under_pressure":
            return VexloStrings.Overlay.readUnderPressure
        case "close_to_best":
            return VexloStrings.Overlay.closeToBest
        case "chain_led_reading":
            return VexloStrings.RunReading.chainLedReading
        case "board_closed_early":
            return VexloStrings.Overlay.boardClosedEarly
        case "clear_rhythm_held":
            return VexloStrings.Overlay.runSteadyClears
        case "no_clear_found":
            return VexloStrings.Overlay.runTightBoard
        case "daily_strong_completion":
            return VexloStrings.RunResidue.dailyStrongCompletion
        case "daily_modest_completion":
            return VexloStrings.RunResidue.dailyModestCompletion
        case "daily_weak_recorded":
            return VexloStrings.RunResidue.dailyWeakRecorded
        case "daily_no_clear":
            return VexloStrings.Overlay.runTightBoard
        default:
            return VexloStrings.RunResidue.dailyRecorded
        }
    }
}

private extension BoardPressureBand {
    var residueToken: String {
        switch self {
        case .calm:
            return "calm"
        case .attentive:
            return "attentive"
        case .taut:
            return "taut"
        }
    }
}
