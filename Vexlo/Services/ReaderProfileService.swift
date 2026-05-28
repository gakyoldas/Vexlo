import Foundation

/// Reads retention spine data and exposes editorial reader profile synthesis (Reader Profile v1).
final class ReaderProfileService {
    static let shared = ReaderProfileService()

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

    func currentProfile() -> ReaderProfile? {
        guard !isCaptureModeProvider() else { return nil }
        let residues = residuePersistence.loadHistory(limit: ReaderProfileEvaluator.profileWindow)
        let mastery = masteryPersistence.load()?.recognizedCompetencies ?? []
        return ReaderProfileEvaluator.synthesize(
            input: .init(
                recentResidues: residues,
                recognizedMastery: mastery
            )
        )
    }

    func utilityProfileBlock() -> String? {
        currentProfile()?.utilityBlock()
    }
}
