import Foundation

/// Refreshes behavioral mastery recognition after terminal residue is saved (Mastery v1).
final class MasteryRecognitionService {
    static let shared = MasteryRecognitionService()

    private let residuePersistence: RunResiduePersistenceService
    private let masteryPersistence: MasteryRecognitionPersistenceService
    private let isCaptureModeProvider: () -> Bool

    private init() {
        residuePersistence = .shared
        masteryPersistence = .shared
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
    }

    init(
        residuePersistence: RunResiduePersistenceService,
        masteryPersistence: MasteryRecognitionPersistenceService,
        isCaptureModeProvider: @escaping () -> Bool
    ) {
        self.residuePersistence = residuePersistence
        self.masteryPersistence = masteryPersistence
        self.isCaptureModeProvider = isCaptureModeProvider
    }

    func refreshAfterTerminalResidue() {
        guard !isCaptureModeProvider() else { return }
        let history = residuePersistence.loadHistory()
        let existing = masteryPersistence.load()?.recognizedCompetencies ?? []
        let recognized = MasteryRecognitionEvaluator.recognizedCompetencies(
            history: history,
            alreadyRecognized: existing
        )
        guard recognized != existing else { return }
        masteryPersistence.save(MasteryRecognitionState(
            schemaVersion: MasteryRecognitionState.currentSchemaVersion,
            recognized: recognized
        ))
    }

    func utilityMasteryLine() -> String? {
        guard !isCaptureModeProvider() else { return nil }
        return masteryPersistence.load()?.utilityLine()
    }
}
