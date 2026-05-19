import Foundation

/// Tracks whether today's daily arrival beat was shown (Phase 3B).
/// Presentation-only marker; does not affect daily generation, streak, or gameplay.
final class DailyArrivalRitualService {
    static let shared = DailyArrivalRitualService()

    private enum Keys {
        static let arrivalPresentedDayID = "nf_vexlo_daily_arrival_presented_day_id"
    }

    private let defaults: UserDefaults

    private init() {
        defaults = .standard
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func shouldPresentArrival(for dayID: String) -> Bool {
        defaults.string(forKey: Keys.arrivalPresentedDayID) != dayID
    }

    func markArrivalPresented(for dayID: String) {
        defaults.set(dayID, forKey: Keys.arrivalPresentedDayID)
    }

    func presentedArrivalDayID() -> String? {
        defaults.string(forKey: Keys.arrivalPresentedDayID)
    }
}
