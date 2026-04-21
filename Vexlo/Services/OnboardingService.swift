import Foundation

final class OnboardingService {
    static let shared = OnboardingService()

    private enum Keys {
        static let placementLearned = ICloudProgressSyncService.Keys.onboardingPlacementLearned
        static let clearLearned = ICloudProgressSyncService.Keys.onboardingClearLearned
    }

    private let defaults: UserDefaults
    private let syncService: ICloudProgressSyncService?

    private init() {
        defaults = .standard
        syncService = .shared
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        syncService = nil
    }

    var shouldShowPlacementHint: Bool {
        !defaults.bool(forKey: Keys.placementLearned)
    }

    var shouldShowClearHint: Bool {
        !defaults.bool(forKey: Keys.clearLearned)
    }

    func markPlacementLearned() {
        defaults.set(true, forKey: Keys.placementLearned)
        syncService?.publishLearnedFlag(key: Keys.placementLearned)
    }

    func markClearLearned() {
        defaults.set(true, forKey: Keys.clearLearned)
        syncService?.publishLearnedFlag(key: Keys.clearLearned)
    }
}
