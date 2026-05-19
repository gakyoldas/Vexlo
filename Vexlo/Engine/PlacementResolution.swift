import Foundation

/// Engine-owned outcome for a single piece placement at an anchor.
/// Phase 0: line-clear prediction only. Phase 1 may derive `MoveQualityTier` from this value.
struct PlacementResolution: Equatable {
    let anchor: HexCoordinate
    let placedCoordinates: [HexCoordinate]
    let isLegal: Bool
    let clearedRowIndices: [Int]
    let clearedColIndices: [Int]
    let clearedCellCoordinates: [HexCoordinate]

    var clearedLineCount: Int {
        clearedRowIndices.count + clearedColIndices.count
    }

    var clearsAnything: Bool {
        !clearedCellCoordinates.isEmpty
    }
}
