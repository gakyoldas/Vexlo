import GameKit
import UIKit

final class GameCenterService: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterService()
    enum Leaderboard {
        static let score = "com.northfall.vexlo.alltime"
    }
    enum Challenge {
        static let scoreChase = "com.northfall.vexlo.scorechase"
    }
    enum GameActivity {
        static let dailyChallenge = "com.northfall.vexlo.dailychallenge"
        static let scoreChase = "com.northfall.vexlo.scorechase"
    }
    enum Achievement {
        static let firstClear = "com.northfall.vexlo.first_clear"
        static let comboThree = "com.northfall.vexlo.combo_three"
        static let score500 = "com.northfall.vexlo.score_500"
        static let runs10 = "com.northfall.vexlo.runs_10"
    }
    enum Route {
        case dailyChallenge
        case normalScoreChase
    }

    static func shouldSubmitDailyTableScore(
        todayBest: Int,
        dayID: String,
        lastSubmittedDayID: String?,
        lastSubmittedScore: Int
    ) -> Bool {
        guard todayBest > 0 else { return false }
        guard let lastSubmittedDayID else { return true }
        guard lastSubmittedDayID == dayID else { return true }
        return todayBest > lastSubmittedScore
    }

    private(set) var isAuthenticated = false
    private(set) var canPresentScoreChallenge = false
    private(set) var canPresentDailyActivity = false
    private(set) var canPresentScoreChaseActivity = false
    private let defaults = UserDefaults.standard
    private let completedRunsKey = "nf_vexlo_gc_completed_runs"
    private var rootViewControllerProvider: (() -> UIViewController?)?
    private var pendingBestScore: Int = 0
    private var pendingAchievementIDs: Set<String> = []
    private var pendingRoute: Route?
    private var scoreChallengeDefinitionID: String?
    private var availableGameActivityIDs: Set<String> = []
    private var hasRegisteredListener = false
    private var activityListener: AnyObject?
    var onRouteRequest: ((Route) -> Void)?

    var completedRunCount: Int {
        defaults.integer(forKey: completedRunsKey)
    }

    private override init() {}

    func configure(rootViewControllerProvider: @escaping () -> UIViewController?) {
        self.rootViewControllerProvider = rootViewControllerProvider
        authenticateIfNeeded()
    }

    func authenticateIfNeeded() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] vc, error in
            guard let self else { return }
            if let vc {
                self.topViewController()?.present(vc, animated: true)
                return
            }
            self.isAuthenticated = error == nil && player.isAuthenticated
            if self.isAuthenticated {
                self.registerListenerIfNeeded()
                self.refreshPresentationCapabilities()
                self.flushPending()
            }
        }
    }

    func reportCompletedRun(
        score: Int,
        didClearAny: Bool,
        maxCombo: Int,
        completedRuns: Int
    ) {
        pendingBestScore = max(pendingBestScore, score)
        if didClearAny {
            queueAchievement(Achievement.firstClear)
        }
        if maxCombo >= 3 {
            queueAchievement(Achievement.comboThree)
        }
        if score >= 500 {
            queueAchievement(Achievement.score500)
        }
        if completedRuns >= 10 {
            queueAchievement(Achievement.runs10)
        }
        flushPending()
    }

    func nextCompletedRunCount() -> Int {
        let runs = defaults.integer(forKey: completedRunsKey) + 1
        defaults.set(runs, forKey: completedRunsKey)
        return runs
    }

    func showProgressDashboard() {
        if !isAuthenticated {
            authenticateIfNeeded()
        }
        guard isAuthenticated else { return }
        let vc = GKGameCenterViewController(state: .dashboard)
        vc.gameCenterDelegate = self
        topViewController()?.present(vc, animated: true)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }

    private func queueAchievement(_ id: String) {
        pendingAchievementIDs.insert(id)
    }

    private func flushPending() {
        guard isAuthenticated else { return }
        if pendingBestScore > 0 {
            let score = pendingBestScore
            GKLeaderboard.submitScore(
                score,
                context: 0,
                player: GKLocalPlayer.local,
                leaderboardIDs: [Leaderboard.score]
            ) { [weak self] error in
                guard error == nil else { return }
                if self?.pendingBestScore == score {
                    self?.pendingBestScore = 0
                }
            }
        }
        guard !pendingAchievementIDs.isEmpty else { return }
        let ids = pendingAchievementIDs
        let achievements = ids.map { id in
            let achievement = GKAchievement(identifier: id)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = false
            return achievement
        }
        GKAchievement.report(achievements) { [weak self] error in
            guard error == nil else { return }
            self?.pendingAchievementIDs.subtract(ids)
        }
    }

    private func topViewController() -> UIViewController? {
        var current = rootViewControllerProvider?()
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }

    func submitScore(_ score: Int) {
        pendingBestScore = max(pendingBestScore, score)
        flushPending()
    }

    func unlockAchievement(_ id: String, percent: Double = 100) {
        guard percent >= 100 else { return }
        let achievement = GKAchievement(identifier: id)
        achievement.percentComplete = 100
        achievement.showsCompletionBanner = false
        pendingAchievementIDs.insert(id)
        flushPending()
    }

    func showLeaderboard(from viewController: UIViewController) {
        guard isAuthenticated else { return }
        let vc = GKGameCenterViewController(
            leaderboardID: Leaderboard.score,
            playerScope: .global,
            timeScope: .allTime
        )
        vc.gameCenterDelegate = self
        viewController.present(vc, animated: true)
    }

    func showScoreLeaderboard() {
        guard isAuthenticated else {
            authenticateIfNeeded()
            return
        }
        if #available(iOS 18.0, *) {
            GKAccessPoint.shared.trigger(
                leaderboardID: Leaderboard.score,
                playerScope: .global,
                timeScope: .allTime
            )
        } else if let viewController = topViewController() {
            showLeaderboard(from: viewController)
        }
    }

    func presentScoreChallengeIfAvailable() {
        guard #available(iOS 26.0, *),
              isAuthenticated,
              let scoreChallengeDefinitionID else {
            authenticateIfNeeded()
            return
        }
        GKAccessPoint.shared.trigger(challengeDefinitionID: scoreChallengeDefinitionID)
    }

    func presentDailyActivityIfAvailable() {
        guard #available(iOS 26.0, *),
              isAuthenticated,
              availableGameActivityIDs.contains(GameActivity.dailyChallenge) else {
            authenticateIfNeeded()
            return
        }
        GKAccessPoint.shared.trigger(gameActivityDefinitionID: GameActivity.dailyChallenge)
    }

    func presentScoreChaseActivityIfAvailable() {
        guard #available(iOS 26.0, *),
              isAuthenticated,
              availableGameActivityIDs.contains(GameActivity.scoreChase) else {
            authenticateIfNeeded()
            return
        }
        GKAccessPoint.shared.trigger(gameActivityDefinitionID: GameActivity.scoreChase)
    }

    func consumePendingRoute() -> Route? {
        let route = pendingRoute
        pendingRoute = nil
        return route
    }

    private func registerListenerIfNeeded() {
        guard !hasRegisteredListener else { return }
        hasRegisteredListener = true
        guard #available(iOS 26.0, *) else { return }
        let listener = GameCenterActivityListener { [weak self] route in
            if let handler = self?.onRouteRequest {
                handler(route)
            } else {
                self?.pendingRoute = route
            }
        }
        activityListener = listener
        GKLocalPlayer.local.register(listener)
    }

    private func refreshPresentationCapabilities() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.scoreChallengeDefinitionID = nil
            self.availableGameActivityIDs = []
            self.canPresentScoreChallenge = false
            self.canPresentDailyActivity = false
            self.canPresentScoreChaseActivity = false
            guard #available(iOS 26.0, *) else { return }

            let challengeDefinitions = (try? await GKChallengeDefinition.all) ?? []
            self.scoreChallengeDefinitionID =
                challengeDefinitions.first(where: { $0.identifier == Challenge.scoreChase })?.identifier ??
                challengeDefinitions.first(where: { $0.leaderboard != nil })?.identifier
            self.canPresentScoreChallenge = self.scoreChallengeDefinitionID != nil

            let activityDefinitions = (try? await GKGameActivityDefinition.all) ?? []
            self.availableGameActivityIDs = Set(activityDefinitions.map(\.identifier))
            self.canPresentDailyActivity = self.availableGameActivityIDs.contains(GameActivity.dailyChallenge)
            self.canPresentScoreChaseActivity = self.availableGameActivityIDs.contains(GameActivity.scoreChase)
        }
    }
}

@available(iOS 26.0, *)
private final class GameCenterActivityListener: NSObject, GKLocalPlayerListener {
    private let routeHandler: @MainActor (GameCenterService.Route) -> Void

    init(routeHandler: @escaping @MainActor (GameCenterService.Route) -> Void) {
        self.routeHandler = routeHandler
    }

    func player(_ player: GKPlayer, wantsToPlay activity: GKGameActivity) async -> Bool {
        let route: GameCenterService.Route?
        switch activity.activityDefinition.identifier {
        case GameCenterService.GameActivity.dailyChallenge:
            route = .dailyChallenge
        case GameCenterService.GameActivity.scoreChase:
            route = .normalScoreChase
        default:
            route = nil
        }
        guard let route else { return false }
        routeHandler(route)
        return true
    }
}
