import Foundation

extension GameScene {
    enum DragPreviewProfile: Equatable {
        case invalidPlacement
        case validPlacement
        case clearPlacement
        case multiClearPlacement
    }

    static func dragPreviewProfile(isValid: Bool, clearedLineCount: Int) -> DragPreviewProfile {
        guard isValid else { return .invalidPlacement }
        if clearedLineCount > 1 {
            return .multiClearPlacement
        }
        if clearedLineCount == 1 {
            return .clearPlacement
        }
        return .validPlacement
    }

    static func dragPreviewProfile(for resolution: PlacementResolution) -> DragPreviewProfile {
        dragPreviewProfile(isValid: resolution.isLegal, clearedLineCount: resolution.clearedLineCount)
    }

    static func shouldEmphasizeOpeningReliefPlacement(
        evaluation: PlacementEvaluation?,
        previewProfile: DragPreviewProfile,
        isOpeningState: Bool
    ) -> Bool {
        guard isOpeningState,
              previewProfile == .validPlacement,
              let evaluation,
              evaluation.tier == .relief else { return false }
        return true
    }
}
