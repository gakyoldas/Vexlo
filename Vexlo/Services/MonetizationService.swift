import Foundation
import UIKit

enum MonetizationOfferKind {
    case continueAfterLoss
    case rerollTrayPiece
    case supporterUnlock
}

struct MonetizationCapabilities {
    var rewardedContinueAvailable: Bool = false
    var rewardedRerollAvailable: Bool = false
    var supporterUnlockAvailable: Bool = false
    var supporterOwned: Bool = false

    func supports(_ offer: MonetizationOfferKind) -> Bool {
        switch offer {
        case .continueAfterLoss:
            rewardedContinueAvailable || supporterOwned
        case .rerollTrayPiece:
            rewardedRerollAvailable || supporterOwned
        case .supporterUnlock:
            supporterUnlockAvailable && !supporterOwned
        }
    }
}

private struct MonetizationPlayerState {
    var sessionCount: Int
    var runsStarted: Int
}

private struct MonetizationRunState {
    var isActive: Bool = false
    var hasEnded: Bool = false
    var continueOfferCount: Int = 0
    var rerollOfferCount: Int = 0
}

private struct MonetizationPolicy {
    let suppressedSessionCount = 2
    let suppressedRunCount = 4
    let rerollUnlockRunCount = 8
    let supporterVisibilityRunCount = 6
    let maxContinueOffersPerRun = 1
    let maxRerollOffersPerRun = 1

    func allows(
        _ offer: MonetizationOfferKind,
        player: MonetizationPlayerState,
        run: MonetizationRunState,
        capabilities: MonetizationCapabilities
    ) -> Bool {
        guard capabilities.supports(offer) else { return false }
        switch offer {
        case .continueAfterLoss:
            guard player.sessionCount > suppressedSessionCount || player.runsStarted > suppressedRunCount else {
                return false
            }
            return run.hasEnded && run.continueOfferCount < maxContinueOffersPerRun
        case .rerollTrayPiece:
            guard player.runsStarted >= rerollUnlockRunCount else { return false }
            guard !run.hasEnded else { return false }
            return run.rerollOfferCount < maxRerollOffersPerRun
        case .supporterUnlock:
            guard player.sessionCount > suppressedSessionCount || player.runsStarted >= supporterVisibilityRunCount else {
                return false
            }
            return true
        }
    }
}

final class MonetizationService {
    static let shared = MonetizationService()

    private enum Keys {
        static let sessionCount = "nf_vexlo_monetization_session_count"
        static let runsStarted = "nf_vexlo_monetization_runs_started"
    }

    private let defaults = UserDefaults.standard
    private let policy = MonetizationPolicy()
    private(set) var capabilities = MonetizationCapabilities()
    private var rewardedFoundationConfigured = false
    private var supporterFoundationConfigured = false
    private var sessionStarted = false
    private var runState = MonetizationRunState()
    private var testingCanPresentOverrides: [MonetizationOfferKind: Bool] = [:]

    private init() {}

    func beginSessionIfNeeded() {
        configureRewardedFoundationIfNeeded()
        configureSupporterFoundationIfNeeded()
        guard !sessionStarted else { return }
        sessionStarted = true
        defaults.set(sessionCount + 1, forKey: Keys.sessionCount)
        refreshCapabilities()
    }

    func beginRun() {
        beginSessionIfNeeded()
        defaults.set(runsStarted + 1, forKey: Keys.runsStarted)
        runState = MonetizationRunState(isActive: true)
        RewardedAdsService.shared.preparePlacementsForActiveRun()
        refreshCapabilities()
    }

    func markRunEnded() {
        guard runState.isActive else { return }
        runState.hasEnded = true
        refreshCapabilities()
    }

    func resumeRunAfterContinue() {
        guard runState.isActive else { return }
        runState.hasEnded = false
        refreshCapabilities()
    }

    func canPresent(_ offer: MonetizationOfferKind) -> Bool {
        if let override = testingCanPresentOverrides[offer] {
            return override
        }
        return policy.allows(
            offer,
            player: MonetizationPlayerState(sessionCount: sessionCount, runsStarted: runsStarted),
            run: runState,
            capabilities: capabilities
        )
    }

    func recordOfferPresentation(_ offer: MonetizationOfferKind) {
        switch offer {
        case .continueAfterLoss:
            runState.continueOfferCount += 1
        case .rerollTrayPiece:
            runState.rerollOfferCount += 1
        case .supporterUnlock:
            break
        }
    }

    func presentRewardedOffer(
        _ offer: MonetizationOfferKind,
        from presenter: UIViewController,
        completion: @escaping (RewardedPresentationResult) -> Void
    ) {
        guard canPresent(offer) else {
            completion(.unavailable)
            return
        }
        if capabilities.supporterOwned, offer != .supporterUnlock {
            recordOfferPresentation(offer)
            refreshCapabilities()
            completion(.rewarded)
            return
        }
        guard let placement = rewardedPlacement(for: offer) else {
            completion(.unavailable)
            return
        }
        RewardedAdsService.shared.present(placement, from: presenter) { [weak self] result in
            if result == .rewarded {
                self?.recordOfferPresentation(offer)
            }
            self?.refreshCapabilities()
            completion(result)
        }
    }

    func canPresentSupporterPack() -> Bool {
        canPresent(.supporterUnlock)
    }

    func purchaseSupporterPack() async -> SupporterPackPurchaseResult {
        let result = await SupporterPackService.shared.purchase()
        refreshCapabilities()
        return result
    }

    func restoreSupporterPack() async -> Bool {
        let restored = await SupporterPackService.shared.restore()
        refreshCapabilities()
        return restored
    }

    func resetRunState() {
        runState = MonetizationRunState()
        refreshCapabilities()
    }

    func restoreRunState(hasUsedContinue: Bool, hasUsedReroll: Bool) {
        beginSessionIfNeeded()
        runState = MonetizationRunState(
            isActive: true,
            hasEnded: false,
            continueOfferCount: hasUsedContinue ? 1 : 0,
            rerollOfferCount: hasUsedReroll ? 1 : 0
        )
        RewardedAdsService.shared.preparePlacementsForActiveRun()
        refreshCapabilities()
    }

    private var sessionCount: Int {
        defaults.integer(forKey: Keys.sessionCount)
    }

    private var runsStarted: Int {
        defaults.integer(forKey: Keys.runsStarted)
    }

    private func configureRewardedFoundationIfNeeded() {
        guard !rewardedFoundationConfigured else { return }
        rewardedFoundationConfigured = true
        RewardedAdsService.shared.onAvailabilityChanged = { [weak self] _ in
            self?.refreshCapabilities()
        }
        RewardedAdsService.shared.startIfNeeded()
    }

    private func configureSupporterFoundationIfNeeded() {
        guard !supporterFoundationConfigured else { return }
        supporterFoundationConfigured = true
        SupporterPackService.shared.onStateChanged = { [weak self] in
            self?.refreshCapabilities()
        }
        SupporterPackService.shared.startIfNeeded()
    }

    private func refreshCapabilities() {
        let availability = RewardedAdsService.shared.availability
        capabilities.rewardedContinueAvailable = availability.continueAfterLossAvailable
        capabilities.rewardedRerollAvailable = availability.rerollTrayPieceAvailable
        capabilities.supporterUnlockAvailable = SupporterPackService.shared.isProductLoaded
        capabilities.supporterOwned = SupporterPackService.shared.isOwned
    }

    private func rewardedPlacement(for offer: MonetizationOfferKind) -> RewardedPlacement? {
        switch offer {
        case .continueAfterLoss:
            .continueAfterLoss
        case .rerollTrayPiece:
            .rerollTrayPiece
        case .supporterUnlock:
            nil
        }
    }

    struct AttachmentSnapshot: Equatable {
        let continueOfferCount: Int
        let rerollOfferCount: Int
        let sessionCount: Int
        let runsStarted: Int
        let supporterOwned: Bool
        let continueCommerceAvailable: Bool
        let rerollCommerceAvailable: Bool
    }

    func attachmentSnapshot() -> AttachmentSnapshot {
        AttachmentSnapshot(
            continueOfferCount: runState.continueOfferCount,
            rerollOfferCount: runState.rerollOfferCount,
            sessionCount: sessionCount,
            runsStarted: runsStarted,
            supporterOwned: capabilities.supporterOwned,
            continueCommerceAvailable: capabilities.supports(.continueAfterLoss),
            rerollCommerceAvailable: capabilities.supports(.rerollTrayPiece)
        )
    }
}

extension MonetizationService {
    struct TestingRunState {
        let isActive: Bool
        let hasEnded: Bool
        let continueOfferCount: Int
        let rerollOfferCount: Int
    }

    var testingRunState: TestingRunState {
        TestingRunState(
            isActive: runState.isActive,
            hasEnded: runState.hasEnded,
            continueOfferCount: runState.continueOfferCount,
            rerollOfferCount: runState.rerollOfferCount
        )
    }

    func testingSetCanPresentOverride(_ isEnabled: Bool?, for offer: MonetizationOfferKind) {
        if let isEnabled {
            testingCanPresentOverrides[offer] = isEnabled
        } else {
            testingCanPresentOverrides.removeValue(forKey: offer)
        }
    }

    func testingClearCanPresentOverrides() {
        testingCanPresentOverrides.removeAll()
    }

    func testingForceRewardedCommerceCapabilitiesForPresentation() {
        capabilities.rewardedContinueAvailable = true
        capabilities.rewardedRerollAvailable = true
    }
}
