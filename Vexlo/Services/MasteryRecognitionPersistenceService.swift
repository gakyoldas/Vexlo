import Foundation

final class MasteryRecognitionPersistenceService {
    static let shared = MasteryRecognitionPersistenceService()

    private enum Keys {
        static let state = "nf_vexlo_mastery_recognition"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var cachedData: Data?
    private let isCaptureModeProvider: () -> Bool

    private init() {
        defaults = .standard
        isCaptureModeProvider = { LaunchSupport.shared.isCaptureMode }
        cachedData = defaults.data(forKey: Keys.state)
    }

    init(defaults: UserDefaults, isCaptureModeProvider: @escaping () -> Bool) {
        self.defaults = defaults
        self.isCaptureModeProvider = isCaptureModeProvider
        cachedData = defaults.data(forKey: Keys.state)
    }

    func save(_ state: MasteryRecognitionState) {
        guard !isCaptureModeProvider(),
              let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: Keys.state)
        cachedData = data
    }

    func load() -> MasteryRecognitionState? {
        guard let data = cachedData ?? defaults.data(forKey: Keys.state) else { return nil }
        guard let state = try? decoder.decode(MasteryRecognitionState.self, from: data) else {
            clear()
            return nil
        }
        guard state.schemaVersion <= MasteryRecognitionState.currentSchemaVersion else {
            return nil
        }
        cachedData = data
        return state
    }

    func clear() {
        defaults.removeObject(forKey: Keys.state)
        cachedData = nil
    }
}
