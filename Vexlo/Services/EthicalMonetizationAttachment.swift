import Foundation

/// Product attachment points for ethical monetization (Economy Clarity v1).
enum MonetizationAttachmentPoint: String, Codable, CaseIterable, Equatable {
    case continueAfterLoss
    case rerollTrayPiece
    case supporterPatronage
    case atelierCosmetic
}

/// Surfaces where monetization may appear without taking over the product.
enum MonetizationAttachmentSurface: String, Codable, CaseIterable, Equatable {
    case terminalLossOverlay
    case activeTraySlot
    case utilityMenu
    case atelierGallery
}

/// Editorial cosmetic categories allowed for future Atelier ownership.
enum AtelierCosmeticCategory: String, Codable, CaseIterable, Equatable {
    case boardFrameFinish
    case pieceMineralPalette
    case hudAccentTone
    case shareCardFinish
    case trayRestMarkFinish

    static let allowedCategories: [AtelierCosmeticCategory] = allCases
}

/// Grants that must never be sold or rewarded through monetization.
enum ForbiddenMonetizationGrant: String, Codable, CaseIterable, Equatable {
    case scoreOrComboPower
    case extraContinueCapacity
    case masteryUnlock
    case codexUnlock
    case readerProfileUnlock
    case streakInsurance
    case countdownOrScarcityOffer
    case gameplayHintAutomation
}

struct MonetizationAttachmentDefinition: Equatable {
    let point: MonetizationAttachmentPoint
    let surfaces: [MonetizationAttachmentSurface]
    let neverGrantsPower: Bool
    let respectsRetentionSpine: Bool
    let productIntent: String
}

/// Static catalog of where commerce may attach and what it must never become.
enum EthicalMonetizationPolicy {
    static let suppressedSessionCount = 2
    static let suppressedRunCount = 4
    static let rerollUnlockRunCount = 8
    static let supporterVisibilityRunCount = 6
    static let maxContinueOffersPerRun = 1
    static let maxRerollOffersPerRun = 1
    static let minimumScoreForContinueReadingValue = 120
    static let profileSynthesisWindow = ReaderProfileEvaluator.profileWindow

    static let attachmentCatalog: [MonetizationAttachmentDefinition] = [
        MonetizationAttachmentDefinition(
            point: .continueAfterLoss,
            surfaces: [.terminalLossOverlay],
            neverGrantsPower: true,
            respectsRetentionSpine: true,
            productIntent: VexloStrings.MonetizationAttachment.continueIntent
        ),
        MonetizationAttachmentDefinition(
            point: .rerollTrayPiece,
            surfaces: [.activeTraySlot],
            neverGrantsPower: true,
            respectsRetentionSpine: true,
            productIntent: VexloStrings.MonetizationAttachment.rerollIntent
        ),
        MonetizationAttachmentDefinition(
            point: .supporterPatronage,
            surfaces: [.utilityMenu],
            neverGrantsPower: true,
            respectsRetentionSpine: true,
            productIntent: VexloStrings.MonetizationAttachment.supporterIntent
        ),
        MonetizationAttachmentDefinition(
            point: .atelierCosmetic,
            surfaces: [.atelierGallery, .utilityMenu],
            neverGrantsPower: true,
            respectsRetentionSpine: true,
            productIntent: VexloStrings.MonetizationAttachment.atelierIntent
        )
    ]

    static func definition(for point: MonetizationAttachmentPoint) -> MonetizationAttachmentDefinition? {
        attachmentCatalog.first { $0.point == point }
    }

    static func isForbiddenGrant(_ grant: ForbiddenMonetizationGrant) -> Bool {
        ForbiddenMonetizationGrant.allCases.contains(grant)
    }

    static func isAllowedAtelierCategory(_ category: AtelierCosmeticCategory) -> Bool {
        AtelierCosmeticCategory.allowedCategories.contains(category)
    }
}

/// Run-time facts for attachment evaluation. Does not mutate gameplay.
struct MonetizationAttachmentContext: Equatable {
    let isDailyChallenge: Bool
    let isGameOver: Bool
    let didClearAny: Bool
    let score: Int
    let maxCombo: Int
    let hasUsedContinue: Bool
    let hasUsedReroll: Bool
    let canEngineResumeAfterLoss: Bool
    let canEngineRerollAtRequestedSlot: Bool
    let continueOffersPresented: Int
    let rerollOffersPresented: Int
    let sessionCount: Int
    let runsStarted: Int
    let supporterOwned: Bool
    let commerceCapabilityAvailable: Bool

    var runHadContinueReadingValue: Bool {
        didClearAny
            || maxCombo >= 2
            || score >= EthicalMonetizationPolicy.minimumScoreForContinueReadingValue
    }

    var passedEarlyPlayerProtection: Bool {
        sessionCount > EthicalMonetizationPolicy.suppressedSessionCount
            || runsStarted > EthicalMonetizationPolicy.suppressedRunCount
    }

    /// Live run facts for ethical gating at presentation seams.
    static func live(
        for point: MonetizationAttachmentPoint,
        engine: GameEngine,
        monetization: MonetizationService = .shared,
        rerollSlotIndex: Int? = nil
    ) -> MonetizationAttachmentContext {
        let snapshot = monetization.attachmentSnapshot()
        let commerceCapabilityAvailable: Bool
        switch point {
        case .continueAfterLoss:
            commerceCapabilityAvailable = snapshot.continueCommerceAvailable
        case .rerollTrayPiece:
            commerceCapabilityAvailable = snapshot.rerollCommerceAvailable
        case .supporterPatronage, .atelierCosmetic:
            commerceCapabilityAvailable = false
        }
        let canEngineRerollAtRequestedSlot: Bool
        if let rerollSlotIndex {
            canEngineRerollAtRequestedSlot = engine.canRerollPiece(at: rerollSlotIndex)
        } else {
            canEngineRerollAtRequestedSlot = false
        }
        return MonetizationAttachmentContext(
            isDailyChallenge: engine.isDailyChallenge,
            isGameOver: engine.isGameOver,
            didClearAny: engine.didClearAny,
            score: engine.scoreEngine.score,
            maxCombo: engine.maxCombo,
            hasUsedContinue: engine.hasUsedContinue,
            hasUsedReroll: engine.hasUsedReroll,
            canEngineResumeAfterLoss: engine.canResumeAfterLoss(),
            canEngineRerollAtRequestedSlot: canEngineRerollAtRequestedSlot,
            continueOffersPresented: snapshot.continueOfferCount,
            rerollOffersPresented: snapshot.rerollOfferCount,
            sessionCount: snapshot.sessionCount,
            runsStarted: snapshot.runsStarted,
            supporterOwned: snapshot.supporterOwned,
            commerceCapabilityAvailable: commerceCapabilityAvailable
        )
    }
}

enum MonetizationAttachmentDenialReason: String, Codable, Equatable {
    case dailyModeExcluded
    case insufficientReadingValue
    case runNotEnded
    case runAlreadyEnded
    case engineCannotResume
    case engineCannotReroll
    case continueAlreadyUsed
    case rerollAlreadyUsed
    case offerCapReached
    case earlyPlayerProtection
    case rerollNotUnlockedYet
    case supporterAlreadyOwned
    case commerceUnavailable
    case atelierCategoryNotAllowed
    case forbiddenGrantRequested
}

struct MonetizationAttachmentVerdict: Equatable {
    let point: MonetizationAttachmentPoint
    let isEthicallyEligible: Bool
    let denialReason: MonetizationAttachmentDenialReason?
    let productFraming: String

    var isAttachable: Bool {
        isEthicallyEligible
    }
}

/// Deterministic ethical eligibility for monetization attachment points.
enum EthicalMonetizationEvaluator {
    static func evaluateContinue(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        let framing = VexloStrings.MonetizationAttachment.continueFraming
        if context.isDailyChallenge {
            return verdict(.continueAfterLoss, eligible: false, reason: .dailyModeExcluded, framing: framing)
        }
        if !context.passedEarlyPlayerProtection {
            return verdict(.continueAfterLoss, eligible: false, reason: .earlyPlayerProtection, framing: framing)
        }
        if !context.isGameOver {
            return verdict(.continueAfterLoss, eligible: false, reason: .runNotEnded, framing: framing)
        }
        if context.hasUsedContinue {
            return verdict(.continueAfterLoss, eligible: false, reason: .continueAlreadyUsed, framing: framing)
        }
        if !context.runHadContinueReadingValue {
            return verdict(.continueAfterLoss, eligible: false, reason: .insufficientReadingValue, framing: framing)
        }
        if !context.canEngineResumeAfterLoss {
            return verdict(.continueAfterLoss, eligible: false, reason: .engineCannotResume, framing: framing)
        }
        if context.continueOffersPresented >= EthicalMonetizationPolicy.maxContinueOffersPerRun {
            return verdict(.continueAfterLoss, eligible: false, reason: .offerCapReached, framing: framing)
        }
        if !context.commerceCapabilityAvailable {
            return verdict(.continueAfterLoss, eligible: false, reason: .commerceUnavailable, framing: framing)
        }
        return verdict(.continueAfterLoss, eligible: true, reason: nil, framing: framing)
    }

    /// Ethics-only gate composed after MonetizationService policy at the live presentation seam.
    static func evaluateContinueForPresentation(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        let framing = VexloStrings.MonetizationAttachment.continueFraming
        if context.isDailyChallenge {
            return verdict(.continueAfterLoss, eligible: false, reason: .dailyModeExcluded, framing: framing)
        }
        if !context.isGameOver {
            return verdict(.continueAfterLoss, eligible: false, reason: .runNotEnded, framing: framing)
        }
        if context.hasUsedContinue {
            return verdict(.continueAfterLoss, eligible: false, reason: .continueAlreadyUsed, framing: framing)
        }
        if !context.runHadContinueReadingValue {
            return verdict(.continueAfterLoss, eligible: false, reason: .insufficientReadingValue, framing: framing)
        }
        if !context.canEngineResumeAfterLoss {
            return verdict(.continueAfterLoss, eligible: false, reason: .engineCannotResume, framing: framing)
        }
        return verdict(.continueAfterLoss, eligible: true, reason: nil, framing: framing)
    }

    static func evaluateReroll(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        let framing = VexloStrings.MonetizationAttachment.rerollFraming
        if context.isDailyChallenge {
            return verdict(.rerollTrayPiece, eligible: false, reason: .dailyModeExcluded, framing: framing)
        }
        if context.runsStarted < EthicalMonetizationPolicy.rerollUnlockRunCount {
            return verdict(.rerollTrayPiece, eligible: false, reason: .rerollNotUnlockedYet, framing: framing)
        }
        if context.isGameOver {
            return verdict(.rerollTrayPiece, eligible: false, reason: .runAlreadyEnded, framing: framing)
        }
        if context.hasUsedReroll {
            return verdict(.rerollTrayPiece, eligible: false, reason: .rerollAlreadyUsed, framing: framing)
        }
        if !context.canEngineRerollAtRequestedSlot {
            return verdict(.rerollTrayPiece, eligible: false, reason: .engineCannotReroll, framing: framing)
        }
        if context.rerollOffersPresented >= EthicalMonetizationPolicy.maxRerollOffersPerRun {
            return verdict(.rerollTrayPiece, eligible: false, reason: .offerCapReached, framing: framing)
        }
        if !context.commerceCapabilityAvailable {
            return verdict(.rerollTrayPiece, eligible: false, reason: .commerceUnavailable, framing: framing)
        }
        return verdict(.rerollTrayPiece, eligible: true, reason: nil, framing: framing)
    }

    /// Ethics-only gate composed after MonetizationService policy at the live presentation seam.
    static func evaluateRerollForPresentation(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        let framing = VexloStrings.MonetizationAttachment.rerollFraming
        if context.isDailyChallenge {
            return verdict(.rerollTrayPiece, eligible: false, reason: .dailyModeExcluded, framing: framing)
        }
        if context.isGameOver {
            return verdict(.rerollTrayPiece, eligible: false, reason: .runAlreadyEnded, framing: framing)
        }
        if context.hasUsedReroll {
            return verdict(.rerollTrayPiece, eligible: false, reason: .rerollAlreadyUsed, framing: framing)
        }
        if !context.canEngineRerollAtRequestedSlot {
            return verdict(.rerollTrayPiece, eligible: false, reason: .engineCannotReroll, framing: framing)
        }
        return verdict(.rerollTrayPiece, eligible: true, reason: nil, framing: framing)
    }

    static func evaluateSupporter(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        let framing = VexloStrings.MonetizationAttachment.supporterFraming
        if context.supporterOwned {
            return verdict(.supporterPatronage, eligible: false, reason: .supporterAlreadyOwned, framing: framing)
        }
        let visible = context.sessionCount > EthicalMonetizationPolicy.suppressedSessionCount
            || context.runsStarted >= EthicalMonetizationPolicy.supporterVisibilityRunCount
        if !visible {
            return verdict(.supporterPatronage, eligible: false, reason: .earlyPlayerProtection, framing: framing)
        }
        if !context.commerceCapabilityAvailable {
            return verdict(.supporterPatronage, eligible: false, reason: .commerceUnavailable, framing: framing)
        }
        return verdict(.supporterPatronage, eligible: true, reason: nil, framing: framing)
    }

    static func evaluateAtelier(
        category: AtelierCosmeticCategory,
        requestedGrant: ForbiddenMonetizationGrant? = nil
    ) -> MonetizationAttachmentVerdict {
        let framing = VexloStrings.MonetizationAttachment.atelierFraming
        if let requestedGrant {
            return verdict(.atelierCosmetic, eligible: false, reason: .forbiddenGrantRequested, framing: framing)
        }
        if !EthicalMonetizationPolicy.isAllowedAtelierCategory(category) {
            return verdict(.atelierCosmetic, eligible: false, reason: .atelierCategoryNotAllowed, framing: framing)
        }
        return verdict(.atelierCosmetic, eligible: true, reason: nil, framing: framing)
    }

    static func supporterValueTiedToRetentionSpine() -> [String] {
        [
            VexloStrings.MonetizationAttachment.supporterSpineUninterrupted,
            VexloStrings.MonetizationAttachment.supporterSpineEarnedMemory,
            VexloStrings.MonetizationAttachment.supporterSpineNoPower
        ]
    }

    private static func verdict(
        _ point: MonetizationAttachmentPoint,
        eligible: Bool,
        reason: MonetizationAttachmentDenialReason?,
        framing: String
    ) -> MonetizationAttachmentVerdict {
        MonetizationAttachmentVerdict(
            point: point,
            isEthicallyEligible: eligible,
            denialReason: reason,
            productFraming: framing
        )
    }
}

/// Read-only facade for future commerce wiring (Economy Clarity v1).
final class EthicalMonetizationAttachmentService {
    static let shared = EthicalMonetizationAttachmentService()

    func continueVerdict(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        EthicalMonetizationEvaluator.evaluateContinue(context: context)
    }

    func continuePresentationVerdict(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        EthicalMonetizationEvaluator.evaluateContinueForPresentation(context: context)
    }

    func rerollVerdict(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        EthicalMonetizationEvaluator.evaluateReroll(context: context)
    }

    func rerollPresentationVerdict(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        EthicalMonetizationEvaluator.evaluateRerollForPresentation(context: context)
    }

    func supporterVerdict(context: MonetizationAttachmentContext) -> MonetizationAttachmentVerdict {
        EthicalMonetizationEvaluator.evaluateSupporter(context: context)
    }

    func atelierVerdict(
        category: AtelierCosmeticCategory,
        requestedGrant: ForbiddenMonetizationGrant? = nil
    ) -> MonetizationAttachmentVerdict {
        EthicalMonetizationEvaluator.evaluateAtelier(
            category: category,
            requestedGrant: requestedGrant
        )
    }

    func attachmentCatalog() -> [MonetizationAttachmentDefinition] {
        EthicalMonetizationPolicy.attachmentCatalog
    }
}
