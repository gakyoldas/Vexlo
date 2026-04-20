import Foundation

enum SystemEntryRoute {
    case todayChallenge
    case resumeLastRun
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
