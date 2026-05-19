import Foundation

/// Engine-owned move-quality classification for a single placement (Phase 1).
/// Derived from `PlacementResolution`; not stored on the resolution value.
enum MoveQualityTier: Equatable, CaseIterable {
    /// Legal placement with little immediate board help; provisional occupancy proxy in Phase 1.
    case survival
    /// Legal placement that eases tension via meaningful contact without clearing.
    case relief
    /// Legal placement that completes at least one line.
    case constructive
    /// Legal placement that clears multiple lines at once.
    case expert
}
