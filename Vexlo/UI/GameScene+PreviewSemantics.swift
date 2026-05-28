import Foundation

extension GameScene {
    enum DragPreviewProfile: Equatable {
        case invalidPlacement
        case survivalPlacement
        case reliefPlacement
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
        return .survivalPlacement
    }

    static func dragPreviewProfile(
        resolution: PlacementResolution,
        evaluation: PlacementEvaluation?
    ) -> DragPreviewProfile {
        guard resolution.isLegal else { return .invalidPlacement }
        guard let evaluation else {
            return dragPreviewProfile(
                isValid: true,
                clearedLineCount: resolution.clearedLineCount
            )
        }
        switch evaluation.tier {
        case .expert:
            return .multiClearPlacement
        case .constructive:
            return .clearPlacement
        case .relief:
            return .reliefPlacement
        case .survival:
            return .survivalPlacement
        }
    }

    static func dragPreviewProfile(for resolution: PlacementResolution) -> DragPreviewProfile {
        dragPreviewProfile(resolution: resolution, evaluation: nil)
    }

    static func shouldEmphasizeOpeningReliefPlacement(
        previewProfile: DragPreviewProfile,
        isOpeningState: Bool
    ) -> Bool {
        isOpeningState && previewProfile == .reliefPlacement
    }
}
