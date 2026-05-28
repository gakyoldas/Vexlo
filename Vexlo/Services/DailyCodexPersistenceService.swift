import Foundation

/// Local persistence for recent daily ritual codex entries (Daily Codex v1).
final class DailyCodexPersistenceService {
    static let shared = DailyCodexPersistenceService()
    static let maxEntryCount = 21
    static let defaultRecentLimit = 5

    private enum Keys {
        static let entries = "nf_vexlo_daily_codex_entries"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedData: Data?
    private let isCaptureModeProvider: () -> Bool
    private(set) var upsertInvocationCount = 0

    private init() {
        defaults = .standard
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
        cachedData = defaults.data(forKey: Keys.entries)
    }

    init(defaults: UserDefaults, isCaptureModeProvider: @escaping () -> Bool) {
        self.defaults = defaults
        self.isCaptureModeProvider = isCaptureModeProvider
        cachedData = defaults.data(forKey: Keys.entries)
    }

    func upsert(_ entry: DailyCodexEntry) {
        guard !isCaptureModeProvider() else { return }
        var entries = decodeEntries()
        if let index = entries.firstIndex(where: { $0.dayID == entry.dayID }) {
            entries.remove(at: index)
        }
        entries.insert(entry, at: 0)
        entries.sort { $0.dayID > $1.dayID }
        if entries.count > Self.maxEntryCount {
            entries = Array(entries.prefix(Self.maxEntryCount))
        }
        guard let data = try? encoder.encode(entries) else { return }
        upsertInvocationCount += 1
        defaults.set(data, forKey: Keys.entries)
        cachedData = data
    }

    func loadRecent(limit: Int = defaultRecentLimit) -> [DailyCodexEntry] {
        let entries = decodeEntries()
        guard limit > 0 else { return entries }
        return Array(entries.prefix(limit))
    }

    func loadEntry(dayID: String) -> DailyCodexEntry? {
        decodeEntries().first { $0.dayID == dayID }
    }

    func clear() {
        defaults.removeObject(forKey: Keys.entries)
        cachedData = nil
    }

    private func decodeEntries() -> [DailyCodexEntry] {
        guard let data = cachedData ?? defaults.data(forKey: Keys.entries) else { return [] }
        guard let entries = try? decoder.decode([DailyCodexEntry].self, from: data) else {
            clear()
            return []
        }
        cachedData = data
        return entries
            .filter { $0.schemaVersion <= DailyCodexEntry.currentSchemaVersion }
            .sorted { $0.dayID > $1.dayID }
    }
}
