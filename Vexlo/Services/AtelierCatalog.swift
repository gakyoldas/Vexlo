import Foundation

/// Stable cosmetic identifiers for Atelier catalog v1. Raw values are persisted and entitlement-compatible.
enum AtelierCosmeticID: String, Codable, CaseIterable, Equatable, Hashable {
    case boardFrameDefault = "vexlo.atelier.boardFrame.default"
    case boardFrameArchive = "vexlo.atelier.boardFrame.archive"
    case piecePaletteDefault = "vexlo.atelier.piecePalette.default"
    case hudAccentDefault = "vexlo.atelier.hudAccent.default"
    case shareFinishDefault = "vexlo.atelier.shareFinish.default"
    case trayMarkDefault = "vexlo.atelier.trayMark.default"
}

/// Catalog entry for a presentation-only cosmetic. No assets, StoreKit, or gameplay coupling.
struct AtelierCosmetic: Equatable {
    let id: AtelierCosmeticID
    /// Uses `AtelierCosmeticCategory` from ethical monetization policy — do not fork category names.
    let category: AtelierCosmeticCategory
    let isDefaultForCategory: Bool
    let isFreeByDefault: Bool
}

/// Effective owned cosmetic IDs (defaults + persisted grants).
struct AtelierInventorySnapshot: Equatable {
    let ownedIDs: Set<String>
}

/// Resolved selected cosmetic ID per category (always owned and catalog-known).
struct AtelierSelectionSnapshot: Equatable {
    let selections: [AtelierCosmeticCategory: AtelierCosmeticID]
}

/// Read-only seed catalog for Atelier persistence v1.
enum AtelierCatalog {
    static let allCosmetics: [AtelierCosmetic] = [
        AtelierCosmetic(
            id: .boardFrameDefault,
            category: .boardFrameFinish,
            isDefaultForCategory: true,
            isFreeByDefault: true
        ),
        AtelierCosmetic(
            id: .boardFrameArchive,
            category: .boardFrameFinish,
            isDefaultForCategory: false,
            isFreeByDefault: false
        ),
        AtelierCosmetic(
            id: .piecePaletteDefault,
            category: .pieceMineralPalette,
            isDefaultForCategory: true,
            isFreeByDefault: true
        ),
        AtelierCosmetic(
            id: .hudAccentDefault,
            category: .hudAccentTone,
            isDefaultForCategory: true,
            isFreeByDefault: true
        ),
        AtelierCosmetic(
            id: .shareFinishDefault,
            category: .shareCardFinish,
            isDefaultForCategory: true,
            isFreeByDefault: true
        ),
        AtelierCosmetic(
            id: .trayMarkDefault,
            category: .trayRestMarkFinish,
            isDefaultForCategory: true,
            isFreeByDefault: true
        )
    ]

    static let defaultFreeOwnedIDs: Set<String> = Set(
        allCosmetics.filter(\.isFreeByDefault).map { $0.id.rawValue }
    )

    static func cosmetic(id: AtelierCosmeticID) -> AtelierCosmetic? {
        allCosmetics.first { $0.id == id }
    }

    static func cosmetic(rawID: String) -> AtelierCosmetic? {
        guard let id = AtelierCosmeticID(rawValue: rawID) else { return nil }
        return cosmetic(id: id)
    }

    static func isKnown(id: String) -> Bool {
        cosmetic(rawID: id) != nil
    }

    static func defaultCosmetic(for category: AtelierCosmeticCategory) -> AtelierCosmetic? {
        allCosmetics.first { $0.category == category && $0.isDefaultForCategory }
    }

    static func defaultCosmeticID(for category: AtelierCosmeticCategory) -> AtelierCosmeticID? {
        defaultCosmetic(for: category)?.id
    }

    static func cosmetics(in category: AtelierCosmeticCategory) -> [AtelierCosmetic] {
        allCosmetics.filter { $0.category == category }
    }
}
