import Foundation
import MetricKit
import OSLog
import UIKit

enum AnalyticsRunMode: String, Codable {
    case normal
    case daily
}

private struct RecentRunSummary: Codable {
    let mode: AnalyticsRunMode
    let score: Int
    let duration: TimeInterval
    let maxCombo: Int
    let didClearAny: Bool
    let continued: Bool
    let endedAt: Date
}

private struct AnalyticsAggregates: Codable {
    var sessionsStarted: Int = 0
    var runsStarted: Int = 0
    var runsEnded: Int = 0
    var normalRunsStarted: Int = 0
    var dailyRunsStarted: Int = 0
    var normalRunsEnded: Int = 0
    var dailyRunsEnded: Int = 0
    var totalTerminalScore: Int = 0
    var maxTerminalScore: Int = 0
    var totalRunDuration: TimeInterval = 0
    var restartTriggeredCount: Int = 0
    var restartLatencySamples: Int = 0
    var restartLatencyTotal: TimeInterval = 0
    var continueOfferShownCount: Int = 0
    var continueUsedCount: Int = 0
    var continueAdDismissedCount: Int = 0
    var continueAdFailedCount: Int = 0
    var continueSupporterBypassCount: Int = 0
    var rerollOfferShownCount: Int = 0
    var rerollUsedCount: Int = 0
    var rerollAdDismissedCount: Int = 0
    var rerollAdFailedCount: Int = 0
    var rerollSupporterBypassCount: Int = 0
    var dailyChallengeEnteredCount: Int = 0
    var dailyChallengeCompletedCount: Int = 0
    var lastDailyStreak: Int = 0
    var supporterPurchaseSuccessCount: Int = 0
    var supporterRestoreSuccessCount: Int = 0
}

private struct MetricSnapshot: Codable {
    var metricPayloadCount: Int = 0
    var diagnosticPayloadCount: Int = 0
    var crashDiagnosticsCount: Int = 0
    var hangDiagnosticsCount: Int = 0
    var cpuExceptionDiagnosticsCount: Int = 0
    var diskWriteExceptionDiagnosticsCount: Int = 0
    var latestPayloadDate: Date?
}

private struct CurrentRunState {
    let mode: AnalyticsRunMode
    let startedAt: Date
    var resultPresentedAt: Date?
    var continueOfferShown = false
    var rerollOfferShown = false
    var continued = false
}

final class AnalyticsService: NSObject, MXMetricManagerSubscriber {
    static let shared = AnalyticsService()

    private enum Keys {
        static let aggregates = "nf_vexlo_analytics_aggregates"
        static let recentRuns = "nf_vexlo_analytics_recent_runs"
        static let metricSnapshot = "nf_vexlo_analytics_metric_snapshot"
    }

    private let defaults = UserDefaults.standard
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Vexlo", category: "Instrumentation")
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let recentRunLimit = 20
    private var hasStarted = false
    private var currentRun: CurrentRunState?
    private var aggregates: AnalyticsAggregates
    private var recentRuns: [RecentRunSummary]
    private var metricSnapshot: MetricSnapshot

    private override init() {
        aggregates = Self.load(AnalyticsAggregates.self, key: Keys.aggregates) ?? AnalyticsAggregates()
        recentRuns = Self.load([RecentRunSummary].self, key: Keys.recentRuns) ?? []
        metricSnapshot = Self.load(MetricSnapshot.self, key: Keys.metricSnapshot) ?? MetricSnapshot()
        super.init()
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        MXMetricManager.shared.add(self)
    }

    func recordSessionStart() {
        startIfNeeded()
        aggregates.sessionsStarted += 1
        logger.log("session_start")
        persist()
    }

    func beginRun(mode: AnalyticsRunMode) {
        currentRun = CurrentRunState(mode: mode, startedAt: Date())
        aggregates.runsStarted += 1
        switch mode {
        case .normal:
            aggregates.normalRunsStarted += 1
        case .daily:
            aggregates.dailyRunsStarted += 1
        }
        logger.log("run_start mode=\(mode.rawValue, privacy: .public)")
        persist()
    }

    func markLossSurfacePresented() {
        guard currentRun?.resultPresentedAt == nil else { return }
        currentRun?.resultPresentedAt = Date()
        logger.log("loss_surface_presented")
    }

    func recordRestartTriggered() {
        aggregates.restartTriggeredCount += 1
        if let shownAt = currentRun?.resultPresentedAt {
            aggregates.restartLatencySamples += 1
            aggregates.restartLatencyTotal += Date().timeIntervalSince(shownAt)
        }
        logger.log("restart_triggered")
        persist()
    }

    func recordContinueOfferShown() {
        guard currentRun?.continueOfferShown == false else { return }
        currentRun?.continueOfferShown = true
        aggregates.continueOfferShownCount += 1
        logger.log("continue_offer_shown")
        persist()
    }

    func recordContinueUsedSuccessfully(viaSupporterBypass: Bool) {
        aggregates.continueUsedCount += 1
        if viaSupporterBypass {
            aggregates.continueSupporterBypassCount += 1
        }
        currentRun?.continued = true
        currentRun?.resultPresentedAt = nil
        logger.log("continue_used_success supporter=\(viaSupporterBypass, privacy: .public)")
        persist()
    }

    func recordContinueAdOutcome(_ result: RewardedPresentationResult) {
        switch result {
        case .dismissed:
            aggregates.continueAdDismissedCount += 1
        case .failed:
            aggregates.continueAdFailedCount += 1
        case .rewarded, .unavailable:
            return
        }
        logger.log("continue_ad_outcome=\(String(describing: result), privacy: .public)")
        persist()
    }

    func recordRerollOfferShown() {
        guard currentRun?.rerollOfferShown == false else { return }
        currentRun?.rerollOfferShown = true
        aggregates.rerollOfferShownCount += 1
        logger.log("reroll_offer_shown")
        persist()
    }

    func recordRerollUsedSuccessfully(viaSupporterBypass: Bool) {
        aggregates.rerollUsedCount += 1
        if viaSupporterBypass {
            aggregates.rerollSupporterBypassCount += 1
        }
        logger.log("reroll_used_success supporter=\(viaSupporterBypass, privacy: .public)")
        persist()
    }

    func recordRerollAdOutcome(_ result: RewardedPresentationResult) {
        switch result {
        case .dismissed:
            aggregates.rerollAdDismissedCount += 1
        case .failed:
            aggregates.rerollAdFailedCount += 1
        case .rewarded, .unavailable:
            return
        }
        logger.log("reroll_ad_outcome=\(String(describing: result), privacy: .public)")
        persist()
    }

    func recordDailyChallengeEntered() {
        aggregates.dailyChallengeEnteredCount += 1
        logger.log("daily_entered")
        persist()
    }

    func recordDailyChallengeCompleted(streak: Int) {
        aggregates.dailyChallengeCompletedCount += 1
        aggregates.lastDailyStreak = streak
        logger.log("daily_completed streak=\(streak, privacy: .public)")
        persist()
    }

    func recordSupporterPurchaseSuccess() {
        aggregates.supporterPurchaseSuccessCount += 1
        logger.log("supporter_purchase_success")
        persist()
    }

    func recordSupporterRestoreSuccess() {
        aggregates.supporterRestoreSuccessCount += 1
        logger.log("supporter_restore_success")
        persist()
    }

    func finalizeRun(score: Int, maxCombo: Int, didClearAny: Bool) {
        guard let run = currentRun else { return }
        let duration = Date().timeIntervalSince(run.startedAt)
        aggregates.runsEnded += 1
        switch run.mode {
        case .normal:
            aggregates.normalRunsEnded += 1
        case .daily:
            aggregates.dailyRunsEnded += 1
        }
        aggregates.totalTerminalScore += score
        aggregates.maxTerminalScore = max(aggregates.maxTerminalScore, score)
        aggregates.totalRunDuration += duration
        recentRuns.insert(
            RecentRunSummary(
                mode: run.mode,
                score: score,
                duration: duration,
                maxCombo: maxCombo,
                didClearAny: didClearAny,
                continued: run.continued,
                endedAt: Date()
            ),
            at: 0
        )
        if recentRuns.count > recentRunLimit {
            recentRuns = Array(recentRuns.prefix(recentRunLimit))
        }
        logger.log("run_end mode=\(run.mode.rawValue, privacy: .public) score=\(score, privacy: .public)")
        currentRun = nil
        persist()
    }

    var isTesterExportAvailable: Bool {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return true
        }
        #if targetEnvironment(simulator)
        return true
        #else
        #if DEBUG
        return true
        #else
        return Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
        #endif
    }

    func exportSnapshot() -> String {
        let snapshot = AnalyticsExportSnapshot(
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            build: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            sessionsStarted: aggregates.sessionsStarted,
            runsStarted: aggregates.runsStarted,
            runsEnded: aggregates.runsEnded,
            normalRunsStarted: aggregates.normalRunsStarted,
            dailyRunsStarted: aggregates.dailyRunsStarted,
            normalRunsEnded: aggregates.normalRunsEnded,
            dailyRunsEnded: aggregates.dailyRunsEnded,
            averageRunDuration: aggregates.runsEnded > 0 ? aggregates.totalRunDuration / Double(aggregates.runsEnded) : 0,
            medianRunDuration: medianRunDuration(),
            averageTerminalScore: aggregates.runsEnded > 0 ? Double(aggregates.totalTerminalScore) / Double(aggregates.runsEnded) : 0,
            maxTerminalScore: aggregates.maxTerminalScore,
            restartTriggeredCount: aggregates.restartTriggeredCount,
            averageRestartLatency: aggregates.restartLatencySamples > 0 ? aggregates.restartLatencyTotal / Double(aggregates.restartLatencySamples) : 0,
            continueOfferShownCount: aggregates.continueOfferShownCount,
            continueUsedCount: aggregates.continueUsedCount,
            continueAdDismissedCount: aggregates.continueAdDismissedCount,
            continueAdFailedCount: aggregates.continueAdFailedCount,
            continueSupporterBypassCount: aggregates.continueSupporterBypassCount,
            rerollOfferShownCount: aggregates.rerollOfferShownCount,
            rerollUsedCount: aggregates.rerollUsedCount,
            rerollAdDismissedCount: aggregates.rerollAdDismissedCount,
            rerollAdFailedCount: aggregates.rerollAdFailedCount,
            rerollSupporterBypassCount: aggregates.rerollSupporterBypassCount,
            dailyChallengeEnteredCount: aggregates.dailyChallengeEnteredCount,
            dailyChallengeCompletedCount: aggregates.dailyChallengeCompletedCount,
            lastDailyStreak: aggregates.lastDailyStreak,
            supporterPurchaseSuccessCount: aggregates.supporterPurchaseSuccessCount,
            supporterRestoreSuccessCount: aggregates.supporterRestoreSuccessCount,
            metricSnapshot: metricSnapshot,
            recentRuns: recentRuns
        )
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(snapshot),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        metricSnapshot.metricPayloadCount += payloads.count
        metricSnapshot.latestPayloadDate = Date()
        persist()
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        metricSnapshot.diagnosticPayloadCount += payloads.count
        metricSnapshot.latestPayloadDate = Date()
        for payload in payloads {
            metricSnapshot.crashDiagnosticsCount += payload.crashDiagnostics?.count ?? 0
            metricSnapshot.hangDiagnosticsCount += payload.hangDiagnostics?.count ?? 0
            metricSnapshot.cpuExceptionDiagnosticsCount += payload.cpuExceptionDiagnostics?.count ?? 0
            metricSnapshot.diskWriteExceptionDiagnosticsCount += payload.diskWriteExceptionDiagnostics?.count ?? 0
        }
        persist()
    }

    private func medianRunDuration() -> TimeInterval {
        let sorted = recentRuns.map(\.duration).sorted()
        guard !sorted.isEmpty else { return 0 }
        let middle = sorted.count / 2
        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) * 0.5
        }
        return sorted[middle]
    }

    private func persist() {
        save(aggregates, key: Keys.aggregates)
        save(recentRuns, key: Keys.recentRuns)
        save(metricSnapshot, key: Keys.metricSnapshot)
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? encoder.encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

private struct AnalyticsExportSnapshot: Codable {
    let appVersion: String
    let build: String
    let sessionsStarted: Int
    let runsStarted: Int
    let runsEnded: Int
    let normalRunsStarted: Int
    let dailyRunsStarted: Int
    let normalRunsEnded: Int
    let dailyRunsEnded: Int
    let averageRunDuration: TimeInterval
    let medianRunDuration: TimeInterval
    let averageTerminalScore: Double
    let maxTerminalScore: Int
    let restartTriggeredCount: Int
    let averageRestartLatency: TimeInterval
    let continueOfferShownCount: Int
    let continueUsedCount: Int
    let continueAdDismissedCount: Int
    let continueAdFailedCount: Int
    let continueSupporterBypassCount: Int
    let rerollOfferShownCount: Int
    let rerollUsedCount: Int
    let rerollAdDismissedCount: Int
    let rerollAdFailedCount: Int
    let rerollSupporterBypassCount: Int
    let dailyChallengeEnteredCount: Int
    let dailyChallengeCompletedCount: Int
    let lastDailyStreak: Int
    let supporterPurchaseSuccessCount: Int
    let supporterRestoreSuccessCount: Int
    let metricSnapshot: MetricSnapshot
    let recentRuns: [RecentRunSummary]
}
