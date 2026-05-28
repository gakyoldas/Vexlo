import Foundation

/// Read-only entitlement kinds for monetization spine v1. Live ownership sources stay in product services.
enum EntitlementKind: Equatable, Hashable {
    case supporter
    case noAds
    case allAccess
    case founder
    case atelierCosmetic(String)
}

/// Stable StoreKit product identifiers — live and reserved.
enum EntitlementProductID {
    static let supporterPack = SupporterPackService.ProductID.supporterPack

    // Reserved for future product decisions — not loaded by StoreKit today.
    static let noAdsReserved = "com.northfall.vexlo.noads"
    static let allAccessReserved = "com.northfall.vexlo.allaccess"
    static let founderReserved = "com.northfall.vexlo.founder"
    static let atelierNamespaceReserved = "com.northfall.vexlo.atelier"
}

/// Immutable entitlement read model composed from live services. No persistence or purchase logic.
struct EntitlementSnapshot: Equatable {
    let supporterOwned: Bool
    let noAdsOwned: Bool
    let allAccessOwned: Bool
    let founderOwned: Bool
    let ownedCosmeticIDs: Set<String>

    static let none = EntitlementSnapshot(
        supporterOwned: false,
        noAdsOwned: false,
        allAccessOwned: false,
        founderOwned: false,
        ownedCosmeticIDs: []
    )

    /// True when rewarded continue/reroll may be satisfied without showing a rewarded ad.
    var removesRewardedAdRequirement: Bool {
        supporterOwned || noAdsOwned || allAccessOwned
    }

    var hasAllAccess: Bool {
        allAccessOwned
    }

    func ownsCosmetic(id: String) -> Bool {
        allAccessOwned || ownedCosmeticIDs.contains(id)
    }

    func hasEntitlement(_ kind: EntitlementKind) -> Bool {
        switch kind {
        case .supporter:
            supporterOwned
        case .noAds:
            noAdsOwned
        case .allAccess:
            allAccessOwned
        case .founder:
            founderOwned
        case .atelierCosmetic(let id):
            ownsCosmetic(id: id)
        }
    }
}

/// Composes entitlement snapshots from live ownership sources without replacing product services.
enum EntitlementCatalog {
    /// `grantedAtelierCosmeticIDs` — persisted or commerce-granted IDs (`AtelierCosmeticID.rawValue`); not catalog defaults.
    static func liveSnapshot(
        supporterOwned: Bool,
        grantedAtelierCosmeticIDs: Set<String> = []
    ) -> EntitlementSnapshot {
        EntitlementSnapshot(
            supporterOwned: supporterOwned,
            noAdsOwned: false,
            allAccessOwned: false,
            founderOwned: false,
            ownedCosmeticIDs: grantedAtelierCosmeticIDs
        )
    }
}
