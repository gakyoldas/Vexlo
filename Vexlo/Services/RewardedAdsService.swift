import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

enum RewardedPlacement: String, CaseIterable {
    case continueAfterLoss
    case rerollTrayPiece

    var infoPlistAdUnitKey: String {
        switch self {
        case .continueAfterLoss:
            RewardedAdsConfigKey.continueAdUnitID
        case .rerollTrayPiece:
            RewardedAdsConfigKey.rerollAdUnitID
        }
    }
}

enum RewardedPresentationResult {
    case rewarded
    case dismissed
    case unavailable
    case failed
}

struct RewardedAvailability {
    var continueAfterLossAvailable: Bool = false
    var rerollTrayPieceAvailable: Bool = false
}

/// Info.plist keys for rewarded AdMob configuration. Values are supplied at build/release time — never hardcode production IDs in source.
enum RewardedAdsConfigKey {
    static let gadApplicationID = "GADApplicationIdentifier"
    static let continueAdUnitID = "VexloRewardedContinueAdUnitID"
    static let rerollAdUnitID = "VexloRewardedRerollAdUnitID"
}

enum RewardedAdsConfigurationBlocker: String, Equatable, CaseIterable {
    case sdkModuleMissing
    case missingAppID
    case missingContinueAdUnitID
    case missingRerollAdUnitID
}

/// Read-only configuration and diagnostic state for rewarded ads.
struct RewardedAdsConfiguration: Equatable {
    private static let continueDebugAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private static let rerollDebugAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    let appID: String?
    let continueAfterLossAdUnitID: String?
    let rerollTrayPieceAdUnitID: String?
    let usesDebugTestAdUnits: Bool

    var diagnostic: RewardedAdsConfigurationDiagnostic {
        var blockers: [RewardedAdsConfigurationBlocker] = []
#if !canImport(GoogleMobileAds)
        blockers.append(.sdkModuleMissing)
#endif
        if Self.sanitized(appID) == nil {
            blockers.append(.missingAppID)
        }
        if continueAfterLossAdUnitID == nil {
            blockers.append(.missingContinueAdUnitID)
        }
        if rerollTrayPieceAdUnitID == nil {
            blockers.append(.missingRerollAdUnitID)
        }
        return RewardedAdsConfigurationDiagnostic(
            usesDebugTestAdUnits: usesDebugTestAdUnits,
            blockers: blockers
        )
    }

    var isSDKConfigured: Bool {
        Self.sanitized(appID) != nil
    }

    func adUnitID(for placement: RewardedPlacement) -> String? {
        switch placement {
        case .continueAfterLoss:
            continueAfterLossAdUnitID
        case .rerollTrayPiece:
            rerollTrayPieceAdUnitID
        }
    }

    func isPlacementConfigured(_ placement: RewardedPlacement) -> Bool {
        adUnitID(for: placement) != nil
    }

    static var current: RewardedAdsConfiguration {
        resolve(bundle: .main, allowDebugPlacementFallback: isDebugBuild)
    }

    static func resolve(
        bundle: Bundle = .main,
        allowDebugPlacementFallback: Bool = isDebugBuild
    ) -> RewardedAdsConfiguration {
        resolve(
            appID: bundle.object(forInfoDictionaryKey: RewardedAdsConfigKey.gadApplicationID) as? String,
            continuePlistValue: bundle.object(forInfoDictionaryKey: RewardedAdsConfigKey.continueAdUnitID) as? String,
            rerollPlistValue: bundle.object(forInfoDictionaryKey: RewardedAdsConfigKey.rerollAdUnitID) as? String,
            allowDebugPlacementFallback: allowDebugPlacementFallback
        )
    }

    static func resolve(
        appID: String?,
        continuePlistValue: String?,
        rerollPlistValue: String?,
        allowDebugPlacementFallback: Bool
    ) -> RewardedAdsConfiguration {
        let continueID = resolvedAdUnitID(
            plistValue: continuePlistValue,
            allowDebugFallback: allowDebugPlacementFallback,
            debugID: continueDebugAdUnitID
        )
        let rerollID = resolvedAdUnitID(
            plistValue: rerollPlistValue,
            allowDebugFallback: allowDebugPlacementFallback,
            debugID: rerollDebugAdUnitID
        )
        return RewardedAdsConfiguration(
            appID: appID,
            continueAfterLossAdUnitID: continueID,
            rerollTrayPieceAdUnitID: rerollID,
            usesDebugTestAdUnits: allowDebugPlacementFallback
                && (sanitized(continuePlistValue) == nil || sanitized(rerollPlistValue) == nil)
        )
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    private static func resolvedAdUnitID(
        plistValue: String?,
        allowDebugFallback: Bool,
        debugID: String
    ) -> String? {
        if let plistValue = sanitized(plistValue) {
            return plistValue
        }
        guard allowDebugFallback else { return nil }
        return debugID
    }

    private static func sanitized(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct RewardedAdsConfigurationDiagnostic: Equatable {
    let usesDebugTestAdUnits: Bool
    let blockers: [RewardedAdsConfigurationBlocker]

    var isFullyConfigured: Bool {
        blockers.isEmpty
    }

    var isRewardedCommerceConfigured: Bool {
        !blockers.contains(.missingAppID)
            && !blockers.contains(.missingContinueAdUnitID)
            && !blockers.contains(.missingRerollAdUnitID)
            && !blockers.contains(.sdkModuleMissing)
    }
}

@MainActor
final class RewardedAdsService: NSObject {
    static let shared = RewardedAdsService()

    var onAvailabilityChanged: ((RewardedAvailability) -> Void)?

    private(set) var configuration = RewardedAdsConfiguration.current
    private var hasStarted = false

#if canImport(GoogleMobileAds)
    private var continueAd: RewardedAd?
    private var rerollAd: RewardedAd?
    private var loadingPlacements: Set<RewardedPlacement> = []
    private var presentedPlacement: RewardedPlacement?
    private var rewardEarned = false
    private var presentationCompletion: ((RewardedPresentationResult) -> Void)?
#endif

    private override init() {
        super.init()
    }

    var configurationDiagnostic: RewardedAdsConfigurationDiagnostic {
        configuration.diagnostic
    }

    var availability: RewardedAvailability {
        RewardedAvailability(
            continueAfterLossAvailable: isLoaded(.continueAfterLoss),
            rerollTrayPieceAvailable: isLoaded(.rerollTrayPiece)
        )
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
        configuration = RewardedAdsConfiguration.current
#if canImport(GoogleMobileAds)
        guard configuration.isSDKConfigured else {
            publishAvailability()
            return
        }
        MobileAds.shared.start()
        preparePlacementsForActiveRun()
#else
        publishAvailability()
#endif
    }

    func preparePlacementsForActiveRun() {
        startIfNeeded()
        preloadIfNeeded(for: .continueAfterLoss)
        preloadIfNeeded(for: .rerollTrayPiece)
    }

    func present(
        _ placement: RewardedPlacement,
        from presenter: UIViewController,
        completion: @escaping (RewardedPresentationResult) -> Void
    ) {
#if canImport(GoogleMobileAds)
        startIfNeeded()
        guard presentationCompletion == nil else {
            completion(.failed)
            return
        }
        guard let ad = ad(for: placement) else {
            preloadIfNeeded(for: placement)
            completion(.unavailable)
            return
        }
        presentedPlacement = placement
        rewardEarned = false
        presentationCompletion = completion
        ad.fullScreenContentDelegate = self
        ad.present(from: presenter) { [weak self] in
            self?.rewardEarned = true
        }
#else
        completion(.unavailable)
#endif
    }

    private func publishAvailability() {
        onAvailabilityChanged?(availability)
    }

    private func isLoaded(_ placement: RewardedPlacement) -> Bool {
#if canImport(GoogleMobileAds)
        switch placement {
        case .continueAfterLoss:
            continueAd != nil
        case .rerollTrayPiece:
            rerollAd != nil
        }
#else
        false
#endif
    }

    private func preloadIfNeeded(for placement: RewardedPlacement) {
#if canImport(GoogleMobileAds)
        guard configuration.isPlacementConfigured(placement) else {
            publishAvailability()
            return
        }
        guard !isLoaded(placement), !loadingPlacements.contains(placement) else { return }
        loadingPlacements.insert(placement)
        Task { [weak self] in
            guard let self else { return }
            defer {
                self.loadingPlacements.remove(placement)
                self.publishAvailability()
            }
            do {
                let ad = try await RewardedAd.load(
                    with: self.configuration.adUnitID(for: placement) ?? "",
                    request: Request()
                )
                ad.fullScreenContentDelegate = self
                self.setAd(ad, for: placement)
            } catch {
                self.setAd(nil, for: placement)
            }
        }
#endif
    }

#if canImport(GoogleMobileAds)
    private func ad(for placement: RewardedPlacement) -> RewardedAd? {
        switch placement {
        case .continueAfterLoss:
            continueAd
        case .rerollTrayPiece:
            rerollAd
        }
    }

    private func setAd(_ ad: RewardedAd?, for placement: RewardedPlacement) {
        switch placement {
        case .continueAfterLoss:
            continueAd = ad
        case .rerollTrayPiece:
            rerollAd = ad
        }
    }

    private func finishPresentation(with result: RewardedPresentationResult) {
        let placement = presentedPlacement
        let completion = presentationCompletion
        presentedPlacement = nil
        presentationCompletion = nil
        rewardEarned = false
        completion?(result)
        if let placement {
            preloadIfNeeded(for: placement)
        }
    }
#endif
}

#if canImport(GoogleMobileAds)
extension RewardedAdsService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        finishPresentation(with: rewardEarned ? .rewarded : .dismissed)
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        finishPresentation(with: .failed)
    }
}
#endif
