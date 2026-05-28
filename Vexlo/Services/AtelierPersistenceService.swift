import Foundation

/// Local persistence for Atelier cosmetic ownership and per-category selection (v1 foundation).
final class AtelierPersistenceService {
    static let shared = AtelierPersistenceService()

    private enum Keys {
        static let grantedOwnedIDs = "nf_vexlo_atelier_granted_owned"
        static let selections = "nf_vexlo_atelier_selections"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let isCaptureModeProvider: () -> Bool

    private init() {
        defaults = .standard
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
    }

    init(defaults: UserDefaults, isCaptureModeProvider: @escaping () -> Bool = { false }) {
        self.defaults = defaults
        self.isCaptureModeProvider = isCaptureModeProvider
    }

    func loadGrantedOwnedIDs() -> Set<String> {
        guard let data = defaults.data(forKey: Keys.grantedOwnedIDs),
              let ids = try? decoder.decode([String].self, from: data) else {
            return []
        }
        return Set(ids.filter { AtelierCatalog.isKnown(id: $0) })
    }

    func saveGrantedOwnedIDs(_ ids: Set<String>) {
        guard !isCaptureModeProvider() else { return }
        let known = ids.filter { AtelierCatalog.isKnown(id: $0) }
        guard let data = try? encoder.encode(Array(known).sorted()) else { return }
        defaults.set(data, forKey: Keys.grantedOwnedIDs)
    }

    func grant(cosmeticID: AtelierCosmeticID) {
        guard AtelierCatalog.cosmetic(id: cosmeticID) != nil else { return }
        var granted = loadGrantedOwnedIDs()
        granted.insert(cosmeticID.rawValue)
        saveGrantedOwnedIDs(granted)
    }

    func loadPersistedSelection(for category: AtelierCosmeticCategory) -> AtelierCosmeticID? {
        guard let raw = loadPersistedSelectionRaw()[category.rawValue],
              let id = AtelierCosmeticID(rawValue: raw) else {
            return nil
        }
        return id
    }

    func saveSelected(cosmeticID: AtelierCosmeticID, for category: AtelierCosmeticCategory) {
        guard !isCaptureModeProvider(),
              let cosmetic = AtelierCatalog.cosmetic(id: cosmeticID),
              cosmetic.category == category,
              effectiveOwnedIDs().contains(cosmeticID.rawValue) else {
            if let fallback = AtelierCatalog.defaultCosmeticID(for: category) {
                persistSelection(fallback, for: category)
            }
            return
        }
        persistSelection(cosmeticID, for: category)
    }

    func resolvedSelection(for category: AtelierCosmeticCategory) -> AtelierCosmeticID {
        let owned = effectiveOwnedIDs()
        if let persisted = loadPersistedSelection(for: category),
           owned.contains(persisted.rawValue) {
            return persisted
        }
        return AtelierCatalog.defaultCosmeticID(for: category) ?? .boardFrameDefault
    }

    func inventorySnapshot() -> AtelierInventorySnapshot {
        AtelierInventorySnapshot(ownedIDs: effectiveOwnedIDs())
    }

    func selectionSnapshot() -> AtelierSelectionSnapshot {
        var selections: [AtelierCosmeticCategory: AtelierCosmeticID] = [:]
        for category in AtelierCosmeticCategory.allCases {
            selections[category] = resolvedSelection(for: category)
        }
        return AtelierSelectionSnapshot(selections: selections)
    }

    func clearForTesting() {
        defaults.removeObject(forKey: Keys.grantedOwnedIDs)
        defaults.removeObject(forKey: Keys.selections)
    }

    private func effectiveOwnedIDs() -> Set<String> {
        loadGrantedOwnedIDs().union(AtelierCatalog.defaultFreeOwnedIDs)
    }

    private func loadPersistedSelectionRaw() -> [String: String] {
        guard let data = defaults.data(forKey: Keys.selections),
              let map = try? decoder.decode([String: String].self, from: data) else {
            return [:]
        }
        return map
    }

    private func persistSelection(_ cosmeticID: AtelierCosmeticID, for category: AtelierCosmeticCategory) {
        var map = loadPersistedSelectionRaw()
        map[category.rawValue] = cosmeticID.rawValue
        guard let data = try? encoder.encode(map) else { return }
        defaults.set(data, forKey: Keys.selections)
    }
}
