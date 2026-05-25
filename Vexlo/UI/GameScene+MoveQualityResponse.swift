import Foundation

extension GameScene {
    static func moveQualityDragResponse(
        evaluation: PlacementEvaluation?,
        isOpeningState: Bool
    ) -> MoveQualityResponse {
        guard let evaluation else {
            return .inactive
        }
        let context = MoveQualityResponseContext(
            moment: .drag,
            tier: evaluation.tier,
            isOpeningState: isOpeningState,
            clearedLineCount: evaluation.resolution.clearedLineCount,
            isLegalPlacement: evaluation.resolution.isLegal
        )
        return MoveQualityResponsePolicy.evaluate(context)
    }

    static func moveQualityCommitResponse(
        for committed: PlacementResolution,
        tier: MoveQualityTier?
    ) -> MoveQualityResponse {
        let context = MoveQualityResponseContext(
            moment: .commit,
            tier: tier,
            isOpeningState: false,
            clearedLineCount: committed.clearedLineCount,
            isLegalPlacement: committed.isLegal
        )
        return MoveQualityResponsePolicy.evaluate(context)
    }

    static func playCommitPlaceHaptic(_ commitHaptic: MoveQualityCommitHaptic) {
        HapticsService.shared.playPlace(commitHaptic: commitHaptic)
    }
}
