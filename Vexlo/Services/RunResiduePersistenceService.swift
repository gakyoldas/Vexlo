import Foundation

/// Local persistence for the latest completed-run residue (Run Residue v1).
final class RunResiduePersistenceService {
    static let shared = RunResiduePersistenceService()

    static let maxHistoryCount = 32

    private enum Keys {
        static let lastRecord = "nf_vexlo_run_residue_last"
        static let history = "nf_vexlo_run_residue_history"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedData: Data?
    private var cachedHistoryData: Data?
    private let isCaptureModeProvider: () -> Bool
    private(set) var saveInvocationCount = 0

    private init() {
        defaults = .standard
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
        cachedData = defaults.data(forKey: Keys.lastRecord)
        cachedHistoryData = defaults.data(forKey: Keys.history)
    }

    init(defaults: UserDefaults, isCaptureModeProvider: @escaping () -> Bool) {
        self.defaults = defaults
        self.isCaptureModeProvider = isCaptureModeProvider
        cachedData = defaults.data(forKey: Keys.lastRecord)
        cachedHistoryData = defaults.data(forKey: Keys.history)
    }

    func save(_ record: RunResidueRecord) {
        guard !isCaptureModeProvider(),
              let data = try? encoder.encode(record) else { return }
        saveInvocationCount += 1
        defaults.set(data, forKey: Keys.lastRecord)
        cachedData = data
        appendToHistory(record)
    }

    func loadHistory(limit: Int? = nil) -> [RunResidueRecord] {
        let history = decodeHistory()
        guard let limit, limit > 0 else { return history }
        return Array(history.prefix(limit))
    }

    func loadLast() -> RunResidueRecord? {
        guard let data = cachedData ?? defaults.data(forKey: Keys.lastRecord) else { return nil }
        guard let record = try? decoder.decode(RunResidueRecord.self, from: data) else {
            clear()
            return nil
        }
        guard record.schemaVersion <= RunResidueRecord.currentSchemaVersion else {
            return nil
        }
        cachedData = data
        return record
    }

    func clear() {
        defaults.removeObject(forKey: Keys.lastRecord)
        defaults.removeObject(forKey: Keys.history)
        cachedData = nil
        cachedHistoryData = nil
    }

    private func appendToHistory(_ record: RunResidueRecord) {
        var history = decodeHistory()
        history.insert(record, at: 0)
        if history.count > Self.maxHistoryCount {
            history.removeLast(history.count - Self.maxHistoryCount)
        }
        guard let data = try? encoder.encode(history) else { return }
        defaults.set(data, forKey: Keys.history)
        cachedHistoryData = data
    }

    private func decodeHistory() -> [RunResidueRecord] {
        guard let data = cachedHistoryData ?? defaults.data(forKey: Keys.history) else { return [] }
        guard let history = try? decoder.decode([RunResidueRecord].self, from: data) else {
            defaults.removeObject(forKey: Keys.history)
            cachedHistoryData = nil
            return []
        }
        cachedHistoryData = data
        return history.filter { $0.schemaVersion <= RunResidueRecord.currentSchemaVersion }
    }
}
