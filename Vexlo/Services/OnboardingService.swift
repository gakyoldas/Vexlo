import Foundation

final class OnboardingService {
    static let shared = OnboardingService()

    private enum Keys {
        static let placementLearned = "nf_vexlo_onboarding_placement_learned"
        static let clearLearned = "nf_vexlo_onboarding_clear_learned"
    }

    private let defaults: UserDefaults

    private init() {
        defaults = .standard
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var shouldShowPlacementHint: Bool {
        !defaults.bool(forKey: Keys.placementLearned)
    }

    var shouldShowClearHint: Bool {
        !defaults.bool(forKey: Keys.clearLearned)
    }

    func markPlacementLearned() {
        defaults.set(true, forKey: Keys.placementLearned)
    }

    func markClearLearned() {
        defaults.set(true, forKey: Keys.clearLearned)
    }
}
