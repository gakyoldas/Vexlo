import Foundation
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

enum RewardedPlacement {
    case continueAfterLoss
    case rerollTrayPiece
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

@MainActor
final class RewardedAdsService: NSObject {
    static let shared = RewardedAdsService()

    var onAvailabilityChanged: ((RewardedAvailability) -> Void)?

    private let configuration = RewardedAdsConfiguration.current
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

    var availability: RewardedAvailability {
        RewardedAvailability(
            continueAfterLossAvailable: isLoaded(.continueAfterLoss),
            rerollTrayPieceAvailable: isLoaded(.rerollTrayPiece)
        )
    }

    func startIfNeeded() {
        guard !hasStarted else { return }
        hasStarted = true
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
        guard configuration.adUnitID(for: placement) != nil else {
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

private struct RewardedAdsConfiguration {
    private static let continueDebugAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private static let rerollDebugAdUnitID = "ca-app-pub-3940256099942544/1712485313"

    let appID: String?
    let continueAfterLossAdUnitID: String?
    let rerollTrayPieceAdUnitID: String?

    static var current: RewardedAdsConfiguration {
        let bundle = Bundle.main
        let appID = bundle.object(forInfoDictionaryKey: "GADApplicationIdentifier") as? String
        let continueID = bundle.object(forInfoDictionaryKey: "VexloRewardedContinueAdUnitID") as? String
        let rerollID = bundle.object(forInfoDictionaryKey: "VexloRewardedRerollAdUnitID") as? String
        #if DEBUG
        return RewardedAdsConfiguration(
            appID: appID,
            continueAfterLossAdUnitID: continueID ?? continueDebugAdUnitID,
            rerollTrayPieceAdUnitID: rerollID ?? rerollDebugAdUnitID
        )
        #else
        return RewardedAdsConfiguration(
            appID: appID,
            continueAfterLossAdUnitID: continueID,
            rerollTrayPieceAdUnitID: rerollID
        )
        #endif
    }

    var isSDKConfigured: Bool {
        guard let appID else { return false }
        return !appID.isEmpty
    }

    func adUnitID(for placement: RewardedPlacement) -> String? {
        switch placement {
        case .continueAfterLoss:
            continueAfterLossAdUnitID
        case .rerollTrayPiece:
            rerollTrayPieceAdUnitID
        }
    }
}
