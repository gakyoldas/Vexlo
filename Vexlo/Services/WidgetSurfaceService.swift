import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

struct WidgetSurfaceSnapshot: Codable, Equatable {
    enum RunMode: String, Codable {
        case normal
        case daily
    }

    let canResumeRun: Bool
    let runMode: RunMode?
    let score: Int?
    let dayID: String
    let hasCompletedToday: Bool
    let streakCount: Int

    static func dailyFallback(status: DailyChallengeStatus) -> WidgetSurfaceSnapshot {
        WidgetSurfaceSnapshot(
            canResumeRun: false,
            runMode: nil,
            score: nil,
            dayID: status.dayID,
            hasCompletedToday: status.hasCompletedToday,
            streakCount: status.streakCount
        )
    }
}

final class WidgetSurfaceService {
    static let shared = WidgetSurfaceService()

    enum Contract {
        static let appGroupID = "group.com.northfallstudio.Vexlo"
        static let snapshotKey = "nf_vexlo_widget_surface_snapshot"
        static let widgetKind = "com.northfallstudio.Vexlo.reentry"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        defaults = UserDefaults(suiteName: Contract.appGroupID) ?? .standard
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    func publishDailyStatus(_ status: DailyChallengeStatus) {
        let current = loadSnapshot()
        let snapshot = WidgetSurfaceSnapshot(
            canResumeRun: current?.canResumeRun == true,
            runMode: current?.runMode,
            score: current?.score,
            dayID: status.dayID,
            hasCompletedToday: status.hasCompletedToday,
            streakCount: status.streakCount
        )
        save(snapshot)
    }

    func publishLiveRun(_ snapshot: GameEngine.LiveRunSnapshot) {
        let status = DailyChallengeService.shared.currentStatus()
        let runMode: WidgetSurfaceSnapshot.RunMode = snapshot.runMode.kind == "daily" ? .daily : .normal
        save(
            WidgetSurfaceSnapshot(
                canResumeRun: true,
                runMode: runMode,
                score: snapshot.score,
                dayID: status.dayID,
                hasCompletedToday: status.hasCompletedToday,
                streakCount: status.streakCount
            )
        )
    }

    func clearResumableRun() {
        let status = DailyChallengeService.shared.currentStatus()
        save(.dailyFallback(status: status))
    }

    private func loadSnapshot() -> WidgetSurfaceSnapshot? {
        guard let data = defaults.data(forKey: Contract.snapshotKey) else { return nil }
        return try? decoder.decode(WidgetSurfaceSnapshot.self, from: data)
    }

    private func save(_ snapshot: WidgetSurfaceSnapshot) {
        guard let data = try? encoder.encode(snapshot),
              data != defaults.data(forKey: Contract.snapshotKey) else { return }
        defaults.set(data, forKey: Contract.snapshotKey)
        reloadWidget()
    }

    private func reloadWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: Contract.widgetKind)
        #endif
    }
}
