import Foundation

final class ICloudProgressSyncService {
    static let shared = ICloudProgressSyncService()

    enum Keys {
        static let bestScore = "nf_vexlo_best"
        static let dailyBestDayID = "nf_vexlo_daily_best_day_id"
        static let dailyBestScore = "nf_vexlo_daily_best_score"
        static let dailyCompletedDayID = "nf_vexlo_daily_completed_day_id"
        static let dailyStreakCount = "nf_vexlo_daily_streak_count"
        static let dailyLastStreakDayID = "nf_vexlo_daily_last_streak_day_id"
        static let soundEnabled = "nf_vexlo_sound_enabled"
        static let hapticsEnabled = "nf_vexlo_haptics_enabled"
        static let onboardingPlacementLearned = "nf_vexlo_onboarding_placement_learned"
        static let onboardingClearLearned = "nf_vexlo_onboarding_clear_learned"
    }

    private let defaults: UserDefaults
    private let store: NSUbiquitousKeyValueStore
    private let notificationCenter: NotificationCenter
    private var hasStarted = false

    private var isSyncAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    private var isUnitTesting: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private init(
        defaults: UserDefaults = .standard,
        store: NSUbiquitousKeyValueStore = .default,
        notificationCenter: NotificationCenter = .default
    ) {
        self.defaults = defaults
        self.store = store
        self.notificationCenter = notificationCenter
    }

    func start() {
        guard !hasStarted, !isUnitTesting else { return }
        hasStarted = true
        notificationCenter.addObserver(
            self,
            selector: #selector(ubiquitousStoreDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
        store.synchronize()
        mergeAllForCurrentDay()
    }

    @discardableResult
    func mergeBestScore(localBest: Int) -> Int {
        guard !isUnitTesting, isSyncAvailable else { return localBest }
        let cloudBest = Int(store.longLong(forKey: Keys.bestScore))
        let merged = max(localBest, cloudBest)
        if merged != localBest {
            defaults.set(merged, forKey: Keys.bestScore)
        }
        if merged != cloudBest {
            store.set(Int64(merged), forKey: Keys.bestScore)
        }
        return merged
    }

    func publishBestScore(_ bestScore: Int) {
        guard !isUnitTesting, isSyncAvailable else { return }
        let merged = max(bestScore, Int(store.longLong(forKey: Keys.bestScore)))
        defaults.set(merged, forKey: Keys.bestScore)
        store.set(Int64(merged), forKey: Keys.bestScore)
    }

    func mergeDailyProgress(currentDayID: String) {
        guard !isUnitTesting, isSyncAvailable else { return }
        mergeLatestDayID(dayKey: Keys.dailyLastStreakDayID, valueKey: Keys.dailyStreakCount)
        mergeLatestDayID(dayKey: Keys.dailyBestDayID, valueKey: Keys.dailyBestScore)
        mergeCurrentDayCompletion(currentDayID: currentDayID)
    }

    func publishDailyProgress(currentDayID: String) {
        guard !isUnitTesting, isSyncAvailable else { return }
        mergeDailyProgress(currentDayID: currentDayID)
        publishString(Keys.dailyBestDayID)
        publishInteger(Keys.dailyBestScore)
        publishString(Keys.dailyCompletedDayID)
        publishString(Keys.dailyLastStreakDayID)
        publishInteger(Keys.dailyStreakCount)
    }

    func publishBooleanPreference(key: String, value: Bool) {
        guard !isUnitTesting, isSyncAvailable else { return }
        defaults.set(value, forKey: key)
        store.set(value, forKey: key)
    }

    func publishLearnedFlag(key: String) {
        publishBooleanPreference(key: key, value: true)
    }

    private func mergeAllForCurrentDay() {
        let today = currentDayID()
        _ = mergeBestScore(localBest: defaults.integer(forKey: Keys.bestScore))
        mergeDailyProgress(currentDayID: today)
        mergeBoolean(key: Keys.soundEnabled, defaultValue: true)
        mergeBoolean(key: Keys.hapticsEnabled, defaultValue: true)
        mergeBoolean(key: Keys.onboardingPlacementLearned, defaultValue: false)
        mergeBoolean(key: Keys.onboardingClearLearned, defaultValue: false)
    }

    private func mergeLatestDayID(dayKey: String, valueKey: String) {
        let localDay = defaults.string(forKey: dayKey)
        let cloudDay = store.string(forKey: dayKey)
        switch selectedDay(local: localDay, cloud: cloudDay) {
        case .local:
            publishString(dayKey)
            publishInteger(valueKey)
        case .cloud:
            defaults.set(cloudDay, forKey: dayKey)
            defaults.set(Int(store.longLong(forKey: valueKey)), forKey: valueKey)
        case .same:
            let mergedValue = max(defaults.integer(forKey: valueKey), Int(store.longLong(forKey: valueKey)))
            defaults.set(mergedValue, forKey: valueKey)
            store.set(Int64(mergedValue), forKey: valueKey)
            if let localDay {
                store.set(localDay, forKey: dayKey)
            }
        case .none:
            break
        }
    }

    private func mergeCurrentDayCompletion(currentDayID: String) {
        let localCompleted = defaults.string(forKey: Keys.dailyCompletedDayID) == currentDayID
        let cloudCompleted = store.string(forKey: Keys.dailyCompletedDayID) == currentDayID
        guard localCompleted || cloudCompleted else { return }
        defaults.set(currentDayID, forKey: Keys.dailyCompletedDayID)
        store.set(currentDayID, forKey: Keys.dailyCompletedDayID)
    }

    private func mergeBoolean(key: String, defaultValue: Bool) {
        if let cloudValue = store.object(forKey: key) as? Bool {
            defaults.set(cloudValue, forKey: key)
        } else {
            let localValue = defaults.object(forKey: key) as? Bool ?? defaultValue
            store.set(localValue, forKey: key)
        }
    }

    private func publishString(_ key: String) {
        if let value = defaults.string(forKey: key) {
            store.set(value, forKey: key)
        }
    }

    private func publishInteger(_ key: String) {
        store.set(Int64(defaults.integer(forKey: key)), forKey: key)
    }

    private enum DaySelection {
        case local
        case cloud
        case same
        case none
    }

    private func selectedDay(local: String?, cloud: String?) -> DaySelection {
        switch (local, cloud) {
        case (.none, .none):
            return .none
        case (.some, .none):
            return .local
        case (.none, .some):
            return .cloud
        case let (.some(local), .some(cloud)) where local == cloud:
            return .same
        case let (.some(local), .some(cloud)):
            return local > cloud ? .local : .cloud
        }
    }

    private func currentDayID() -> String {
        let calendar = Calendar.autoupdatingCurrent
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    @objc private func ubiquitousStoreDidChange() {
        mergeAllForCurrentDay()
        WidgetSurfaceService.shared.publishDailyStatus(DailyChallengeService.shared.currentStatus())
    }
}
