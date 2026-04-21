import Foundation

struct DailyChallengeStatus {
    let dayID: String
    let seed: UInt64
    let todayBest: Int
    let hasCompletedToday: Bool
    let streakCount: Int
}

struct DailyChallengeCompletion {
    let dayID: String
    let score: Int
    let isNewBestToday: Bool
    let todayBest: Int
    let streakCount: Int
}

final class DailyChallengeService {
    static let shared = DailyChallengeService()

    private enum Keys {
        static let bestDayID = ICloudProgressSyncService.Keys.dailyBestDayID
        static let bestScore = ICloudProgressSyncService.Keys.dailyBestScore
        static let completedDayID = ICloudProgressSyncService.Keys.dailyCompletedDayID
        static let streakCount = ICloudProgressSyncService.Keys.dailyStreakCount
        static let lastStreakDayID = ICloudProgressSyncService.Keys.dailyLastStreakDayID
    }

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let syncService: ICloudProgressSyncService?

    private init() {
        defaults = .standard
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent
        self.calendar = calendar
        syncService = .shared
    }

    init(defaults: UserDefaults, calendar: Calendar) {
        self.defaults = defaults
        self.calendar = calendar
        syncService = nil
    }

    func refreshForCurrentDay() {
        let today = currentDayID()
        let visibleStreak = currentStreakCount(for: today)
        if visibleStreak != defaults.integer(forKey: Keys.streakCount) {
            defaults.set(visibleStreak, forKey: Keys.streakCount)
        }
        syncService?.mergeDailyProgress(currentDayID: today)
        WidgetSurfaceService.shared.publishDailyStatus(status(for: today))
    }

    func currentStatus() -> DailyChallengeStatus {
        let dayID = currentDayID()
        return status(for: dayID)
    }

    func status(for dayID: String) -> DailyChallengeStatus {
        DailyChallengeStatus(
            dayID: dayID,
            seed: seed(for: dayID),
            todayBest: bestScore(for: dayID),
            hasCompletedToday: hasCompleted(dayID: dayID),
            streakCount: currentStreakCount(for: dayID)
        )
    }

    func bestScore(for dayID: String) -> Int {
        guard defaults.string(forKey: Keys.bestDayID) == dayID else { return 0 }
        return defaults.integer(forKey: Keys.bestScore)
    }

    func previewStreakIfCompleted(dayID: String) -> Int {
        if hasCompleted(dayID: dayID) {
            return currentStreakCount(for: currentDayID())
        }
        guard let lastDayID = defaults.string(forKey: Keys.lastStreakDayID) else { return 1 }
        if isNextDay(dayID, after: lastDayID) {
            return max(1, defaults.integer(forKey: Keys.streakCount) + 1)
        }
        if lastDayID == dayID {
            return max(1, defaults.integer(forKey: Keys.streakCount))
        }
        return 1
    }

    func completeRun(dayID: String, score: Int) -> DailyChallengeCompletion {
        refreshForCurrentDay()
        let previousBest = bestScore(for: dayID)
        let isNewBest = score > previousBest
        let updatedBest = max(previousBest, score)
        defaults.set(dayID, forKey: Keys.bestDayID)
        defaults.set(updatedBest, forKey: Keys.bestScore)

        var streak = currentStreakCount(for: dayID)
        if !hasCompleted(dayID: dayID) {
            if let lastDayID = defaults.string(forKey: Keys.lastStreakDayID), isNextDay(dayID, after: lastDayID) {
                streak = max(1, defaults.integer(forKey: Keys.streakCount) + 1)
            } else if defaults.string(forKey: Keys.lastStreakDayID) == dayID {
                streak = max(1, defaults.integer(forKey: Keys.streakCount))
            } else {
                streak = 1
            }
            defaults.set(dayID, forKey: Keys.completedDayID)
            defaults.set(dayID, forKey: Keys.lastStreakDayID)
            defaults.set(streak, forKey: Keys.streakCount)
        }

        if streak == 0 {
            streak = max(1, defaults.integer(forKey: Keys.streakCount))
        }

        let completion = DailyChallengeCompletion(
            dayID: dayID,
            score: score,
            isNewBestToday: isNewBest,
            todayBest: updatedBest,
            streakCount: max(streak, currentStreakCount(for: currentDayID()))
        )
        let currentDayID = currentDayID()
        syncService?.publishDailyProgress(currentDayID: currentDayID)
        WidgetSurfaceService.shared.publishDailyStatus(status(for: currentDayID))
        return completion
    }

    func currentDayID() -> String {
        dayID(for: Date())
    }

    func seed(for dayID: String) -> UInt64 {
        dayID.utf8.reduce(UInt64(1469598103934665603)) { partial, byte in
            (partial ^ UInt64(byte)) &* 1099511628211
        }
    }

    private func hasCompleted(dayID: String) -> Bool {
        defaults.string(forKey: Keys.completedDayID) == dayID
    }

    private func currentStreakCount(for referenceDayID: String) -> Int {
        guard let lastDayID = defaults.string(forKey: Keys.lastStreakDayID) else { return 0 }
        let stored = defaults.integer(forKey: Keys.streakCount)
        guard stored > 0 else { return 0 }
        if lastDayID == referenceDayID || isNextDay(referenceDayID, after: lastDayID) {
            return stored
        }
        return 0
    }

    private func isNextDay(_ candidate: String, after baseline: String) -> Bool {
        guard let baselineDate = date(for: baseline),
              let nextDate = calendar.date(byAdding: .day, value: 1, to: baselineDate) else {
            return false
        }
        return dayID(for: nextDate) == candidate
    }

    private func dayID(for date: Date) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    private func date(for dayID: String) -> Date? {
        let parts = dayID.split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return nil }
        return calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
