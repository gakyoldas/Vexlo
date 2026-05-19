import Foundation

/// Single engine read for hypothetical placement outcome and move-quality evaluation.
struct PlacementPreview: Equatable {
    let resolution: PlacementResolution
    let evaluation: PlacementEvaluation?
}
