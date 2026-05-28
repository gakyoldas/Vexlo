import Foundation
import UIKit

/// Product policy for line-clear preview and commit choreography.
enum ClearConsequenceSurface {
    /// Already-placed neighbor cells must not react during drag; relief reads on footprint only.
    static let includesBoardReliefContactsInDragHighlight = false

    struct CommitAnimationTiming: Equatable {
        let stagger: TimeInterval
        let brighten: TimeInterval
        let dwell: TimeInterval
        let dissolve: TimeInterval
        let completionPadding: TimeInterval

        func totalDuration(cellCount: Int) -> TimeInterval {
            guard cellCount > 0 else { return 0 }
            let lastIndex = max(0, cellCount - 1)
            return TimeInterval(lastIndex) * stagger + brighten + dwell + dissolve + completionPadding
        }
    }

    static func commitAnimationTiming(prefersReducedMotion: Bool) -> CommitAnimationTiming {
        guard !prefersReducedMotion else {
            return CommitAnimationTiming(
                stagger: 0,
                brighten: 0,
                dwell: 0,
                dissolve: 0,
                completionPadding: 0
            )
        }
        return CommitAnimationTiming(
            stagger: 0.032,
            brighten: 0.14,
            dwell: 0.14,
            dissolve: 0.30,
            completionPadding: 0.09
        )
    }

    /// Footprint cells on a clear-legal drag never borrow clear-lane mint; they stay survival/relief only.
    static func footprintDragProfile(
        resolutionProfile: GameScene.DragPreviewProfile,
        evaluationTier: MoveQualityTier?,
        showsClearConsequence: Bool
    ) -> GameScene.DragPreviewProfile {
        guard showsClearConsequence else { return resolutionProfile }
        switch resolutionProfile {
        case .clearPlacement, .multiClearPlacement:
            if evaluationTier == .relief {
                return .reliefPlacement
            }
            return .survivalPlacement
        default:
            return resolutionProfile
        }
    }

    static func clearedCellJewelColors(
        clearedCoordinates: [HexCoordinate],
        placedCoordinates: [HexCoordinate],
        pieceColor: UIColor,
        boardColorAt: (HexCoordinate) -> UIColor?
    ) -> [HexCoordinate: UIColor] {
        let placed = Set(placedCoordinates)
        var colors: [HexCoordinate: UIColor] = [:]
        for coord in clearedCoordinates {
            if let board = boardColorAt(coord) {
                colors[coord] = board
            } else if placed.contains(coord) {
                colors[coord] = pieceColor
            }
        }
        return colors
    }

    static func previewEmptyFill(accent: UIColor?, multiClear: Bool) -> UIColor {
        if let accent {
            return accent.withAlphaComponent(multiClear ? 0.42 : 0.38)
        }
        return UIColor(hex: multiClear ? "B8EBDD" : "8FD4C4").withAlphaComponent(multiClear ? 0.46 : 0.42)
    }

    static func previewEmptyStroke(multiClear: Bool) -> UIColor {
        UIColor.white.withAlphaComponent(multiClear ? 0.58 : 0.52)
    }

    static func previewEmptyGlint(multiClear: Bool) -> UIColor {
        UIColor.white.withAlphaComponent(multiClear ? 0.18 : 0.15)
    }

    static func jewelCommitFill(_ color: UIColor) -> UIColor {
        color.withAlphaComponent(1.0)
    }

    static func jewelCommitStroke(_ color: UIColor, multiClear: Bool) -> UIColor {
        color.withAlphaComponent(multiClear ? 0.34 : 0.30)
    }

    static func jewelCommitGlint(_ color: UIColor, multiClear: Bool) -> UIColor {
        color.lighter(by: 0.24).withAlphaComponent(multiClear ? 0.44 : 0.38)
    }

    static func emptyDissolveMineral() -> UIColor {
        UIColor(hex: "9BB5C8")
    }
}

private extension UIColor {
    func lighter(by amount: CGFloat) -> UIColor {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }
        return UIColor(
            red: min(red + amount, 1),
            green: min(green + amount, 1),
            blue: min(blue + amount, 1),
            alpha: alpha
        )
    }
}
