import Foundation

final class LiveRunPersistenceService {
    static let shared = LiveRunPersistenceService()

    private enum Keys {
        static let snapshot = "nf_vexlo_live_run_snapshot"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedData: Data?
    private let isCaptureModeProvider: () -> Bool

    private init() {
        defaults = .standard
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
        cachedData = defaults.data(forKey: Keys.snapshot)
    }

    init(defaults: UserDefaults, isCaptureModeProvider: @escaping () -> Bool) {
        self.defaults = defaults
        self.isCaptureModeProvider = isCaptureModeProvider
        cachedData = defaults.data(forKey: Keys.snapshot)
    }

    var hasPersistedRun: Bool {
        cachedData != nil
    }

    func save(_ snapshot: GameEngine.LiveRunSnapshot) {
        guard !isCaptureModeProvider(),
              let data = try? encoder.encode(snapshot) else { return }
        guard data != cachedData else { return }
        defaults.set(data, forKey: Keys.snapshot)
        cachedData = data
        WidgetSurfaceService.shared.publishLiveRun(snapshot)
    }

    func load() -> GameEngine.LiveRunSnapshot? {
        guard let data = cachedData ?? defaults.data(forKey: Keys.snapshot) else { return nil }
        guard let snapshot = try? decoder.decode(GameEngine.LiveRunSnapshot.self, from: data) else {
            clear()
            return nil
        }
        cachedData = data
        return snapshot
    }

    func clear() {
        defaults.removeObject(forKey: Keys.snapshot)
        cachedData = nil
        WidgetSurfaceService.shared.clearResumableRun()
    }
}
