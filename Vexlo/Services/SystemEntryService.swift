import Foundation

enum SystemEntryRoute {
    case todayChallenge
    case resumeLastRun
    case scoreSprint
}

extension SystemEntryRoute {
    init?(url: URL) {
        guard url.scheme == "vexlo" else { return nil }
        switch url.host {
        case "daily":
            self = .todayChallenge
        case "resume":
            self = .resumeLastRun
        case "event":
            self.init(eventURL: url)
        default:
            return nil
        }
    }

    private init?(eventURL url: URL) {
        let landingType = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == "type" || $0.name == "landing" }?
            .value ?? url.pathComponents.dropFirst().first
        switch landingType {
        case "score-sprint", "score_sprint":
            self = .scoreSprint
        case "daily-feature", "daily_feature":
            self = .todayChallenge
        default:
            return nil
        }
    }
}

final class SystemEntryService {
    static let shared = SystemEntryService()

    var onRouteRequest: ((SystemEntryRoute) -> Void)? {
        didSet { flushPendingRouteIfNeeded() }
    }

    private var pendingRoute: SystemEntryRoute?
    private var resumableRunMode: GameEngine.RunMode?
    private let hasPersistedRunProvider: () -> Bool

    private init() {
        hasPersistedRunProvider = { LiveRunPersistenceService.shared.hasPersistedRun }
    }

    init(hasPersistedRunProvider: @escaping () -> Bool) {
        self.hasPersistedRunProvider = hasPersistedRunProvider
    }

    var canResumeLastRun: Bool {
        hasInMemoryResumableRun || hasPersistedResumableRun
    }

    var hasInMemoryResumableRun: Bool {
        resumableRunMode != nil
    }

    var hasPersistedResumableRun: Bool {
        hasPersistedRunProvider()
    }

    func queue(_ route: SystemEntryRoute) {
        pendingRoute = route
        flushPendingRouteIfNeeded()
    }

    func queue(url: URL) {
        guard let route = SystemEntryRoute(url: url) else { return }
        queue(route)
    }

    func markRunActive(mode: GameEngine.RunMode) {
        resumableRunMode = mode
    }

    func clearResumableRun() {
        resumableRunMode = nil
    }

    private func flushPendingRouteIfNeeded() {
        guard let route = pendingRoute, let onRouteRequest else { return }
        pendingRoute = nil
        DispatchQueue.main.async {
            onRouteRequest(route)
        }
    }
}
