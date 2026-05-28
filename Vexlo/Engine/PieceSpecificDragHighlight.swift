import Foundation

/// Cells that may change visually during drag — footprint, and post-threshold clear consequences.
enum PieceSpecificDragHighlight {
    static func coordinates(
        resolution: PlacementResolution,
        evaluation: PlacementEvaluation?,
        occupiedCoordinates: Set<HexCoordinate>,
        includesClearConsequences: Bool,
        includeBoardReliefContacts: Bool
    ) -> Set<HexCoordinate> {
        guard resolution.isLegal else { return [] }
        var result = Set(resolution.placedCoordinates)
        if includesClearConsequences {
            result.formUnion(resolution.clearedCellCoordinates)
        }
        guard includeBoardReliefContacts,
              let evaluation,
              evaluation.tier == .relief else { return result }
        result.formUnion(
            PlacementEvaluation.reliefContactCoordinates(
                placementCoordinates: resolution.placedCoordinates,
                occupiedCoordinates: occupiedCoordinates
            )
        )
        return result
    }
}
