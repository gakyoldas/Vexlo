import Foundation

struct PlacementEvaluationContext: Equatable {
    let occupiedCellCount: Int
    let isOpeningState: Bool
}

/// Quality read derived from a hypothetical placement on the current board.
struct PlacementEvaluation: Equatable {
    let resolution: PlacementResolution
    let tier: MoveQualityTier
    let reliefContactCount: Int
    let occupiedCellCountBeforePlacement: Int

    static let reliefContactThreshold = 2
    /// Descriptive proxy for elevated board pressure; survival tier is provisional in Phase 1.
    static let survivalOccupancyThreshold = 14

    /// Returns `nil` when `resolution.isLegal` is false.
    static func evaluate(
        resolution: PlacementResolution,
        context: PlacementEvaluationContext,
        occupiedCoordinates: Set<HexCoordinate>
    ) -> PlacementEvaluation? {
        guard resolution.isLegal else { return nil }

        let reliefContactCount = reliefContactCount(
            placementCoordinates: resolution.placedCoordinates,
            occupiedCoordinates: occupiedCoordinates
        )
        let tier = tier(resolution: resolution, reliefContactCount: reliefContactCount)

        return PlacementEvaluation(
            resolution: resolution,
            tier: tier,
            reliefContactCount: reliefContactCount,
            occupiedCellCountBeforePlacement: context.occupiedCellCount
        )
    }

    static func reliefContactCount(
        placementCoordinates: [HexCoordinate],
        occupiedCoordinates: Set<HexCoordinate>
    ) -> Int {
        Set(
            placementCoordinates.flatMap { coordinate in
                axialNeighborCoordinates(for: coordinate)
                    .filter(occupiedCoordinates.contains)
            }
        ).count
    }

    private static func tier(
        resolution: PlacementResolution,
        reliefContactCount: Int
    ) -> MoveQualityTier {
        if resolution.clearedLineCount >= 2 {
            return .expert
        }
        if resolution.clearedLineCount == 1 {
            return .constructive
        }
        if reliefContactCount >= reliefContactThreshold {
            return .relief
        }
        return .survival
    }

    private static func axialNeighborCoordinates(for coordinate: HexCoordinate) -> [HexCoordinate] {
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
