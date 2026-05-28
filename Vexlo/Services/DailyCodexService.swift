import Foundation

/// Records and reads daily ritual codex memory (Daily Codex v1).
final class DailyCodexService {
    static let shared = DailyCodexService()

    private let persistence: DailyCodexPersistenceService
    private let masteryPersistence: MasteryRecognitionPersistenceService
    private let isCaptureModeProvider: () -> Bool

    private init() {
        persistence = .shared
        masteryPersistence = .shared
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
    }

    init(
        persistence: DailyCodexPersistenceService,
        masteryPersistence: MasteryRecognitionPersistenceService,
        isCaptureModeProvider: @escaping () -> Bool
    ) {
        self.persistence = persistence
        self.masteryPersistence = masteryPersistence
        self.isCaptureModeProvider = isCaptureModeProvider
    }

    func recordTerminalDaily(
        dayID: String,
        completion: DailyChallengeCompletion,
        didClearAny: Bool,
        residue: RunResidueRecord?
    ) {
        guard !isCaptureModeProvider() else { return }
        let mastery = masteryPersistence.load()?.recognizedCompetencies ?? []
        let entry = DailyCodexEntry.make(
            dayID: dayID,
            completion: completion,
            didClearAny: didClearAny,
            residue: residue,
            recognizedMastery: mastery
        )
        persistence.upsert(entry)
    }

    func utilityRitualBlock(recentLimit: Int = DailyCodexPersistenceService.defaultRecentLimit) -> String? {
        guard !isCaptureModeProvider() else { return nil }
        let entries = persistence.loadRecent(limit: recentLimit)
        guard !entries.isEmpty else { return nil }
        let lines = [VexloStrings.DailyCodex.ritualHeader] + entries.map { $0.utilityLine() }
        return lines.joined(separator: "\n")
    }
}
