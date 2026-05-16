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

    static func shouldEmphasizeOpeningReliefPlacement(
        isOpeningState: Bool,
        previewProfile: DragPreviewProfile,
        placementCoordinates: [HexCoordinate],
        occupiedCoordinates: Set<HexCoordinate>
    ) -> Bool {
        guard isOpeningState, previewProfile == .validPlacement else { return false }
        return openingReliefContactScore(
            placementCoordinates: placementCoordinates,
            occupiedCoordinates: occupiedCoordinates
        ) >= 2
    }

    static func openingReliefContactScore(
        placementCoordinates: [HexCoordinate],
        occupiedCoordinates: Set<HexCoordinate>
    ) -> Int {
        Set(
            placementCoordinates.flatMap { coordinate in
                openingNeighborCoordinates(for: coordinate)
                    .filter(occupiedCoordinates.contains)
            }
        ).count
    }

    private static func openingNeighborCoordinates(for coordinate: HexCoordinate) -> [HexCoordinate] {
        [
            HexCoordinate(1, 0),
            HexCoordinate(1, -1),
            HexCoordinate(0, -1),
            HexCoordinate(-1, 0),
            HexCoordinate(-1, 1),
            HexCoordinate(0, 1)
        ].map { HexGeometry.coordinate(for: $0, anchoredAt: coordinate) }
    }
}
