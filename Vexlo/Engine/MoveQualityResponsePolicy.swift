import Foundation

/// Lifecycle moment for move-quality product response (Phase 2.5).
enum MoveQualityResponseMoment: Equatable {
    case drag
    case commit
    case postClear
    case runEnd
}

/// Inputs for move-quality response policy. Not `BoardPressure` tray-generation pressure.
struct MoveQualityResponseContext: Equatable {
    let moment: MoveQualityResponseMoment
    let tier: MoveQualityTier?
    let isOpeningState: Bool
    let clearedLineCount: Int
    let isLegalPlacement: Bool
}

/// Commit-time place haptic weight (Phase 1B). Visual clear feedback stays on DragPreviewProfile.
enum MoveQualityCommitHaptic: Equatable {
    case survival
    case relief
    case constructive
    case expert
}

/// Allowed product responses for one moment.
struct MoveQualityResponse: Equatable {
    let emphasizesOpeningReliefOnDrag: Bool
    let commitHaptic: MoveQualityCommitHaptic

    static let inactive = MoveQualityResponse(
        emphasizesOpeningReliefOnDrag: false,
        commitHaptic: .survival
    )
}

enum MoveQualityResponsePolicy {
    static func evaluate(_ context: MoveQualityResponseContext) -> MoveQualityResponse {
        switch context.moment {
        case .drag:
            return evaluateDrag(context)
        case .commit:
            return evaluateCommit(context)
        case .postClear, .runEnd:
            return .inactive
        }
    }

    private static func evaluateDrag(_ context: MoveQualityResponseContext) -> MoveQualityResponse {
        let emphasizesOpeningReliefOnDrag =
            context.isOpeningState &&
            context.isLegalPlacement &&
            context.clearedLineCount == 0 &&
            context.tier == .relief
        return MoveQualityResponse(
            emphasizesOpeningReliefOnDrag: emphasizesOpeningReliefOnDrag,
            commitHaptic: .survival
        )
    }

    private static func evaluateCommit(_ context: MoveQualityResponseContext) -> MoveQualityResponse {
        guard context.isLegalPlacement else { return .inactive }
        let commitHaptic: MoveQualityCommitHaptic
        if context.clearedLineCount >= 2 {
            commitHaptic = .expert
        } else if context.clearedLineCount == 1 {
            commitHaptic = .constructive
        } else {
            switch context.tier {
            case .relief:
                commitHaptic = .relief
            case .survival, .constructive, .expert, .none:
                commitHaptic = .survival
            }
        }
        return MoveQualityResponse(
            emphasizesOpeningReliefOnDrag: false,
            commitHaptic: commitHaptic
        )
    }
}
