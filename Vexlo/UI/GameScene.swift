import SpriteKit
import UIKit

final class GameScene: SKScene {

    static let shared: GameScene = {
        let s = GameScene(size: UIScreen.main.bounds.size)
        s.scaleMode = .resizeFill
        return s
    }()

    let engine = GameEngine()
    private var cellNodes: [HexCoordinate: SKShapeNode] = [:]
    private var boardPressureSnapshot: BoardPressureSnapshot?
    private var traySlots: [SKShapeNode] = []
    private var traySlotFrames: [CGRect] = []
    private var trayPreviews: [SKNode?] = [nil, nil, nil]
    private var rerollBadges: [SKNode?] = [nil, nil, nil]
    private var dragNode: SKNode?
    var dragPiece: HexPiece?
    private var dragSlotIndex: Int = -1
    private var dragAnchor: HexCoordinate?
    private var dragHighlightedCells: Set<HexCoordinate> = []
    private var lastDragHighlightAnchor: HexCoordinate?
    private var lastDragHighlightValid: Bool?
    private var bestCaptionLabel = SKLabelNode()
    private var bestLabel = SKLabelNode()
    private var scoreCaptionLabel = SKLabelNode()
    private var scoreLabel = SKLabelNode()
    private var comboCueLabel = SKLabelNode()
    private var modeLabel = SKLabelNode()
    private var onboardingLabel = SKLabelNode()
    var utilityButton = SKShapeNode()
    var utilityMenuNode = SKNode()
    var utilityMenuBackground = SKShapeNode()
    var utilitySoundLabel = SKLabelNode()
    var utilityHapticsLabel = SKLabelNode()
    var utilitySupporterLabel = SKLabelNode()
    var utilityRestoreLabel = SKLabelNode()
    var utilityExportLabel = SKLabelNode()
    var utilityNewRunLabel = SKLabelNode()
    var utilityStudioLabel = SKLabelNode()
    private let resultOverlay = ResultOverlaySurface()
    private var lastScoreValue: Int = 0
    private var lastBestValue: Int = 0
    var isOverlayPresented = false
    var isRestarting = false
    var isPresentingContinue = false
    var isPresentingReroll = false
    var isPresentingSupporterPurchase = false
    var isPresentingNewRunConfirmation = false
    var hasFinalizedRun = false
    private var hasStartedMonetizationRun = false
    private var hasStartedAnalyticsRun = false
    var isUtilityPresented = false
    var hasRecordedContinueOfferForCurrentLoss = false
    var visibleRerollOfferSlots: Set<Int> = []
    private var flowEpoch: Int = 0
    private var lastLayoutSignature: LayoutSignature?
    private var hasBuiltScene = false
    var runStartBest: Int = 0
    var lastDailyCompletion: DailyChallengeCompletion?
    private var appliedCaptureSignature: String?
    var hasAttemptedPersistedRestore = false
    private var isShowingTransientOnboardingHint = false
    private var isPresentingDailyArrivalBeat = false
    private var hasShownChainMasteryHint = false

    private let cols = 7
    private let rows = 7
    private let pad: CGFloat = 16
    private let slotH: CGFloat = 96
    private let slotSpacing: CGFloat = 12
    private let trayBottom: CGFloat = 80
    private let hudH: CGFloat = 64
    private let boardOpticalXOffset: CGFloat = 4

    private var gridOrigin: CGPoint = .zero

    struct LayoutMetrics {
        let sideInset: CGFloat
        let topY: CGFloat
        let modeY: CGFloat
        let titleY: CGFloat
        let titleAccentY: CGFloat
        let utilityRadius: CGFloat
        let utilityCenter: CGPoint
        let utilityPanelWidth: CGFloat
        let utilityRowHeight: CGFloat
        let utilityRowHitHeight: CGFloat
        let utilityPanelTopInset: CGFloat
        let utilityPanelBottomInset: CGFloat
        let overlayCaptionOffset: CGFloat
        let overlayScoreOffset: CGFloat
        let overlayBadgeOffset: CGFloat
        let overlayDetailOffset: CGFloat
        let overlayActionsStartOffset: CGFloat
        let overlaySecondarySpacing: CGFloat
        let overlayContinueSize: CGSize
        let overlayRestartSize: CGSize
        let overlayScoreFontSize: CGFloat
        let rerollBadgeInset: CGFloat
        let boardVerticalBias: CGFloat
    }

    private struct LayoutSignature: Equatable {
        let size: CGSize
        let safeInsets: UIEdgeInsets
    }

    struct OnboardingSurfaceState {
        let isCaptureMode: Bool
        let isDailyChallenge: Bool
        let isOverlayHidden: Bool
        let isUtilityPresented: Bool
        let isInteractionLocked: Bool
        let isShowingTransientHint: Bool
        let isDraggingPiece: Bool
        let shouldShowPlacementHint: Bool
        let score: Int
        let didClearAny: Bool
        let isBoardEmpty: Bool

        var canShowFirstSessionHintSurface: Bool {
            !isCaptureMode &&
            !isDailyChallenge &&
            isOverlayHidden &&
            !isUtilityPresented &&
            !isInteractionLocked
        }

        var shouldShowPlacementHintSurface: Bool {
            canShowFirstSessionHintSurface &&
            !isShowingTransientHint &&
            !isDraggingPiece &&
            shouldShowPlacementHint &&
            score == 0 &&
            !didClearAny &&
            isBoardEmpty
        }
    }

    var layoutMetrics: LayoutMetrics {
        let safeTop = view?.safeAreaInsets.top ?? 44
        let safeLeft = view?.safeAreaInsets.left ?? 0
        let safeRight = view?.safeAreaInsets.right ?? 0
        let compactHeight = size.height < 760
        let compactWidth = size.width < 390
        let compact = compactHeight || compactWidth
        let tall = size.height >= 880
        let sideInset = max(pad, max(safeLeft, safeRight) + 16)
        let topY = size.height - safeTop - (compact ? 14 : 18)
        let utilityRadius: CGFloat = compact ? 15.5 : 16.5
        let utilityCenter = CGPoint(
            x: size.width - sideInset - utilityRadius,
            y: topY - (compact ? 17 : 19)
        )
        let utilityPanelWidth = min(max(size.width - sideInset * 2 - 28, 180), compact ? 196 : 214)
        let actionWidth = min(max(size.width - sideInset * 2 - 28, 200), compact ? 216 : 228)
        return LayoutMetrics(
            sideInset: sideInset,
            topY: topY,
            modeY: topY - (compact ? 36 : 40),
            titleY: topY - (compact ? 10 : 10),
            titleAccentY: topY - (compact ? 21 : 23),
            utilityRadius: utilityRadius,
            utilityCenter: utilityCenter,
            utilityPanelWidth: utilityPanelWidth,
            utilityRowHeight: compact ? 34 : 36,
            utilityRowHitHeight: compact ? 44 : 46,
            utilityPanelTopInset: compact ? 17 : 18,
            utilityPanelBottomInset: compact ? 14 : 16,
            overlayCaptionOffset: compact ? 98 : 112,
            overlayScoreOffset: compact ? 18 : 22,
            overlayBadgeOffset: compact ? -29 : -35,
            overlayDetailOffset: compact ? -52 : -59,
            overlayActionsStartOffset: compact ? -96 : -108,
            overlaySecondarySpacing: compact ? 18 : 19,
            overlayContinueSize: CGSize(width: actionWidth, height: compact ? 46 : 48),
            overlayRestartSize: CGSize(width: actionWidth - (compact ? 18 : 20), height: compact ? 54 : 56),
            overlayScoreFontSize: compact ? 68 : 78,
            rerollBadgeInset: compact ? 16 : 18,
            boardVerticalBias: compact ? 0.53 : (tall ? 0.5 : 0.525)
        )
    }

    private final class ResultOverlaySurface {
        let node = SKNode()
        let captionLabel = SKLabelNode()
        let scoreShadowLabel = SKLabelNode()
        let scoreLabel = SKLabelNode()
        let detailLabel = SKLabelNode()
        let badgeLabel = SKLabelNode()
        let progressLabel = SKLabelNode()
        let gamesLabel = SKLabelNode()
        let shareLabel = SKLabelNode()
        let shareIcon = SKSpriteNode()
        let continueButton = SKShapeNode()
        private let monumentAura = SKShapeNode()
        private let headingField = SKShapeNode()
        private let monumentVeil = SKShapeNode()
        private let badgeCapsule = SKShapeNode()
        private let scoreField = SKShapeNode()
        private let restartButton = SKShapeNode()
        private let restartBase = SKShapeNode()
        private let restartHalo = SKShapeNode()
        private let restartInnerStroke = SKShapeNode()
        private let restartLabel = SKLabelNode()

        func rebuild(
            in scene: SKScene,
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            node.removeFromParent()
            node.removeAllChildren()
            node.zPosition = 200
            node.isHidden = true
            node.alpha = 0
            scene.addChild(node)

            let bg = SKShapeNode(rectOf: size)
            bg.fillColor = UIColor(hex: "04050B").withAlphaComponent(0.82)
            bg.strokeColor = .clear
            bg.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
            node.addChild(bg)

            monumentAura.fillColor = UIColor(hex: "070914").withAlphaComponent(0.044)
            monumentAura.strokeColor = .clear
            monumentAura.zPosition = 200.25
            node.addChild(monumentAura)

            headingField.fillColor = UIColor.white.withAlphaComponent(0.005)
            headingField.strokeColor = .clear
            headingField.lineWidth = 0
            headingField.zPosition = 200.5
            node.addChild(headingField)

            monumentVeil.fillColor = UIColor(hex: "060811").withAlphaComponent(0.66)
            monumentVeil.strokeColor = .clear
            monumentVeil.zPosition = 200.35
            node.addChild(monumentVeil)

            scoreField.fillColor = UIColor(hex: "060914").withAlphaComponent(0.74)
            scoreField.strokeColor = UIColor.white.withAlphaComponent(0.038)
            scoreField.lineWidth = 0.8
            scoreField.zPosition = 200.36
            node.addChild(scoreField)

            badgeCapsule.fillColor = UIColor(hex: "17131C").withAlphaComponent(0.78)
            badgeCapsule.strokeColor = UIColor(hex: "C4A862").withAlphaComponent(0.24)
            badgeCapsule.lineWidth = 0.85
            badgeCapsule.zPosition = 200.40
            badgeCapsule.isHidden = true
            node.addChild(badgeCapsule)

            configureCaptionLabel(size: size, metrics: metrics, labelFactory: labelFactory)
            configureScoreLabel(size: size, metrics: metrics, labelFactory: labelFactory)
            configureBadgeLabel(size: size, metrics: metrics, labelFactory: labelFactory)
            configureDetailLabel(size: size, metrics: metrics, labelFactory: labelFactory)
            configureProgressLabel(size: size, metrics: metrics, labelFactory: labelFactory)
            configureGamesLabel(size: size, metrics: metrics, labelFactory: labelFactory)
            configureShareSurface(size: size, metrics: metrics, labelFactory: labelFactory)
            configureContinueButton(size: size, metrics: metrics, labelFactory: labelFactory)
            configureRestartButton(size: size, metrics: metrics, labelFactory: labelFactory)
        }

        func applyResultText(
            score: Int,
            caption: String,
            badge: String,
            detail: String,
            progress: String,
            isDaily: Bool,
            size: CGSize,
            metrics: LayoutMetrics,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            scoreLabel.text = "\(score)"
            scoreShadowLabel.text = "\(score)"
            captionLabel.text = caption
            badgeLabel.text = badge
            detailLabel.text = detail
            progressLabel.text = progress
            applyVisualState(isDaily: isDaily, score: score, size: size, metrics: metrics)
            relayout(size: size, metrics: metrics, isDaily: isDaily, score: score, fitLabelWidth: fitLabelWidth)
        }

        func updateGameCenterSurface(
            isResultOverlayCapture: Bool,
            isDaily: Bool,
            gamesText: String?,
            showsGames: Bool,
            showsProgress: Bool,
            canShare: Bool,
            showsContinue: Bool,
            size: CGSize,
            metrics: LayoutMetrics,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            if let gamesText {
                gamesLabel.text = gamesText
            }
            let shouldShowGames = GameScene.shouldShowResultGames(
                isResultOverlayCapture: isResultOverlayCapture,
                showsGames: showsGames,
                canShare: canShare,
                showsContinue: showsContinue
            )
            let shouldShowProgress = GameScene.shouldShowResultProgress(
                showsProgress: showsProgress,
                progressText: progressLabel.text
            )
            gamesLabel.isHidden = !shouldShowGames
            gamesLabel.alpha = shouldShowGames ? (isDaily ? 0.78 : 0.74) : 0
            progressLabel.isHidden = !shouldShowProgress
            progressLabel.alpha = shouldShowProgress ? (isDaily ? 0.84 : 0.80) : 0
            relayout(size: size, metrics: metrics, isDaily: isDaily, score: Int(scoreLabel.text ?? "") ?? 0, fitLabelWidth: fitLabelWidth)
        }

        func updateShareVisibility(
            canShare: Bool,
            showsContinue: Bool,
            size: CGSize,
            metrics: LayoutMetrics,
            isDaily: Bool,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            shareLabel.text = VexloStrings.Overlay.shareResult
            let shouldShowShare = GameScene.shouldShowResultShare(canShare: canShare, showsContinue: showsContinue)
            shareLabel.isHidden = !shouldShowShare
            shareLabel.alpha = shouldShowShare ? 0.82 : 0
            shareIcon.isHidden = !shouldShowShare
            shareIcon.alpha = shouldShowShare ? 0.82 : 0
            relayout(size: size, metrics: metrics, isDaily: isDaily, score: Int(scoreLabel.text ?? "") ?? 0, fitLabelWidth: fitLabelWidth)
        }

        func updateContinueVisibility(
            isVisible: Bool,
            size: CGSize,
            metrics: LayoutMetrics,
            isDaily: Bool,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            continueButton.isHidden = !isVisible
            continueButton.alpha = isVisible ? 0.96 : 0
            relayout(size: size, metrics: metrics, isDaily: isDaily, score: Int(scoreLabel.text ?? "") ?? 0, fitLabelWidth: fitLabelWidth)
        }

        func present(prefersReducedMotion: Bool) {
            node.removeAllActions()
            node.isHidden = false
            guard !prefersReducedMotion else {
                node.alpha = 1
                node.setScale(1)
                return
            }
            node.alpha = 0
            node.setScale(1.02)
            node.run(.group([
                .fadeIn(withDuration: 0.16),
                .scale(to: 1.0, duration: 0.16)
            ]))
        }

        func hide() {
            node.removeAllActions()
            node.alpha = 0
            node.setScale(1)
            node.isHidden = true
            gamesLabel.isHidden = true
            shareIcon.isHidden = true
            shareLabel.isHidden = true
        }

        private func configureCaptionLabel(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory(VexloStrings.Overlay.gameOver, 19, .white, 0.64, .center, true),
                into: captionLabel
            )
            captionLabel.fontName = "SFProDisplay-Regular"
            captionLabel.zPosition = 200.43
            captionLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayCaptionOffset)
            node.addChild(captionLabel)
        }

        private func configureScoreLabel(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory("0", metrics.overlayScoreFontSize, .white, 1, .center, true),
                into: scoreLabel
            )
            copyLabel(
                from: labelFactory("0", metrics.overlayScoreFontSize, UIColor(hex: "111528"), 0.18, .center, true),
                into: scoreShadowLabel
            )
            let scoreFontCandidates = [
                "SFProRounded-Black",
                "SFProRounded-Heavy",
                "SFProDisplay-Black",
                "SFProDisplay-Heavy",
                ".SFUI-Black",
                ".SFUI-Heavy",
                "SFProRounded-Bold",
                "SFProDisplay-Bold"
            ]
            let scoreFont = scoreFontCandidates.first { UIFont(name: $0, size: 1) != nil } ?? "SFProDisplay-Bold"
            scoreShadowLabel.fontName = scoreFont
            scoreShadowLabel.zPosition = 200.38
            scoreShadowLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayScoreOffset)
            node.addChild(scoreShadowLabel)
            scoreLabel.fontName = scoreFont
            scoreLabel.zPosition = 200.39
            scoreLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayScoreOffset)
            node.addChild(scoreLabel)
        }

        private func configureBadgeLabel(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory("", 11.4, UIColor(hex: "6C5CE7"), 0.82, .center, true),
                into: badgeLabel
            )
            badgeLabel.fontName = "SFProDisplay-Semibold"
            badgeLabel.verticalAlignmentMode = .center
            badgeLabel.zPosition = 200.41
            badgeLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayBadgeOffset)
            node.addChild(badgeLabel)
        }

        private func configureDetailLabel(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory("", 14.5, .white, 0.66, .center, false),
                into: detailLabel
            )
            detailLabel.fontName = "SFProDisplay-Semibold"
            detailLabel.zPosition = 200.42
            detailLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayDetailOffset)
            node.addChild(detailLabel)
        }

        private func configureProgressLabel(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory(VexloStrings.Overlay.gameCenter, 12.5, .white, 0.5, .center, true),
                into: progressLabel
            )
            progressLabel.fontName = "SFProDisplay-Medium"
            progressLabel.name = "progress"
            progressLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset)
            node.addChild(progressLabel)
        }

        private func configureGamesLabel(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory("", 12, .white, 0.44, .center, true),
                into: gamesLabel
            )
            gamesLabel.fontName = "SFProDisplay-Medium"
            gamesLabel.name = "games"
            gamesLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - metrics.overlaySecondarySpacing)
            gamesLabel.isHidden = true
            node.addChild(gamesLabel)
        }

        private func configureShareSurface(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            copyLabel(
                from: labelFactory("", 13, UIColor(hex: "F4F3FF"), 0.72, .center, true),
                into: shareLabel
            )
            shareLabel.name = "share"
            shareLabel.fontSize = 12.5
            shareLabel.fontName = "SFProDisplay-Semibold"
            shareLabel.fontColor = UIColor(hex: "D5DCF8").withAlphaComponent(0.72)
            shareLabel.text = VexloStrings.Overlay.shareResult
            shareLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - metrics.overlaySecondarySpacing * 2)
            shareLabel.zPosition = 202
            shareLabel.isHidden = true

            if let image = UIImage(
                systemName: "square.and.arrow.up",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .medium)
            )?.withTintColor(UIColor(hex: "D7DEEF"), renderingMode: .alwaysOriginal) {
                shareIcon.texture = SKTexture(image: image)
                shareIcon.size = image.size
            }
            shareIcon.zPosition = shareLabel.zPosition
            shareIcon.isHidden = true

            node.addChild(shareIcon)
            node.addChild(shareLabel)
        }

        private func configureContinueButton(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            continueButton.path = CGPath(
                roundedRect: CGRect(
                    x: -metrics.overlayContinueSize.width * 0.5,
                    y: -metrics.overlayContinueSize.height * 0.5,
                    width: metrics.overlayContinueSize.width,
                    height: metrics.overlayContinueSize.height
                ),
                cornerWidth: metrics.overlayContinueSize.height * 0.5,
                cornerHeight: metrics.overlayContinueSize.height * 0.5,
                transform: nil
            )
            continueButton.name = "continue"
            continueButton.fillColor = UIColor(hex: "14142A").withAlphaComponent(0.92)
            continueButton.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.12)
            continueButton.lineWidth = 1
            continueButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - 60)
            continueButton.zPosition = 201
            continueButton.isHidden = true
            continueButton.removeAllChildren()

            let continueLabel = labelFactory(VexloStrings.Overlay.continueRun, 14, .white, 0.9, .center, true)
            continueLabel.verticalAlignmentMode = .center
            continueLabel.position = .zero
            continueButton.addChild(continueLabel)
            node.addChild(continueButton)
        }

        private func configureRestartButton(
            size: CGSize,
            metrics: LayoutMetrics,
            labelFactory: (String, CGFloat, UIColor, CGFloat, SKLabelHorizontalAlignmentMode, Bool) -> SKLabelNode
        ) {
            restartButton.name = "restart"
            restartButton.fillColor = UIColor(hex: "6964EA").withAlphaComponent(0.975)
            restartButton.strokeColor = UIColor(hex: "C5CBFF").withAlphaComponent(0.28)
            restartButton.lineWidth = 1.1
            restartButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - 118)
            restartButton.zPosition = 201
            restartButton.removeAllChildren()
            restartBase.fillColor = UIColor(hex: "101428").withAlphaComponent(0.92)
            restartBase.strokeColor = .clear
            restartBase.zPosition = -2
            restartButton.addChild(restartBase)
            restartHalo.fillColor = UIColor(hex: "9A99FF").withAlphaComponent(0.16)
            restartHalo.strokeColor = .clear
            restartHalo.zPosition = -1
            restartButton.addChild(restartHalo)
            restartInnerStroke.fillColor = .clear
            restartInnerStroke.strokeColor = UIColor.white.withAlphaComponent(0.132)
            restartInnerStroke.lineWidth = 0.9
            restartInnerStroke.zPosition = 1
            restartButton.addChild(restartInnerStroke)
            copyLabel(
                from: labelFactory(VexloStrings.Overlay.playAgain, 22, UIColor(hex: "F5F4FB"), 1, .center, true),
                into: restartLabel
            )
            restartLabel.fontName = "SFProDisplay-Semibold"
            restartLabel.verticalAlignmentMode = .center
            restartLabel.position = .zero
            restartLabel.zPosition = 2
            restartButton.addChild(restartLabel)
            node.addChild(restartButton)
        }

        private func copyLabel(from source: SKLabelNode, into target: SKLabelNode) {
            target.text = source.text
            target.fontName = source.fontName
            target.fontSize = source.fontSize
            target.fontColor = source.fontColor
            target.alpha = source.alpha
            target.horizontalAlignmentMode = source.horizontalAlignmentMode
            target.verticalAlignmentMode = source.verticalAlignmentMode
            target.zPosition = source.zPosition
        }

        private func masterScaleX(for size: CGSize) -> CGFloat {
            size.width / 440
        }

        private func masterScaleY(for size: CGSize) -> CGFloat {
            size.height / 956
        }

        private func masterFontScale(for size: CGSize) -> CGFloat {
            min(masterScaleX(for: size), masterScaleY(for: size))
        }

        private func masterY(_ value: CGFloat, in size: CGSize) -> CGFloat {
            size.height - size.height * (value / 956)
        }

        private func masterTopCenterY(_ top: CGFloat, height: CGFloat, in size: CGSize) -> CGFloat {
            let scaleY = masterScaleY(for: size)
            return size.height - ((top + height * 0.5) * scaleY)
        }

        private func masterRect(_ rect: CGRect, in size: CGSize) -> CGRect {
            let scaleX = masterScaleX(for: size)
            let scaleY = masterScaleY(for: size)
            return CGRect(
                x: rect.origin.x * scaleX,
                y: size.height - ((rect.origin.y + rect.height) * scaleY),
                width: rect.width * scaleX,
                height: rect.height * scaleY
            )
        }

        private func applyVisualState(isDaily: Bool, score: Int, size: CGSize, metrics: LayoutMetrics) {
            let isSpecial = badgeLabel.text?.isEmpty == false
            let isEditorialTerminal = isDaily || isSpecial
            let isWeakScoreTerminal = !isEditorialTerminal && score < 10
            let isZeroScoreTerminal = isWeakScoreTerminal && score == 0
            let fontScale = masterFontScale(for: size)
            let lowScoreScale: CGFloat
            if isSpecial {
                lowScoreScale = 1
            } else if isZeroScoreTerminal {
                lowScoreScale = 1.08
            } else if isWeakScoreTerminal {
                lowScoreScale = 1.0
            } else if score == 0 {
                lowScoreScale = 0.82
            } else if score < 10 {
                lowScoreScale = 0.88
            } else if score < 25 {
                lowScoreScale = 0.94
            } else {
                lowScoreScale = 1
            }
            let detailScale: CGFloat = isZeroScoreTerminal ? 0.84 : (isWeakScoreTerminal ? 0.88 : 0.86)

            captionLabel.fontName = "SFProDisplay-Regular"
            captionLabel.fontColor = UIColor(hex: "ECEEF7").withAlphaComponent(0.95)
            captionLabel.alpha = 1.0
            captionLabel.fontSize = 27 * fontScale
            detailLabel.fontName = "SFProDisplay-Medium"
            detailLabel.fontColor = UIColor(hex: "E8ECF4").withAlphaComponent(0.92)
            detailLabel.alpha = isWeakScoreTerminal ? 0.82 : 0.88
            detailLabel.fontSize = 17.6 * fontScale * detailScale
            scoreLabel.fontSize = 98 * fontScale * lowScoreScale
            scoreShadowLabel.fontSize = 98 * fontScale * lowScoreScale
            scoreShadowLabel.alpha = isZeroScoreTerminal ? 0.14 : 0.18
            scoreLabel.alpha = 1.0
            let isNormalHistoryLineVisible = !isDaily && !(progressLabel.text?.isEmpty ?? true)
            progressLabel.fontName = "SFProDisplay-Semibold"
            progressLabel.fontSize = 13.2 * fontScale
            progressLabel.fontColor = UIColor(hex: "DCE2EF")
            progressLabel.alpha = isEditorialTerminal ? 0.88 : (isNormalHistoryLineVisible ? 0.84 : 0.70)
            gamesLabel.fontName = "SFProDisplay-Semibold"
            gamesLabel.fontSize = 13.2 * fontScale
            gamesLabel.fontColor = UIColor(hex: "D7DEED")
            gamesLabel.alpha = gamesLabel.isHidden ? 0 : 0.82
            shareLabel.fontName = "SFProDisplay-Semibold"
            shareLabel.fontSize = 13.6 * fontScale
            shareLabel.fontColor = UIColor(hex: "DDE4F2").withAlphaComponent(0.82)
            shareIcon.alpha = 0.82

            if isDaily {
                badgeLabel.fontName = "SFProDisplay-Semibold"
                badgeLabel.fontColor = UIColor(hex: "D3B46D")
                badgeLabel.alpha = 0.95
                badgeLabel.fontSize = 12.8 * fontScale
                scoreLabel.fontColor = UIColor(hex: "F2F1F6")
            } else if isSpecial {
                badgeLabel.fontName = "SFProDisplay-Semibold"
                badgeLabel.fontColor = UIColor(hex: "D3B46D")
                badgeLabel.alpha = 0.95
                badgeLabel.fontSize = 12.8 * fontScale
                scoreLabel.fontColor = UIColor(hex: "F2F1F6")
            } else {
                badgeLabel.fontName = "SFProDisplay-Semibold"
                badgeLabel.fontColor = UIColor(hex: "D3B46D")
                badgeLabel.alpha = 0
                badgeLabel.fontSize = 12.8 * fontScale
                scoreLabel.fontColor = UIColor(hex: "F2F1F6")
            }
        }

        private func relayout(
            size: CGSize,
            metrics: LayoutMetrics,
            isDaily: Bool,
            score: Int,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            let isCompactHeight = size.height < 760
            let isWeakScoreTerminal = !isDaily && (badgeLabel.text?.isEmpty ?? true) && score < 10
            let isZeroScoreTerminal = isWeakScoreTerminal && score == 0
            let hasHonorBadge = !(badgeLabel.text?.isEmpty ?? true)
            fitLabelWidth(progressLabel, size.width - metrics.sideInset * 2 - 24, 0.78)
            fitLabelWidth(gamesLabel, size.width - metrics.sideInset * 2 - 24, 0.78)
            fitLabelWidth(shareLabel, size.width - metrics.sideInset * 2 - 24, 0.78)
            fitLabelWidth(detailLabel, size.width - metrics.sideInset * 2 - 16, 0.8)
            fitLabelWidth(badgeLabel, size.width - metrics.sideInset * 2 - 16, 0.8)
            let centerX = size.width * 0.5
            let fontScale = masterFontScale(for: size)
            let scaleX = masterScaleX(for: size)
            let scaleY = masterScaleY(for: size)
            let headingY = masterY(316, in: size)
            let badgeY = masterY(352, in: size)
            let scoreY = masterY(436, in: size)
            let detailY = masterY(524, in: size)
            let shareActionHeight = max(shareLabel.fontSize * 1.05, 16 * fontScale)
            let hasSupportContent = !progressLabel.isHidden || !gamesLabel.isHidden
            let restartSize = CGSize(width: 214 * masterScaleX(for: size), height: 78 * masterScaleY(for: size))
            let desiredRestartCenterY = masterTopCenterY(804, height: 78, in: size)
            let trayTop: CGFloat = 80 + 96 + 24
            let minimumRestartTop = trayTop + (isCompactHeight ? 22 : 12)
            let restartCenterY = max(desiredRestartCenterY, minimumRestartTop + restartSize.height * 0.5)
            let restartTopEdge = restartCenterY + restartSize.height * 0.5
            let minimumShareGap = (isCompactHeight ? 22 : 28) * masterScaleY(for: size)
            let minimumShareCenterY = restartTopEdge + minimumShareGap + shareActionHeight * 0.5
            let badgeDropY = hasHonorBadge ? (2 * fontScale) : 0
            let scoreLiftY = (isZeroScoreTerminal ? (10 * fontScale) : (isWeakScoreTerminal ? (7 * fontScale) : (4 * fontScale))) + (hasHonorBadge ? (2 * fontScale) : 0)
            let detailLiftY = (isZeroScoreTerminal ? (13 * fontScale) : (isWeakScoreTerminal ? (10 * fontScale) : (8 * fontScale))) + (hasHonorBadge ? (3 * fontScale) : (2 * fontScale))

            captionLabel.position = CGPoint(x: centerX, y: headingY)
            badgeLabel.position = CGPoint(x: centerX + (0.2 * fontScale), y: badgeY - badgeDropY + (0.35 * fontScale))
            badgeCapsule.isHidden = true
            if hasHonorBadge {
                let text = badgeLabel.text ?? ""
                let badgeTextWidth = badgeLabel.fontSize * CGFloat(text.count) * 0.47
                let capsuleWidth = max(92 * scaleX, badgeTextWidth + 20 * fontScale)
                let capsuleHeight = 16 * scaleY
                badgeCapsule.path = CGPath(
                    roundedRect: CGRect(
                        x: -capsuleWidth * 0.5,
                        y: -capsuleHeight * 0.5,
                        width: capsuleWidth,
                        height: capsuleHeight
                    ),
                    cornerWidth: 3 * fontScale,
                    cornerHeight: 3 * fontScale,
                    transform: nil
                )
                badgeCapsule.position = CGPoint(x: centerX, y: badgeLabel.position.y - badgeLabel.fontSize * 0.12)
                badgeCapsule.fillColor = UIColor(hex: "17121A").withAlphaComponent(isDaily ? 0.50 : 0.44)
                badgeCapsule.strokeColor = UIColor(hex: "C6AB68").withAlphaComponent(isDaily ? 0.24 : 0.18)
                badgeCapsule.isHidden = false
            } else {
                badgeCapsule.isHidden = true
            }

            scoreLabel.position = CGPoint(x: centerX, y: scoreY + scoreLiftY)
            scoreShadowLabel.position = CGPoint(
                x: scoreLabel.position.x + (1.2 * fontScale),
                y: scoreLabel.position.y - (1.8 * fontScale)
            )

            let scoreDigits = max(1, String(max(0, score)).count)
            let estimatedScoreWidth = scoreLabel.fontSize * CGFloat(scoreDigits) * 0.72
            let scoreFieldWidth = min(estimatedScoreWidth + 72 * fontScale, 300 * scaleX)
            let scoreFieldHeight = scoreLabel.fontSize * 0.66 + 10 * fontScale
            scoreField.path = CGPath(
                roundedRect: CGRect(
                    x: -scoreFieldWidth * 0.5,
                    y: -scoreFieldHeight * 0.5,
                    width: scoreFieldWidth,
                    height: scoreFieldHeight
                ),
                cornerWidth: 40 * fontScale,
                cornerHeight: 40 * fontScale,
                transform: nil
            )
            scoreField.position = CGPoint(x: centerX, y: scoreLabel.position.y - scoreLabel.fontSize * 0.01)
            scoreField.fillColor = UIColor(hex: "060914").withAlphaComponent(isZeroScoreTerminal ? 0.46 : (isWeakScoreTerminal ? 0.38 : 0.32))
            scoreField.strokeColor = UIColor.white.withAlphaComponent(isZeroScoreTerminal ? 0.012 : 0.008)
            detailLabel.position = CGPoint(x: centerX, y: detailY + detailLiftY + (2 * fontScale))

            let supportTopGap = hasSupportContent ? (44 * fontScale) : (40 * fontScale)
            var supportCenterY = detailLabel.position.y - supportTopGap
            let supportUpperOffset = 7 * fontScale
            let supportLowerOffset = 7 * fontScale
            let supportToShareGap = (isCompactHeight ? 24 : 28) * fontScale
            let supportSingleLineDescent = 8 * fontScale
            let supportDoubleLineDescent = 10 * fontScale
            let shareToRestartGap = (isCompactHeight ? 22 : 28) * scaleY
            let shareLabelOpticalOffset = shareLabel.fontSize * 0.12

            let supportLineBottomOffset: CGFloat = (!progressLabel.isHidden && !gamesLabel.isHidden) ? supportDoubleLineDescent : supportSingleLineDescent
            let desiredSupportBottomY = minimumShareCenterY + shareActionHeight * 0.5 + supportToShareGap
            let actualSupportBottomY = supportCenterY - supportLineBottomOffset
            if actualSupportBottomY < desiredSupportBottomY {
                supportCenterY += desiredSupportBottomY - actualSupportBottomY
            }

            if !progressLabel.isHidden && !gamesLabel.isHidden {
                progressLabel.position = CGPoint(x: centerX, y: supportCenterY + supportUpperOffset)
                gamesLabel.position = CGPoint(x: centerX, y: supportCenterY - supportLowerOffset)
            } else if !progressLabel.isHidden {
                progressLabel.position = CGPoint(x: centerX, y: supportCenterY)
                gamesLabel.position = CGPoint(x: centerX, y: supportCenterY - (12 * fontScale))
            } else if !gamesLabel.isHidden {
                gamesLabel.position = CGPoint(x: centerX, y: supportCenterY)
                progressLabel.position = CGPoint(x: centerX, y: supportCenterY + (12 * fontScale))
            } else {
                progressLabel.position = CGPoint(x: centerX, y: supportCenterY)
                gamesLabel.position = CGPoint(x: centerX, y: supportCenterY - (12 * fontScale))
            }

            if !shareLabel.isHidden {
                let supportBottomY: CGFloat
                if !progressLabel.isHidden && !gamesLabel.isHidden {
                    supportBottomY = min(progressLabel.position.y, gamesLabel.position.y) - supportDoubleLineDescent
                } else if !progressLabel.isHidden {
                    supportBottomY = progressLabel.position.y - supportSingleLineDescent
                } else if !gamesLabel.isHidden {
                    supportBottomY = gamesLabel.position.y - supportSingleLineDescent
                } else {
                    supportBottomY = detailLabel.position.y - (30 * fontScale)
                }
                let desiredShareCenterY = supportBottomY - supportToShareGap - shareActionHeight * 0.5
                let shareCenterY = max(minimumShareCenterY, desiredShareCenterY)
                let shareText = shareLabel.text ?? ""
                let shareLabelWidth = max(shareLabel.frame.width, shareLabel.fontSize * CGFloat(shareText.count) * 0.44)
                let shareIconWidth = shareIcon.size.width * 0.88
                let shareIconGap = 7 * fontScale
                let shareGroupWidth = shareIconWidth + shareIconGap + shareLabelWidth
                let shareLeftEdge = centerX - shareGroupWidth * 0.5
                shareIcon.position = CGPoint(
                    x: shareLeftEdge + shareIconWidth * 0.5,
                    y: shareCenterY + shareLabel.fontSize * 0.02
                )
                shareLabel.position = CGPoint(
                    x: shareLeftEdge + shareIconWidth + shareIconGap + shareLabelWidth * 0.5,
                    y: shareCenterY + shareLabelOpticalOffset
                )
                shareIcon.setScale(0.88)
                shareIcon.isHidden = false
            }

            if shareLabel.isHidden {
                shareIcon.isHidden = true
            }

            let fallbackShareCenterY = minimumShareCenterY
            continueButton.position = CGPoint(x: centerX, y: fallbackShareCenterY - shareToRestartGap)

            restartButton.path = CGPath(
                roundedRect: CGRect(
                    x: -restartSize.width * 0.5,
                    y: -restartSize.height * 0.5,
                    width: restartSize.width,
                    height: restartSize.height
                ),
                cornerWidth: 24 * fontScale,
                cornerHeight: 24 * fontScale,
                transform: nil
            )
            restartButton.position = CGPoint(x: centerX, y: restartCenterY)
            restartButton.fillColor = UIColor(hex: "635EE6")
            restartButton.strokeColor = UIColor(hex: "B5BCFF").withAlphaComponent(0.23)
            restartButton.lineWidth = 1.05

            restartBase.path = CGPath(
                roundedRect: CGRect(
                    x: -restartSize.width * 0.5 + (8 * masterScaleX(for: size)),
                    y: -restartSize.height * 0.5 - (12 * masterScaleY(for: size)),
                    width: restartSize.width - (16 * masterScaleX(for: size)),
                    height: restartSize.height + (10 * masterScaleY(for: size))
                ),
                cornerWidth: 21 * fontScale,
                cornerHeight: 21 * fontScale,
                transform: nil
            )
            restartHalo.path = CGPath(
                roundedRect: CGRect(
                    x: -restartSize.width * 0.5 - (4 * masterScaleX(for: size)),
                    y: -restartSize.height * 0.5 - (3 * masterScaleY(for: size)),
                    width: restartSize.width + (8 * masterScaleX(for: size)),
                    height: restartSize.height + (6 * masterScaleY(for: size))
                ),
                cornerWidth: 27 * fontScale,
                cornerHeight: 27 * fontScale,
                transform: nil
            )
            restartInnerStroke.path = CGPath(
                roundedRect: CGRect(
                    x: -restartSize.width * 0.5 + (2 * masterScaleX(for: size)),
                    y: -restartSize.height * 0.5 + (2 * masterScaleY(for: size)),
                    width: restartSize.width - (4 * masterScaleX(for: size)),
                    height: restartSize.height - (4 * masterScaleY(for: size))
                ),
                cornerWidth: 22 * fontScale,
                cornerHeight: 22 * fontScale,
                transform: nil
            )
            restartLabel.fontSize = 22 * fontScale
            restartLabel.position = CGPoint(x: 0, y: 2.1 * fontScale)

            // Keep the monument shell anchored to the live caption/detail stack.
            let monumentFieldLeading: CGFloat = 118
            let monumentFieldWidth: CGFloat = 204
            let monumentFieldTopInset: CGFloat = isZeroScoreTerminal ? 28 : 24
            let monumentFieldBottomInset: CGFloat = isWeakScoreTerminal ? 8 : 6
            let monumentOuterHorizontalPad: CGFloat = isWeakScoreTerminal ? 62 : 58
            let monumentOuterVerticalPad: CGFloat = isZeroScoreTerminal ? 66 : (isWeakScoreTerminal ? 62 : 56)
            let monumentVeilLeading: CGFloat = 44
            let monumentVeilWidth: CGFloat = 352
            let monumentVeilTopInset: CGFloat = isWeakScoreTerminal ? 46 : 40
            let monumentVeilBottomInset: CGFloat = hasSupportContent ? 84 : 72
            let monumentFieldCornerRadius: CGFloat = 84
            let monumentAuraCornerRadius: CGFloat = 182
            let monumentVeilCornerRadius: CGFloat = 192
            let monumentFieldTop = captionLabel.position.y + (monumentFieldTopInset * scaleY)
            let monumentFieldBottom = detailLabel.position.y + (monumentFieldBottomInset * scaleY)
            let monumentFieldRect = CGRect(
                x: monumentFieldLeading * scaleX,
                y: monumentFieldBottom,
                width: monumentFieldWidth * scaleX,
                height: monumentFieldTop - monumentFieldBottom
            )
            let monumentOuterRect = monumentFieldRect.insetBy(
                dx: -(monumentOuterHorizontalPad * scaleX),
                dy: -(monumentOuterVerticalPad * scaleY)
            )
            let monumentVeilTop = captionLabel.position.y + (monumentVeilTopInset * scaleY)
            let monumentVeilBottom = detailLabel.position.y + (monumentVeilBottomInset * scaleY)
            let monumentVeilRect = CGRect(
                x: monumentVeilLeading * scaleX,
                y: monumentVeilBottom,
                width: monumentVeilWidth * scaleX,
                height: monumentVeilTop - monumentVeilBottom
            )

            headingField.path = CGPath(
                roundedRect: monumentFieldRect.offsetBy(dx: -monumentFieldRect.midX, dy: -monumentFieldRect.midY),
                cornerWidth: monumentFieldCornerRadius * fontScale,
                cornerHeight: monumentFieldCornerRadius * fontScale,
                transform: nil
            )
            headingField.position = CGPoint(x: monumentFieldRect.midX, y: monumentFieldRect.midY)

            monumentAura.path = CGPath(
                roundedRect: monumentOuterRect.offsetBy(dx: -monumentOuterRect.midX, dy: -monumentOuterRect.midY),
                cornerWidth: monumentAuraCornerRadius * fontScale,
                cornerHeight: monumentAuraCornerRadius * fontScale,
                transform: nil
            )
            monumentAura.position = CGPoint(x: monumentOuterRect.midX, y: monumentOuterRect.midY)

            monumentVeil.path = CGPath(
                roundedRect: monumentVeilRect.offsetBy(dx: -monumentVeilRect.midX, dy: -monumentVeilRect.midY),
                cornerWidth: monumentVeilCornerRadius * fontScale,
                cornerHeight: monumentVeilCornerRadius * fontScale,
                transform: nil
            )
            monumentVeil.position = CGPoint(x: monumentVeilRect.midX, y: monumentVeilRect.midY)

            monumentAura.fillColor = UIColor(hex: "070914").withAlphaComponent(isZeroScoreTerminal ? 0.088 : (isWeakScoreTerminal ? 0.080 : 0.072))
            monumentVeil.fillColor = UIColor(hex: "060811").withAlphaComponent(isZeroScoreTerminal ? 0.74 : (isWeakScoreTerminal ? 0.70 : 0.66))

            if isCompactHeight {
                headingField.fillColor = UIColor.white.withAlphaComponent(isWeakScoreTerminal ? 0.0038 : 0.0026)
            } else {
                headingField.fillColor = UIColor.white.withAlphaComponent(isWeakScoreTerminal ? 0.0044 : 0.003)
            }
            headingField.strokeColor = .clear
        }
    }

    private var overlayNode: SKNode { resultOverlay.node }
    private var overlayCaptionLabel: SKLabelNode { resultOverlay.captionLabel }
    private var overlayScoreLabel: SKLabelNode { resultOverlay.scoreLabel }
    private var overlayDetailLabel: SKLabelNode { resultOverlay.detailLabel }
    private var overlayBadgeLabel: SKLabelNode { resultOverlay.badgeLabel }
    private var overlayProgressLabel: SKLabelNode { resultOverlay.progressLabel }
    private var overlayGamesLabel: SKLabelNode { resultOverlay.gamesLabel }
    private var overlayShareLabel: SKLabelNode { resultOverlay.shareLabel }
    private var overlayContinueButton: SKShapeNode { resultOverlay.continueButton }

    var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    var isInteractionLocked: Bool {
        isRestarting || isPresentingContinue || isPresentingReroll || isPresentingSupporterPurchase || isPresentingNewRunConfirmation
    }

    var canShowUtilityAffordance: Bool {
        (!LaunchSupport.shared.isCaptureMode || LaunchSupport.shared.isUtilitySurfaceCapture) &&
        overlayNode.isHidden &&
        !isOverlayPresented
    }

    private var isPublicEditorialCapture: Bool {
        LaunchSupport.shared.isCaptureMode && !LaunchSupport.shared.isInternalCapture
    }

    private var onboardingSurfaceState: OnboardingSurfaceState {
        OnboardingSurfaceState(
            isCaptureMode: LaunchSupport.shared.isCaptureMode,
            isDailyChallenge: engine.isDailyChallenge,
            isOverlayHidden: overlayNode.isHidden,
            isUtilityPresented: isUtilityPresented,
            isInteractionLocked: isInteractionLocked,
            isShowingTransientHint: isShowingTransientOnboardingHint,
            isDraggingPiece: dragPiece != nil,
            shouldShowPlacementHint: OnboardingService.shared.shouldShowPlacementHint,
            score: engine.scoreEngine.score,
            didClearAny: engine.didClearAny,
            isBoardEmpty: engine.board.allCoordinates().allSatisfy { engine.board.color(at: $0) == nil }
        )
    }

    private var canShowFirstSessionHintSurface: Bool {
        onboardingSurfaceState.canShowFirstSessionHintSurface
    }

    private var shouldShowPlacementHintSurface: Bool {
        onboardingSurfaceState.shouldShowPlacementHintSurface
    }

    private var terminalOverlayOwnsResultContext: Bool {
        engine.isGameOver || isOverlayPresented || !resultOverlay.node.isHidden
    }

    override func didMove(to view: SKView) {
        if size != view.bounds.size {
            size = view.bounds.size
        }
        layoutScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard size.width > 1, size.height > 1 else { return }
        layoutScene()
    }

    override func didFinishUpdate() {
        super.didFinishUpdate()
        syncCaptureComboReviewCueIfNeeded()
    }

    private func layoutScene() {
        let safeInsets = view?.safeAreaInsets ?? UIEdgeInsets(top: 44, left: 0, bottom: 0, right: 0)
        let signature = LayoutSignature(size: size, safeInsets: safeInsets)
        DailyChallengeService.shared.refreshForCurrentDay()
        GameCenterService.shared.onRouteRequest = { [weak self] route in
            self?.applyGameCenterRoute(route)
        }
        SystemEntryService.shared.onRouteRequest = { [weak self] route in
            self?.applySystemEntryRoute(route)
        }
        backgroundColor = UIColor(hex: "080810")
        if hasBuiltScene, lastLayoutSignature == signature {
            if applyCaptureModeIfNeeded() {
                return
            }
            syncAll()
            if !LaunchSupport.shared.isCaptureMode,
               let route = GameCenterService.shared.consumePendingRoute() {
                applyGameCenterRoute(route)
            }
            return
        }
        hasBuiltScene = true
        lastLayoutSignature = signature
        resetVisualActions()
        computeOrigin()
        buildAtmosphere()
        buildHUD()
        buildUtilitySurface()
        buildGrid()
        buildTray()
        buildOnboardingSurface()
        buildOverlay()
        if applyCaptureModeIfNeeded() {
            return
        }
        if restorePersistedRunIfNeeded() {
            if let route = GameCenterService.shared.consumePendingRoute() {
                applyGameCenterRoute(route)
            }
            return
        }
        startMonetizationRunIfNeeded()
        startAnalyticsRunIfNeeded()
        runStartBest = currentDisplayedBest()
        syncAll()
        if !LaunchSupport.shared.isCaptureMode,
           let route = GameCenterService.shared.consumePendingRoute() {
            applyGameCenterRoute(route)
        }
    }

    private func computeOrigin() {
        let safe = view?.safeAreaInsets.top ?? 44
        let metrics = layoutMetrics
        let bounds = HexGeometry.boardBounds(cols: cols, rows: rows)
        let trayTop = trayBottom + slotH + 24
        let hudBottom = size.height - safe - hudH
        let availableH = hudBottom - trayTop
        let centerY = trayTop + availableH * metrics.boardVerticalBias
        gridOrigin = CGPoint(
            x: floor(size.width * 0.5 - bounds.midX + boardOpticalXOffset),
            y: centerY - bounds.height * 0.5 - bounds.minY
        )
    }

    private func buildHUD() {
        children.filter { $0.name?.hasPrefix("hud.") == true }.forEach { $0.removeFromParent() }
        let metrics = layoutMetrics

        bestCaptionLabel = label(VexloStrings.HUD.best, size: 10.75, alpha: 0.31, align: .left)
        bestCaptionLabel.name = "hud.bestCaption"
        bestCaptionLabel.position = CGPoint(x: metrics.sideInset, y: metrics.topY)
        addChild(bestCaptionLabel)

        bestLabel = label("0", size: 28, color: UIColor(hex: "6C5CE7"), align: .left, weight: true)
        bestLabel.name = "hud.best"
        let roundedFonts = ["SFProRounded-Bold", "SFProRounded-Semibold"]
        let resolvedFont = roundedFonts.first { UIFont(name: $0, size: 1) != nil } ?? "SFProDisplay-Bold"
        bestLabel.fontName = resolvedFont
        bestLabel.position = CGPoint(x: metrics.sideInset, y: metrics.topY - 19)
        addChild(bestLabel)

        let title = label(VexloStrings.HUD.title, size: 18, color: UIColor(hex: "F4F3FF"), align: .center, weight: true)
        title.name = "hud.title"
        title.position = CGPoint(x: size.width * 0.5, y: metrics.titleY)
        addChild(title)

        let accent = SKShapeNode(rectOf: CGSize(width: size.height < 760 ? 24 : 29, height: 2), cornerRadius: 1)
        accent.name = "hud.titleAccent"
        accent.fillColor = UIColor(hex: "7A74F7").withAlphaComponent(0.3)
        accent.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.08)
        accent.lineWidth = 1
        accent.position = CGPoint(x: size.width * 0.5, y: metrics.titleAccentY)
        addChild(accent)

        scoreCaptionLabel = label(VexloStrings.HUD.score, size: 10.75, alpha: 0.31, align: .right)
        scoreCaptionLabel.name = "hud.scoreCaption"
        scoreCaptionLabel.position = CGPoint(x: size.width - metrics.sideInset - metrics.utilityRadius * 2 - 12, y: metrics.topY)
        addChild(scoreCaptionLabel)

        scoreLabel = label("0", size: 28, color: .white, align: .right, weight: true)
        scoreLabel.name = "hud.score"
        scoreLabel.fontName = resolvedFont
        scoreLabel.position = CGPoint(x: size.width - metrics.sideInset - metrics.utilityRadius * 2 - 12, y: metrics.topY - 19)
        scoreLabel.zPosition = 40
        addChild(scoreLabel)

        comboCueLabel = label("", size: 15.6, color: UIColor(hex: "DCF8EE"), alpha: 0, align: .center, weight: true)
        comboCueLabel.name = "hud.comboCue"
        comboCueLabel.position = comboCuePosition()
        comboCueLabel.zPosition = 43
        comboCueLabel.isHidden = true
        addChild(comboCueLabel)

        modeLabel = label("", size: 10.75, alpha: 0.46, align: .center, weight: true)
        modeLabel.name = "hud.mode"
        modeLabel.position = CGPoint(x: size.width * 0.5, y: metrics.modeY)
        addChild(modeLabel)
    }

    private func buildOnboardingSurface() {
        onboardingLabel.removeFromParent()
        onboardingLabel = label("", size: 15.3, alpha: 0.89, align: .center, weight: true)
        onboardingLabel.name = "hud.onboarding"
        onboardingLabel.position = CGPoint(x: size.width * 0.5, y: trayBottom + slotH + 46)
        onboardingLabel.zPosition = 30
        onboardingLabel.isHidden = true
        onboardingLabel.alpha = 0
        onboardingLabel.fontColor = UIColor(hex: "F6F7FF").withAlphaComponent(0.89)
        addChild(onboardingLabel)
    }

    private func buildGrid() {
        children.filter { $0.name?.hasPrefix("board.") == true }.forEach { $0.removeFromParent() }
        cellNodes.values.forEach { $0.removeFromParent() }
        cellNodes = [:]
        let bounds = HexGeometry.boardBounds(cols: cols, rows: rows)
        let boardRect = CGRect(
            x: gridOrigin.x + bounds.minX - 18,
            y: gridOrigin.y + bounds.minY - 20,
            width: bounds.width + 36,
            height: bounds.height + 40
        )

        let halo = SKShapeNode(rect: boardRect.insetBy(dx: -12, dy: -16), cornerRadius: 36)
        halo.name = "board.halo"
        halo.fillColor = UIColor(hex: "070A14").withAlphaComponent(0.2)
        halo.strokeColor = .clear
        halo.zPosition = -4
        addChild(halo)

        let backdrop = SKShapeNode(rect: boardRect, cornerRadius: 30)
        backdrop.name = "board.backdrop"
        backdrop.fillColor = UIColor(hex: "0B0F1E").withAlphaComponent(0.635)
        backdrop.strokeColor = UIColor(hex: "7D8CBE").withAlphaComponent(0.1)
        backdrop.lineWidth = 1
        backdrop.zPosition = -3
        addChild(backdrop)

        let frame = SKShapeNode(rect: boardRect.insetBy(dx: 8, dy: 8), cornerRadius: 24)
        frame.name = "board.frame"
        frame.fillColor = UIColor.clear
        frame.strokeColor = UIColor(hex: "7D8CBE").withAlphaComponent(0.1)
        frame.lineWidth = 1
        frame.zPosition = -2
        addChild(frame)

        for col in 0..<cols {
            for row in 0..<rows {
                let coord = HexCoordinate(col, row)
                let node = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius - 1))
                let highlight = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius * 0.72))
                highlight.name = "highlight"
                highlight.fillColor = UIColor(white: 1, alpha: 0.09)
                highlight.strokeColor = .clear
                highlight.lineWidth = 0
                highlight.position = CGPoint(x: 0, y: HexGeometry.radius * 0.18)
                highlight.zPosition = 1
                node.addChild(highlight)
                applyEmptyCellAppearance(for: coord, node: node)
                node.position = HexGeometry.pixelCenter(for: coord, origin: gridOrigin)
                addChild(node)
                cellNodes[coord] = node
            }
        }
    }

    private func buildTray() {
        traySlots.forEach { $0.removeFromParent() }
        traySlots = []
        traySlotFrames = []
        trayPreviews = [nil, nil, nil]
        rerollBadges = [nil, nil, nil]
        let totalPad = pad * 2 + slotSpacing * 2
        let slotW = (size.width - totalPad) / 3
        let centerY = trayBottom + slotH * 0.5
        for i in 0..<3 {
            let cx = pad + slotW * CGFloat(i) + slotSpacing * CGFloat(i) + slotW * 0.5
            let slot = SKShapeNode(rectOf: CGSize(width: slotW, height: slotH), cornerRadius: 14)
            slot.name = "tray.slot.\(i)"
            slot.fillColor = UIColor(hex: "131328")
            slot.strokeColor = UIColor(hex: "262643")
            slot.lineWidth = 1
            slot.position = CGPoint(x: cx, y: centerY)
            slot.zPosition = 1

            let base = SKShapeNode(rectOf: CGSize(width: slotW, height: slotH + 2), cornerRadius: 15)
            base.name = "slot.base"
            base.fillColor = UIColor.black.withAlphaComponent(0.24)
            base.strokeColor = .clear
            base.position = CGPoint(x: 0, y: -2)
            base.zPosition = -2
            slot.addChild(base)

            let inner = SKShapeNode(rectOf: CGSize(width: slotW - 8, height: slotH - 8), cornerRadius: 12)
            inner.name = "slot.inner"
            inner.fillColor = UIColor.white.withAlphaComponent(0.012)
            inner.strokeColor = UIColor.white.withAlphaComponent(0.03)
            inner.lineWidth = 1
            inner.zPosition = -1
            slot.addChild(inner)

            let sheen = SKShapeNode(rectOf: CGSize(width: slotW - 20, height: 2), cornerRadius: 1)
            sheen.name = "slot.sheen"
            sheen.fillColor = UIColor.white.withAlphaComponent(0.09)
            sheen.strokeColor = .clear
            sheen.position = CGPoint(x: 0, y: slotH * 0.5 - 10)
            sheen.zPosition = 2
            slot.addChild(sheen)

            let restMark = SKShapeNode(rectOf: CGSize(width: min(26, slotW * 0.22), height: 2), cornerRadius: 1)
            restMark.name = "slot.restMark"
            restMark.fillColor = UIColor.white.withAlphaComponent(0.13)
            restMark.strokeColor = .clear
            restMark.zPosition = 2
            slot.addChild(restMark)

            addChild(slot)
            traySlots.append(slot)
            traySlotFrames.append(CGRect(
                x: cx - slotW * 0.5,
                y: centerY - slotH * 0.5,
                width: slotW,
                height: slotH
            ))
        }
    }

    private func buildOverlay() {
        resultOverlay.rebuild(in: self, size: size, metrics: layoutMetrics) { text, size, color, alpha, align, weight in
            self.label(text, size: size, color: color, alpha: alpha, align: align, weight: weight)
        }
    }

    func syncAll() {
        DailyChallengeService.shared.refreshForCurrentDay()
        syncBoard()
        syncModeSurface()
        syncModeIdentitySurface()
        syncScores()
        syncTray()
        syncOnboardingSurface()
        syncUtilitySurface()
        syncCaptureComboReviewCueIfNeeded()
        if engine.isGameOver {
            SystemEntryService.shared.clearResumableRun()
            clearPersistedLiveRun()
            if engine.isDailyChallenge {
                finalizeRunIfNeeded()
            }
            updateOverlayResult()
            updateGameCenterSurface()
            updateShareSurface()
            updateContinueSurface()
            presentOverlayIfNeeded()
        } else {
            SystemEntryService.shared.markRunActive(mode: engine.runMode)
            persistLiveRunIfNeeded()
            hideOverlayIfNeeded()
        }
        updateAccessibilitySurfaces()
    }

    func persistLiveRunIfNeeded() {
        guard hasBuiltScene,
              !LaunchSupport.shared.isCaptureMode,
              !engine.isGameOver,
              let snapshot = engine.makeLiveRunSnapshot(runStartBest: runStartBest) else {
            return
        }
        LiveRunPersistenceService.shared.save(snapshot)
    }

    private func clearPersistedLiveRun() {
        LiveRunPersistenceService.shared.clear()
    }

    @discardableResult
    private func restorePersistedRunIfNeeded(force: Bool = false) -> Bool {
        if !force {
            guard !hasAttemptedPersistedRestore else { return false }
            hasAttemptedPersistedRestore = true
        }
        guard !LaunchSupport.shared.isCaptureMode,
              let snapshot = LiveRunPersistenceService.shared.load() else {
            return false
        }
        restoreLiveRun(from: snapshot)
        return true
    }

    func restoreLiveRun(from snapshot: GameEngine.LiveRunSnapshot) {
        flowEpoch &+= 1
        cancelDrag()
        resetVisualActions()
        clearHighlights()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        engine.restoreLiveRun(from: snapshot)
        lastDailyCompletion = nil
        isShowingTransientOnboardingHint = false
        runStartBest = snapshot.runStartBest
        hasFinalizedRun = false
        hasRecordedContinueOfferForCurrentLoss = false
        hasShownChainMasteryHint = false
        visibleRerollOfferSlots.removeAll()
        isRestarting = false
        isPresentingContinue = false
        isPresentingReroll = false
        isPresentingSupporterPurchase = false
        isPresentingNewRunConfirmation = false
        hasStartedAnalyticsRun = true
        if engine.isDailyChallenge {
            MonetizationService.shared.resetRunState()
            hasStartedMonetizationRun = false
        } else {
            MonetizationService.shared.restoreRunState(
                hasUsedContinue: engine.hasUsedContinue,
                hasUsedReroll: engine.hasUsedReroll
            )
            hasStartedMonetizationRun = true
        }
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        syncAll()
    }

    private func updateOverlayResult() {
        let score = engine.scoreEngine.score
        let caption: String
        let badge: String
        let detail: String
        let progress: String
        if engine.isDailyChallenge {
            let dayID = engine.dailyChallengeDayID ?? DailyChallengeService.shared.currentDayID()
            let ritualIdentity = DailyRitualIdentity.identity(for: dayID)
            caption = VexloStrings.Overlay.dailyComplete
            let completion = lastDailyCompletion
            badge = completion?.isNewBestToday == true ? VexloStrings.Overlay.bestToday : ""
            detail = ritualIdentity.resultDetailLine
            let streakCount = completion?.streakCount ?? DailyChallengeService.shared.previewStreakIfCompleted(
                dayID: dayID
            )
            progress = streakCount > 0 ? ritualIdentity.continuityLine(streakCount: streakCount) : ""
        } else {
            let editorialCharacter = Self.editorialRunCharacter(
                maxCombo: engine.maxCombo,
                didClearAny: engine.didClearAny,
                hasUsedContinue: engine.hasUsedContinue
            )
            caption = VexloStrings.Overlay.gameOver
            let completedRuns = GameCenterService.shared.completedRunCount
            progress = Self.quietNearMissMasteryLine(
                score: score,
                best: engine.scoreEngine.best,
                maxCombo: engine.maxCombo,
                didClearAny: engine.didClearAny,
                hasUsedContinue: engine.hasUsedContinue
            ) ?? (completedRuns > 0 ? VexloStrings.Overlay.runCount(completedRuns) : "")
            if score >= engine.scoreEngine.best && score > runStartBest {
                badge = VexloStrings.Overlay.newBest
            } else {
                badge = ""
            }
            detail = editorialCharacter
        }
        resultOverlay.applyResultText(
            score: score,
            caption: caption,
            badge: badge,
            detail: detail,
            progress: progress,
            isDaily: engine.isDailyChallenge,
            size: size,
            metrics: layoutMetrics,
            fitLabelWidth: fitLabelWidth
        )
    }

    private func updateGameCenterSurface() {
        let isResultOverlayCapture = LaunchSupport.shared.isResultOverlayCapture
        let canShare = engine.isGameOver && !LaunchSupport.shared.isInternalCapture
        let showsContinue = !isResultOverlayCapture && canShowContinueAfterLoss() && !isPresentingContinue
        var gamesText: String?
        var showsGames = false
        var showsProgress = false
        if engine.isDailyChallenge {
            gamesText = VexloStrings.Overlay.playTogether
            showsGames = GameCenterService.shared.canPresentDailyActivity
            showsProgress = true
        } else {
            let earnedBest = engine.scoreEngine.score >= engine.scoreEngine.best && engine.scoreEngine.score > runStartBest
            let canChallenge = GameCenterService.shared.canPresentScoreChallenge && engine.scoreEngine.score > 0
            let canScoreChaseActivity = earnedBest && GameCenterService.shared.canPresentScoreChaseActivity
            let completedRuns = GameCenterService.shared.completedRunCount
            if canChallenge {
                gamesText = VexloStrings.Overlay.challengeFriends
                showsGames = true
            } else if canScoreChaseActivity {
                gamesText = VexloStrings.Overlay.playTogether
                showsGames = true
            } else if GameCenterService.shared.isAuthenticated {
                gamesText = VexloStrings.Overlay.leaderboard
                showsGames = true
            }
            showsProgress = completedRuns > 0
        }
        resultOverlay.updateGameCenterSurface(
            isResultOverlayCapture: isResultOverlayCapture,
            isDaily: engine.isDailyChallenge,
            gamesText: gamesText,
            showsGames: showsGames,
            showsProgress: showsProgress,
            canShare: canShare,
            showsContinue: showsContinue,
            size: size,
            metrics: layoutMetrics,
            fitLabelWidth: fitLabelWidth
        )
    }

    private func presentOverlayIfNeeded() {
        guard !isOverlayPresented else { return }
        if !LaunchSupport.shared.isCaptureMode {
            AnalyticsService.shared.markLossSurfacePresented()
            if !engine.isDailyChallenge {
                MonetizationService.shared.markRunEnded()
            }
            if !canShowContinueAfterLoss() && !engine.isDailyChallenge {
                finalizeRunIfNeeded()
            }
        }
        isOverlayPresented = true
        isRestarting = false
        hideUtilitySurface()
        syncModeSurface()
        syncScores()
        syncUtilitySurface()
        resultOverlay.present(prefersReducedMotion: prefersReducedMotion)
        animateTerminalBoardWithdrawalIfNeeded()
        if !LaunchSupport.shared.isCaptureMode {
            if !prefersReducedMotion {
                HapticsService.shared.playInvalid()
            }
            playOverlayResultAudioIfNeeded()
        }
    }

    func hideOverlayIfNeeded() {
        guard isOverlayPresented || !overlayNode.isHidden else { return }
        isOverlayPresented = false
        isRestarting = false
        isPresentingContinue = false
        isPresentingReroll = false
        isPresentingSupporterPurchase = false
        isPresentingNewRunConfirmation = false
        hasRecordedContinueOfferForCurrentLoss = false
        resultOverlay.hide()
        syncModeSurface()
        syncScores()
        syncUtilitySurface()
    }

    private func animateLabelUpdate(_ label: SKLabelNode, emphasis: CGFloat = 1.0) {
        label.removeAllActions()
        guard !prefersReducedMotion else { return }
        label.setScale(0.965 - min(0.025, (emphasis - 1) * 0.02))
        label.alpha = 0.86 + min(0.08, (emphasis - 1) * 0.05)
        label.run(.group([
            .scale(to: emphasis, duration: 0.14),
            .fadeAlpha(to: 1.0, duration: 0.14)
        ]))
    }

    private func animateTerminalBoardWithdrawalIfNeeded() {
        guard terminalOverlayOwnsResultContext, !prefersReducedMotion else { return }

        if let halo = childNode(withName: "board.halo") as? SKShapeNode {
            halo.removeAction(forKey: "result.withdraw")
            halo.alpha = 0.72
            halo.setScale(1.024)
            halo.run(
                .group([
                    .fadeAlpha(to: 1.0, duration: 0.24),
                    .scale(to: 1.0, duration: 0.24)
                ]),
                withKey: "result.withdraw"
            )
        }
        if let backdrop = childNode(withName: "board.backdrop") as? SKShapeNode {
            backdrop.removeAction(forKey: "result.withdraw")
            backdrop.alpha = 0.84
            backdrop.run(.fadeAlpha(to: 1.0, duration: 0.26), withKey: "result.withdraw")
        }
        if let frame = childNode(withName: "board.frame") as? SKShapeNode {
            frame.removeAction(forKey: "result.withdraw")
            frame.alpha = 0.64
            frame.run(.fadeAlpha(to: 1.0, duration: 0.26), withKey: "result.withdraw")
        }
        for node in cellNodes.values {
            let targetAlpha = node.alpha
            node.removeAction(forKey: "result.withdraw")
            node.alpha = min(1.0, targetAlpha * 1.28)
            node.setScale(1.008)
            node.run(
                .group([
                    .fadeAlpha(to: targetAlpha, duration: 0.28),
                    .scale(to: 1.0, duration: 0.28)
                ]),
                withKey: "result.withdraw"
            )
        }
    }

    private func animatePlacement(coords: [HexCoordinate], color: UIColor, completion: @escaping () -> Void) {
        let nodes = coords.compactMap { cellNodes[$0] }
        guard !nodes.isEmpty else {
            completion()
            return
        }
        for node in nodes {
            node.removeAllActions()
            node.fillColor = color
            node.strokeColor = UIColor(white: 1, alpha: 0.25)
            node.lineWidth = 1.2
        }
        guard !prefersReducedMotion else {
            completion()
            return
        }
        for node in nodes {
            node.run(.sequence([
                .group([
                    .scale(to: 1.06, duration: 0.05),
                    .fadeAlpha(to: 0.96, duration: 0.05)
                ]),
                .group([
                    .scale(to: 1.0, duration: 0.09),
                    .fadeAlpha(to: 1.0, duration: 0.09)
                ])
            ]))
        }
        run(.sequence([
            .wait(forDuration: 0.1),
            .run(completion)
        ]))
    }

    private func handlePostPlacementFeedback(
        placedCoords: [HexCoordinate],
        pieceColor: UIColor,
        previousScore: Int,
        previousCombo: Int,
        clearedCoords: [HexCoordinate],
        clearedLineCount: Int
    ) {
        animatePlacement(coords: placedCoords, color: pieceColor) { [weak self] in
            guard let self else { return }
            if self.engine.scoreEngine.score > previousScore {
                self.syncScores()
                HapticsService.shared.playClear()
                let chainAdvanced = self.engine.scoreEngine.combo > previousCombo && self.engine.scoreEngine.combo > 1
                let shouldPlayComboReward = chainAdvanced && clearedLineCount > 1
                if chainAdvanced {
                    HapticsService.shared.playCombo()
                }
                if shouldPlayComboReward {
                    AudioService.shared.play(self.engine.scoreEngine.combo >= 3 ? .comboX3Plus : .comboX2)
                } else {
                    AudioService.shared.play(.lineClear)
                }
                if !clearedCoords.isEmpty {
                    self.animateClear(coords: clearedCoords) { [weak self] in
                        guard let self else { return }
                        self.syncAll()
                        self.presentPostClearMasteryCuesIfNeeded(clearedLineCount: clearedLineCount, chainAdvanced: chainAdvanced)
                        self.handleFirstClearComprehensionIfNeeded(
                            clearedCoords: clearedCoords,
                            clearedLineCount: clearedLineCount,
                            chainAdvanced: chainAdvanced
                        )
                    }
                } else {
                    self.syncAll()
                    self.presentPostClearMasteryCuesIfNeeded(clearedLineCount: clearedLineCount, chainAdvanced: chainAdvanced)
                }
            } else {
                self.syncAll()
            }
            if self.engine.isGameOver {
                self.updateOverlayResult()
            }
        }
    }

    func resetVisualActions() {
        removeAllActions()
        overlayNode.removeAllActions()
        bestLabel.removeAllActions()
        scoreLabel.removeAllActions()
        comboCueLabel.removeAllActions()
        comboCueLabel.alpha = 0
        comboCueLabel.isHidden = true
        overlayScoreLabel.removeAllActions()
        overlayDetailLabel.removeAllActions()
        overlayBadgeLabel.removeAllActions()
        overlayProgressLabel.removeAllActions()
        overlayGamesLabel.removeAllActions()
        overlayContinueButton.removeAllActions()
        utilityButton.removeAllActions()
        utilityMenuNode.removeAllActions()
        utilitySoundLabel.removeAllActions()
        utilityHapticsLabel.removeAllActions()
        utilitySupporterLabel.removeAllActions()
        utilityRestoreLabel.removeAllActions()
        utilityExportLabel.removeAllActions()
        utilityNewRunLabel.removeAllActions()
        utilityStudioLabel.removeAllActions()
        modeLabel.removeAllActions()
        isPresentingDailyArrivalBeat = false
        hasRecordedContinueOfferForCurrentLoss = false
        for node in cellNodes.values {
            node.removeAllActions()
            node.setScale(1.0)
            node.alpha = 1.0
        }
    }

    private func refreshBoardPressureSnapshot() {
        boardPressureSnapshot = engine.boardPressureSnapshot()
    }

    private func syncBoard() {
        refreshBoardPressureSnapshot()
        for col in 0..<cols {
            for row in 0..<rows {
                let coord = HexCoordinate(col, row)
                guard let node = cellNodes[coord] else { continue }
                if let color = engine.board.color(at: coord) {
                    applyFilledCellStyle(node, color: color)
                } else {
                    applyEmptyCellAppearance(for: coord, node: node)
                }
            }
        }
    }

    private func syncScores() {
        let best = currentDisplayedBest()
        let score = engine.scoreEngine.score
        let shouldShowTopMetrics = !terminalOverlayOwnsResultContext
        bestCaptionLabel.isHidden = !shouldShowTopMetrics
        bestLabel.isHidden = !shouldShowTopMetrics
        scoreCaptionLabel.isHidden = !shouldShowTopMetrics
        scoreLabel.isHidden = !shouldShowTopMetrics
        if !shouldShowTopMetrics {
            comboCueLabel.isHidden = true
            comboCueLabel.alpha = 0
        }
        bestCaptionLabel.text = engine.isDailyChallenge ? VexloStrings.HUD.today : VexloStrings.HUD.best
        bestLabel.text = "\(best)"
        scoreLabel.text = "\(score)"
        if engine.scoreEngine.score > 0 {
            let bounce = SKAction.sequence([
                SKAction.scale(to: 1.22, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.10)
            ])
            bounce.timingMode = .easeInEaseOut
            scoreLabel.run(bounce)
        }
        resultOverlay.scoreLabel.text = "\(score)"
        bestCaptionLabel.fontColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.7)
        bestLabel.fontColor = UIColor(hex: "6C5CE7")
        scoreCaptionLabel.fontColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.7)
        scoreLabel.fontColor = .white
        syncPublicCaptureMetricContextIfNeeded()
        fitLabelWidth(modeLabel, maxWidth: size.width * 0.48, minimumScale: 0.78)
        if shouldShowTopMetrics && best != lastBestValue {
            animateLabelUpdate(bestLabel, emphasis: 1.025)
        }
        if shouldShowTopMetrics && score != lastScoreValue {
            let scoreEmphasis: CGFloat = score > lastScoreValue && engine.scoreEngine.combo > 1 ? 1.045 : 1.0
            animateLabelUpdate(scoreLabel, emphasis: scoreEmphasis)
        }
        lastBestValue = best
        lastScoreValue = score
    }

    private func showEventCue(_ text: String) {
        guard !terminalOverlayOwnsResultContext else { return }
        comboCueLabel.removeAllActions()
        comboCueLabel.text = text
        comboCueLabel.position = comboCuePosition()
        comboCueLabel.isHidden = false
        comboCueLabel.alpha = 0
        comboCueLabel.setScale(0.968)
        comboCueLabel.fontColor = UIColor(hex: "F4FDF9")
        comboCueLabel.fontSize = 19.75
        comboCueLabel.zPosition = scoreLabel.zPosition + 4
        fitLabelWidth(comboCueLabel, maxWidth: size.width - pad * 4, minimumScale: 0.86)

        guard !prefersReducedMotion else {
            comboCueLabel.alpha = 0.975
            comboCueLabel.run(.sequence([
                .wait(forDuration: 1.16),
                .fadeOut(withDuration: 0.18),
                .run { [weak self] in
                    self?.comboCueLabel.isHidden = true
                }
            ]))
            return
        }

        comboCueLabel.run(.sequence([
            .group([
                .fadeAlpha(to: 0.975, duration: 0.2),
                .scale(to: 1.0, duration: 0.18),
                .moveBy(x: 0, y: 3, duration: 0.2)
            ]),
            .wait(forDuration: 1.04),
            .group([
                .fadeOut(withDuration: 0.18),
                .moveBy(x: 0, y: 4, duration: 0.18)
            ]),
            .run { [weak self] in
                self?.comboCueLabel.isHidden = true
            }
        ]))
    }

    private func syncCaptureComboReviewCueIfNeeded() {
        guard LaunchSupport.shared.captureState == .normalComboReview,
              engine.scoreEngine.combo > 1,
              !terminalOverlayOwnsResultContext else { return }
        comboCueLabel.removeAllActions()
        comboCueLabel.text = Self.chainCueText(for: engine.scoreEngine.combo)
        comboCueLabel.position = comboCuePosition()
        comboCueLabel.zPosition = scoreLabel.zPosition + 3
        comboCueLabel.fontColor = UIColor(hex: "ECFBF5")
        comboCueLabel.fontSize = 18.75
        comboCueLabel.isHidden = false
        comboCueLabel.alpha = 0.955
        comboCueLabel.setScale(1)
        fitLabelWidth(comboCueLabel, maxWidth: size.width - pad * 4, minimumScale: 0.86)
    }

    private func syncOnboardingSurface() {
        guard canShowFirstSessionHintSurface,
              dragPiece == nil else {
            if !isShowingTransientOnboardingHint {
                onboardingLabel.isHidden = true
                onboardingLabel.alpha = 0
                onboardingLabel.removeAllActions()
            }
            return
        }

        guard !isShowingTransientOnboardingHint else { return }

        if shouldShowPlacementHintSurface {
            let text = VexloStrings.Onboarding.dragToBoard
            let textChanged = onboardingLabel.text != text || onboardingLabel.isHidden
            applyOnboardingCueStyle(isTransient: false)
            onboardingLabel.text = text
            onboardingLabel.isHidden = false
            fitLabelWidth(onboardingLabel, maxWidth: size.width - pad * 4, minimumScale: 0.82)
            guard textChanged else { return }
            onboardingLabel.removeAllActions()
            if prefersReducedMotion {
                onboardingLabel.alpha = 0.89
            } else {
                onboardingLabel.alpha = 0
                onboardingLabel.run(.group([
                    .fadeAlpha(to: 0.89, duration: 0.32),
                    .moveBy(x: 0, y: 3.5, duration: 0.32)
                ]))
            }
        } else {
            onboardingLabel.text = nil
            onboardingLabel.removeAllActions()
            onboardingLabel.isHidden = true
            onboardingLabel.alpha = 0
        }
    }

    private func showTransientOnboardingHint(_ text: String) {
        guard canShowFirstSessionHintSurface else { return }
        isShowingTransientOnboardingHint = true
        onboardingLabel.removeAllActions()
        applyOnboardingCueStyle(isTransient: true)
        onboardingLabel.text = text
        onboardingLabel.isHidden = false
        fitLabelWidth(onboardingLabel, maxWidth: size.width - pad * 4, minimumScale: 0.82)
        if prefersReducedMotion {
            onboardingLabel.alpha = 0.972
        } else {
            onboardingLabel.alpha = 0
            onboardingLabel.setScale(0.988)
            onboardingLabel.run(.group([
                .fadeAlpha(to: 0.972, duration: 0.24),
                .scale(to: 1.0, duration: 0.24),
                .moveBy(x: 0, y: 4.25, duration: 0.24)
            ]))
        }
        onboardingLabel.run(.sequence([
            .wait(forDuration: prefersReducedMotion ? 3.12 : 3.18),
            prefersReducedMotion ? .run {} : .fadeOut(withDuration: 0.22),
            .run { [weak self] in
                guard let self else { return }
                self.isShowingTransientOnboardingHint = false
                self.onboardingLabel.isHidden = true
                self.onboardingLabel.alpha = 0
                self.syncOnboardingSurface()
            }
        ]))
    }

    private func restartRun() {
        guard !isRestarting else { return }
        AnalyticsService.shared.recordRestartTriggered()
        isRestarting = true
        finalizeRunIfNeeded()
        if engine.isDailyChallenge {
            let status = DailyChallengeService.shared.currentStatus()
            if engine.dailyChallengeDayID == status.dayID {
                beginSceneRun(mode: engine.runMode)
            } else {
                beginSceneRun(mode: .daily(dayID: status.dayID, seed: status.seed))
            }
        } else {
            beginSceneRun(mode: engine.runMode)
        }
    }

    private func finalizeRunIfNeeded() {
        guard !hasFinalizedRun else { return }
        hasFinalizedRun = true
        if engine.isDailyChallenge {
            guard let dayID = engine.dailyChallengeDayID else { return }
            lastDailyCompletion = DailyChallengeService.shared.completeRun(dayID: dayID, score: engine.scoreEngine.score)
            if let completion = lastDailyCompletion {
                AnalyticsService.shared.recordDailyChallengeCompleted(streak: completion.streakCount)
            }
        } else {
            let completedRuns = GameCenterService.shared.nextCompletedRunCount()
            GameCenterService.shared.reportCompletedRun(
                score: engine.scoreEngine.score,
                didClearAny: engine.didClearAny,
                maxCombo: engine.maxCombo,
                completedRuns: completedRuns
            )
        }
        AnalyticsService.shared.finalizeRun(
            score: engine.scoreEngine.score,
            maxCombo: engine.maxCombo,
            didClearAny: engine.didClearAny
        )
    }

    private func startMonetizationRunIfNeeded() {
        guard !engine.isDailyChallenge else {
            hasStartedMonetizationRun = false
            MonetizationService.shared.resetRunState()
            return
        }
        guard !hasStartedMonetizationRun else { return }
        MonetizationService.shared.beginRun()
        hasStartedMonetizationRun = true
    }

    private func startAnalyticsRunIfNeeded() {
        guard !hasStartedAnalyticsRun else { return }
        AnalyticsService.shared.beginRun(mode: engine.isDailyChallenge ? .daily : .normal)
        hasStartedAnalyticsRun = true
    }

    func canShowContinueAfterLoss() -> Bool {
        guard !engine.isDailyChallenge else { return false }
        guard engine.canResumeAfterLoss() else { return false }
        return MonetizationService.shared.canPresent(.continueAfterLoss)
    }

    func canShowReroll(for slotIndex: Int) -> Bool {
        guard !LaunchSupport.shared.isCaptureMode else { return false }
        guard !engine.isDailyChallenge else { return false }
        guard !isOverlayPresented,
              !isRestarting,
              !isPresentingContinue,
              !isPresentingReroll,
              dragPiece == nil else { return false }
        guard engine.canRerollPiece(at: slotIndex) else { return false }
        return MonetizationService.shared.canPresent(.rerollTrayPiece)
    }

    private func updateContinueSurface() {
        guard !LaunchSupport.shared.isResultOverlayCapture else {
            hasRecordedContinueOfferForCurrentLoss = false
            resultOverlay.updateContinueVisibility(
                isVisible: false,
                size: size,
                metrics: layoutMetrics,
                isDaily: engine.isDailyChallenge,
                fitLabelWidth: fitLabelWidth
            )
            return
        }
        let isVisible = canShowContinueAfterLoss() && !isPresentingContinue
        if isVisible && !hasRecordedContinueOfferForCurrentLoss {
            AnalyticsService.shared.recordContinueOfferShown()
            hasRecordedContinueOfferForCurrentLoss = true
        } else if !isVisible {
            hasRecordedContinueOfferForCurrentLoss = false
        }
        resultOverlay.updateContinueVisibility(
            isVisible: isVisible,
            size: size,
            metrics: layoutMetrics,
            isDaily: engine.isDailyChallenge,
            fitLabelWidth: fitLabelWidth
        )
    }

    private func updateShareSurface() {
        let canShare = engine.isGameOver && !LaunchSupport.shared.isInternalCapture
        let showsContinue = !LaunchSupport.shared.isResultOverlayCapture && canShowContinueAfterLoss() && !isPresentingContinue
        resultOverlay.updateShareVisibility(
            canShare: canShare,
            showsContinue: showsContinue,
            size: size,
            metrics: layoutMetrics,
            isDaily: engine.isDailyChallenge,
            fitLabelWidth: fitLabelWidth
        )
    }

    private func currentDisplayedBest() -> Int {
        if let dayID = engine.dailyChallengeDayID {
            if let completion = lastDailyCompletion, completion.dayID == dayID {
                return completion.todayBest
            }
            return DailyChallengeService.shared.bestScore(for: dayID)
        }
        return engine.scoreEngine.best
    }

    private func syncModeSurface() {
        let isOpeningState = engine.scoreEngine.score == 0 && !engine.didClearAny
        if terminalOverlayOwnsResultContext {
            modeLabel.isHidden = true
            modeLabel.alpha = 0
            return
        }
        modeLabel.isHidden = false
        if engine.isDailyChallenge {
            if isPresentingDailyArrivalBeat {
                return
            }
            let status = DailyChallengeService.shared.currentStatus()
            let ritualIdentity = DailyRitualIdentity.identity(for: status.dayID)
            if LaunchSupport.shared.isCaptureMode {
                modeLabel.text = VexloStrings.HUD.todaysChallenge
                modeLabel.alpha = isPublicEditorialCapture ? 0.66 : 0.58
            } else {
                modeLabel.text = ritualIdentity.ritualHeadline
                modeLabel.alpha = isOpeningState ? 0.6 : 0.64
            }
        } else if !LaunchSupport.shared.isCaptureMode {
            let status = DailyChallengeService.shared.currentStatus()
            let weekdayTitle = DailyChallengeService.shared.weekdayTitle(for: status.dayID)
            if isOpeningState {
                modeLabel.text = Self.normalOpeningModeLabelText()
                modeLabel.alpha = 0.42
            } else if !weekdayTitle.isEmpty {
                modeLabel.text = VexloStrings.HUD.todaysBoard(weekday: weekdayTitle)
                modeLabel.alpha = 0.36
            } else if status.streakCount > 0 {
                modeLabel.text = VexloStrings.HUD.todaysChallenge(streak: status.streakCount)
                modeLabel.alpha = 0.38
            } else {
                modeLabel.text = VexloStrings.HUD.todaysChallenge
                modeLabel.alpha = 0.30
            }
        } else {
            modeLabel.alpha = 0
        }

        fitLabelWidth(modeLabel, maxWidth: size.width * 0.48,
            minimumScale: 0.78)
    }

    private func syncPublicCaptureMetricContextIfNeeded() {
        guard isPublicEditorialCapture, !terminalOverlayOwnsResultContext else { return }
        if engine.isDailyChallenge {
            bestCaptionLabel.fontColor = UIColor(hex: "DDE6FF").withAlphaComponent(0.36)
            bestLabel.fontColor = UIColor(hex: "F8FBFF")
            scoreCaptionLabel.fontColor = UIColor.white.withAlphaComponent(0.28)
        } else {
            bestCaptionLabel.fontColor = UIColor(hex: "B5A8FF").withAlphaComponent(0.33)
            bestLabel.fontColor = UIColor(hex: "6C5CE7")
            scoreCaptionLabel.fontColor = UIColor.white.withAlphaComponent(0.31)
        }
        scoreLabel.fontColor = UIColor.white
    }

    private func syncModeIdentitySurface() {
        let isDaily = engine.isDailyChallenge
        let isOpeningState = engine.scoreEngine.score == 0 && !engine.didClearAny
        let isNormalMidgame = !isDaily && !isOpeningState
        let isPlacementHintSurfaceVisible = shouldShowPlacementHintSurface
        let dailyTone: DailyToneVariant
        if isDaily {
            let dayID = engine.dailyChallengeDayID ?? DailyChallengeService.shared.currentDayID()
            dailyTone = DailyChallengeService.shared.toneVariant(for: dayID)
        } else {
            dailyTone = .glacial
        }
        let dailyAccentFill: String
        let dailyAccentStroke: String
        let dailyBestTint: String
        let dailyScoreTint: String
        let dailyHaloTint: String
        let dailyBackdropStroke: String
        switch dailyTone {
        case .glacial:
            dailyAccentFill = "DDE6FF"
            dailyAccentStroke = "F8FBFF"
            dailyBestTint = "DDE6FF"
            dailyScoreTint = "F8FBFF"
            dailyHaloTint = "C7D0FF"
            dailyBackdropStroke = "DDE6FF"
        case .lucid:
            dailyAccentFill = "D8EEFF"
            dailyAccentStroke = "F4FCFF"
            dailyBestTint = "DAECFF"
            dailyScoreTint = "F6FCFF"
            dailyHaloTint = "BFE0FF"
            dailyBackdropStroke = "D6EBFF"
        case .iris:
            dailyAccentFill = "E5DBFF"
            dailyAccentStroke = "FBF7FF"
            dailyBestTint = "E7DEFF"
            dailyScoreTint = "FCF9FF"
            dailyHaloTint = "D8CBFF"
            dailyBackdropStroke = "E4D8FF"
        }
        if let accent = childNode(withName: "hud.titleAccent") as? SKShapeNode {
            accent.fillColor = UIColor(hex: isDaily ? dailyAccentFill : "7A74F7").withAlphaComponent(isDaily ? 0.36 : 0.24)
            accent.strokeColor = UIColor(hex: isDaily ? dailyAccentStroke : "A8B4FF").withAlphaComponent(isDaily ? 0.13 : 0.06)
        }
        if isDaily {
            bestCaptionLabel.fontColor = UIColor(hex: dailyBestTint).withAlphaComponent(isOpeningState ? 0.42 : 0.38)
            bestLabel.fontColor = UIColor(hex: dailyScoreTint)
            scoreCaptionLabel.fontColor = UIColor.white.withAlphaComponent(isOpeningState ? 0.31 : 0.29)
            scoreLabel.fontColor = UIColor(hex: dailyScoreTint)
        } else if isOpeningState {
            bestCaptionLabel.fontColor = UIColor(hex: "B5A8FF").withAlphaComponent(0.38)
            bestLabel.fontColor = UIColor(hex: "7A74F7")
            scoreCaptionLabel.fontColor = UIColor.white.withAlphaComponent(0.34)
            scoreLabel.fontColor = UIColor(hex: "F4F3FF")
        } else if isNormalMidgame {
            bestCaptionLabel.fontColor = UIColor(hex: "B5A8FF").withAlphaComponent(0.35)
            bestLabel.fontColor = UIColor(hex: "6C5CE7")
            scoreCaptionLabel.fontColor = UIColor.white.withAlphaComponent(0.3)
            scoreLabel.fontColor = UIColor(hex: "F4F3FF")
        }
        if let halo = childNode(withName: "board.halo") as? SKShapeNode {
            let haloAlpha: CGFloat
            let isWeakScoreTerminal = terminalOverlayOwnsResultContext && !engine.isDailyChallenge && engine.scoreEngine.score < 10
            if terminalOverlayOwnsResultContext {
                haloAlpha = isWeakScoreTerminal
                    ? (size.height < 760 ? 0.002 : 0.003)
                    : (size.height < 760 ? (isDaily ? 0.0026 : 0.0034) : (isDaily ? 0.0038 : 0.0048))
            } else {
                haloAlpha = isPlacementHintSurfaceVisible ? 0.038 :
                    (isOpeningState ? (isDaily ? 0.03 : 0.034) : (isDaily ? 0.021 : (isNormalMidgame ? 0.028 : 0.024)))
            }
            halo.fillColor = UIColor(hex: isDaily ? dailyHaloTint : "92A1FF").withAlphaComponent(haloAlpha)
            if isPlacementHintSurfaceVisible, !prefersReducedMotion {
                if halo.action(forKey: "onboarding.pulse") == nil {
                    halo.setScale(1.0)
                    halo.run(
                        .repeatForever(
                            .sequence([
                                .scale(to: 1.012, duration: 0.52),
                                .scale(to: 1.0, duration: 0.52)
                            ])
                        ),
                        withKey: "onboarding.pulse"
                    )
                }
            } else {
                halo.removeAction(forKey: "onboarding.pulse")
                halo.setScale(1.0)
            }
        }
        if let backdrop = childNode(withName: "board.backdrop") as? SKShapeNode {
            let fillAlpha: CGFloat
            let strokeAlpha: CGFloat
            let isWeakScoreTerminal = terminalOverlayOwnsResultContext && !engine.isDailyChallenge && engine.scoreEngine.score < 10
            if terminalOverlayOwnsResultContext {
                fillAlpha = isWeakScoreTerminal ? (size.height < 760 ? 0.888 : 0.864) : (size.height < 760 ? 0.870 : 0.842)
                strokeAlpha = isWeakScoreTerminal
                    ? (size.height < 760 ? 0.007 : 0.010)
                    : (size.height < 760 ? (isDaily ? 0.011 : 0.010) : (isDaily ? 0.016 : 0.013))
            } else {
                fillAlpha = isPlacementHintSurfaceVisible ? 0.675 : (isOpeningState ? (isDaily ? 0.648 : 0.67) : (isDaily ? 0.626 : (isNormalMidgame ? 0.645 : 0.635)))
                strokeAlpha = isPlacementHintSurfaceVisible ? 0.102 :
                    (isOpeningState ? (isDaily ? 0.128 : 0.09) : (isDaily ? 0.098 : (isNormalMidgame ? 0.08 : 0.072)))
            }
            backdrop.fillColor = UIColor(hex: "101020").withAlphaComponent(fillAlpha)
            backdrop.strokeColor = UIColor(hex: isDaily ? dailyBackdropStroke : "A8B4FF").withAlphaComponent(strokeAlpha)
        }
        if let frame = childNode(withName: "board.frame") as? SKShapeNode {
            let frameAlpha: CGFloat
            let isWeakScoreTerminal = terminalOverlayOwnsResultContext && !engine.isDailyChallenge && engine.scoreEngine.score < 10
            if terminalOverlayOwnsResultContext {
                frameAlpha = isWeakScoreTerminal ? (size.height < 760 ? 0.0028 : 0.0046) : (size.height < 760 ? 0.0048 : 0.0072)
            } else {
                frameAlpha = isPlacementHintSurfaceVisible ? 0.072 : (isOpeningState ? (isDaily ? 0.078 : 0.064) : (isDaily ? 0.062 : (isNormalMidgame ? 0.054 : 0.048)))
            }
            frame.strokeColor = UIColor.white.withAlphaComponent(frameAlpha)
        }
    }

    func beginSceneRun(mode: GameEngine.RunMode) {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        clearPersistedLiveRun()
        lastDailyCompletion = nil
        isShowingTransientOnboardingHint = false
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        hasShownChainMasteryHint = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
        isPresentingNewRunConfirmation = false
        switch mode {
        case .normal:
            engine.startNormalRun()
            if LaunchSupport.shared.isCaptureMode {
                MonetizationService.shared.resetRunState()
                hasStartedMonetizationRun = false
            } else {
                MonetizationService.shared.beginRun()
                hasStartedMonetizationRun = true
            }
            runStartBest = engine.scoreEngine.best
        case let .daily(dayID, seed):
            engine.startDailyRun(dayID: dayID, seed: seed, boardCharacter: DailyChallengeService.shared.toneVariant(for: dayID).boardCharacter)
            MonetizationService.shared.resetRunState()
            hasStartedMonetizationRun = false
            runStartBest = DailyChallengeService.shared.bestScore(for: dayID)
        }
        hasFinalizedRun = false
        isRestarting = false
        hasStartedAnalyticsRun = true
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        if !LaunchSupport.shared.isCaptureMode {
            AnalyticsService.shared.beginRun(mode: engine.isDailyChallenge ? .daily : .normal)
        }
        syncAll()
        presentDailyArrivalBeatIfNeeded()
    }

    private func presentDailyArrivalBeatIfNeeded() {
        guard engine.isDailyChallenge,
              !LaunchSupport.shared.isCaptureMode,
              !terminalOverlayOwnsResultContext else { return }
        let dayID = engine.dailyChallengeDayID ?? DailyChallengeService.shared.currentDayID()
        guard engine.scoreEngine.score == 0, !engine.didClearAny else { return }
        guard DailyArrivalRitualService.shared.shouldPresentArrival(for: dayID) else { return }

        let identity = DailyRitualIdentity.identity(for: dayID)
        DailyArrivalRitualService.shared.markArrivalPresented(for: dayID)

        isPresentingDailyArrivalBeat = true
        let beatEpoch = flowEpoch
        let arrivalText = identity.arrivalLine
        let steadyHeadline = identity.ritualHeadline
        let steadyAlpha: CGFloat = 0.6

        modeLabel.removeAllActions()
        modeLabel.isHidden = false
        modeLabel.text = arrivalText
        modeLabel.alpha = prefersReducedMotion ? 0.56 : 0.44
        fitLabelWidth(modeLabel, maxWidth: size.width * 0.48, minimumScale: 0.78)

        let settle: () -> Void = { [weak self] in
            guard let self, beatEpoch == self.flowEpoch else { return }
            self.isPresentingDailyArrivalBeat = false
            self.modeLabel.text = steadyHeadline
            self.modeLabel.alpha = steadyAlpha
            self.fitLabelWidth(self.modeLabel, maxWidth: self.size.width * 0.48, minimumScale: 0.78)
        }

        if prefersReducedMotion {
            modeLabel.run(.sequence([
                .wait(forDuration: 0.82),
                .run { settle() }
            ]))
            return
        }

        modeLabel.run(.sequence([
            .fadeAlpha(to: 0.56, duration: 0.26),
            .wait(forDuration: 0.68),
            .run { [weak self] in
                guard let self, beatEpoch == self.flowEpoch else { return }
                self.modeLabel.text = steadyHeadline
            },
            .fadeAlpha(to: steadyAlpha, duration: 0.3),
            .run { settle() }
        ]))
    }

    private func playOverlayResultAudioIfNeeded() {
        guard !engine.isDailyChallenge else {
            AudioService.shared.play(.dailyComplete)
            return
        }
        let earnedBest = engine.scoreEngine.score >= engine.scoreEngine.best && engine.scoreEngine.score > runStartBest
        AudioService.shared.play(earnedBest ? .newBest : .gameOver)
    }

    private func applyCaptureModeIfNeeded() -> Bool {
        guard let captureState = LaunchSupport.shared.captureState else {
            appliedCaptureSignature = nil
            return false
        }
        let captureSignature = [
            captureState.rawValue,
            LaunchSupport.shared.captureIntent.rawValue,
            LaunchSupport.shared.captureScoreOverride.map(String.init) ?? "nil"
        ].joined(separator: "|")
        guard appliedCaptureSignature != captureSignature else {
            return false
        }
        appliedCaptureSignature = captureSignature
        switch captureState {
        case .normalRun:
            beginCaptureNormalRun()
        case .normalHero:
            beginCaptureNormalHeroRun()
        case .normalComboReview:
            beginCaptureNormalComboReview()
        case .dailyChallenge:
            beginCaptureDailyRun()
        case .dailyHero:
            beginCaptureDailyHeroRun()
        case .normalResult:
            beginCaptureNormalResult()
        case .dailyResult:
            beginCaptureDailyResult()
        case .utilitySurface:
            beginCaptureUtilitySurface()
        }
        return true
    }

    private func prepareCapturePresetTransition() {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        lastDailyCompletion = nil
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        hasShownChainMasteryHint = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
    }

    private func finalizeCapturePresetBootstrap(runStartBest: Int, hasFinalizedRun: Bool) {
        MonetizationService.shared.resetRunState()
        hasStartedMonetizationRun = false
        hasStartedAnalyticsRun = false
        self.hasFinalizedRun = hasFinalizedRun
        isRestarting = false
        self.runStartBest = runStartBest
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        syncAll()
    }

    private func beginCaptureNormalRun(seed: UInt64 = LaunchSupport.shared.captureNormalSeed) {
        prepareCapturePresetTransition()
        engine.startNormalRun(seed: seed)
        finalizeCapturePresetBootstrap(runStartBest: engine.scoreEngine.best, hasFinalizedRun: false)
    }

    private func beginCaptureNormalHeroRun() {
        beginCaptureNormalRun(seed: LaunchSupport.shared.captureNormalHeroSeed)
        playCaptureHeroSequence(
            maxPlacements: 9,
            preferredAnchors: [
                HexCoordinate(2, 2), HexCoordinate(3, 2), HexCoordinate(1, 3),
                HexCoordinate(4, 1), HexCoordinate(0, 4), HexCoordinate(5, 3),
                HexCoordinate(2, 5), HexCoordinate(4, 4), HexCoordinate(1, 1),
                HexCoordinate(5, 0), HexCoordinate(0, 1), HexCoordinate(3, 5),
                HexCoordinate(6, 2), HexCoordinate(1, 5), HexCoordinate(4, 6),
                HexCoordinate(0, 0), HexCoordinate(6, 5), HexCoordinate(2, 0)
            ]
        )
        syncAll()
    }

    private func beginCaptureNormalComboReview() {
        prepareCapturePresetTransition()
        engine.loadCaptureComboReviewState()
        finalizeCapturePresetBootstrap(runStartBest: engine.scoreEngine.best, hasFinalizedRun: false)
        showEventCue(Self.chainCueText(for: engine.scoreEngine.combo))
        syncCaptureComboReviewCueIfNeeded()
    }

    private func beginCaptureDailyRun() {
        prepareCapturePresetTransition()
        let dayID = LaunchSupport.shared.captureDailyDayID
        engine.startDailyRun(dayID: dayID, seed: DailyChallengeService.shared.seed(for: dayID), boardCharacter: DailyChallengeService.shared.toneVariant(for: dayID).boardCharacter)
        finalizeCapturePresetBootstrap(
            runStartBest: DailyChallengeService.shared.bestScore(for: dayID),
            hasFinalizedRun: false
        )
    }

    private func beginCaptureDailyHeroRun() {
        beginCaptureDailyRun()
        playCaptureHeroSequence(
            maxPlacements: 9,
            preferredAnchors: [
                HexCoordinate(3, 2), HexCoordinate(2, 3), HexCoordinate(4, 2),
                HexCoordinate(1, 1), HexCoordinate(5, 3), HexCoordinate(0, 4),
                HexCoordinate(3, 5), HexCoordinate(4, 0), HexCoordinate(1, 4),
                HexCoordinate(5, 1), HexCoordinate(2, 0), HexCoordinate(0, 2),
                HexCoordinate(6, 4), HexCoordinate(2, 5), HexCoordinate(4, 5),
                HexCoordinate(0, 0), HexCoordinate(6, 1), HexCoordinate(1, 6)
            ]
        )
        syncAll()
    }

    private func playCaptureHeroSequence(maxPlacements: Int, preferredAnchors: [HexCoordinate]) {
        var placements = 0
        while placements < maxPlacements, !engine.isGameOver {
            var didPlace = false
            for slotIndex in engine.pieces.indices {
                guard let piece = engine.pieces[slotIndex],
                      let anchor = preferredAnchors.first(where: { engine.canPlace(piece, at: $0) }) else {
                    continue
                }
                engine.place(piece, at: anchor, slotIndex: slotIndex)
                placements += 1
                didPlace = true
                break
            }
            if !didPlace { break }
        }
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
    }

    private func beginCaptureUtilitySurface() {
        beginCaptureNormalRun()
        isUtilityPresented = true
        utilityMenuNode.removeAllActions()
        utilityMenuNode.alpha = 1
        utilityMenuNode.setScale(1)
        syncUtilitySurface()
    }

    private func beginCaptureNormalResult() {
        prepareCapturePresetTransition()
        let captureScore = LaunchSupport.shared.captureScoreOverride ?? 240
        engine.loadCaptureTerminalState(
            mode: .normal,
            emptyCoordinates: Set([HexCoordinate(0, 0), HexCoordinate(3, 3), HexCoordinate(6, 6)]),
            tray: [
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)], color: UIColor(hex: "7A74F7")),
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)], color: UIColor(hex: "55A7F6")),
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0), HexCoordinate(0, 1)], color: UIColor(hex: "63C7B0"))
            ],
            score: captureScore,
            best: 240,
            combo: 2,
            didClearAny: true,
            maxCombo: 2
        )
        finalizeCapturePresetBootstrap(runStartBest: 180, hasFinalizedRun: true)
    }

    private func beginCaptureDailyResult() {
        prepareCapturePresetTransition()
        let dayID = LaunchSupport.shared.captureDailyDayID
        lastDailyCompletion = DailyChallengeCompletion(
            dayID: dayID,
            score: 180,
            isNewBestToday: true,
            todayBest: 180,
            streakCount: 4
        )
        runStartBest = 120
        engine.loadCaptureTerminalState(
            mode: .daily(dayID: dayID, seed: DailyChallengeService.shared.seed(for: dayID)),
            emptyCoordinates: Set([HexCoordinate(1, 0), HexCoordinate(4, 2), HexCoordinate(6, 5)]),
            tray: [
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(0, 1)], color: UIColor(hex: "6A8CFA")),
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0)], color: UIColor(hex: "52C0E0")),
                HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0), HexCoordinate(1, 1)], color: UIColor(hex: "8DBB8A"))
            ],
            score: 180,
            best: 0,
            combo: 3,
            didClearAny: true,
            maxCombo: 3
        )
        finalizeCapturePresetBootstrap(runStartBest: 120, hasFinalizedRun: true)
    }

    private func startDailyChallenge() {
        let status = DailyChallengeService.shared.currentStatus()
        AnalyticsService.shared.recordDailyChallengeEntered()
        beginSceneRun(mode: .daily(dayID: status.dayID, seed: status.seed))
    }

    private func startNormalRunFromDaily() {
        beginSceneRun(mode: .normal)
    }

    private func applyGameCenterRoute(_ route: GameCenterService.Route) {
        guard !LaunchSupport.shared.isCaptureMode, !isInteractionLocked else { return }
        switch route {
        case .dailyChallenge:
            startDailyChallenge()
        case .normalScoreChase:
            beginSceneRun(mode: .normal)
        }
    }

    func applySystemEntryRoute(_ route: SystemEntryRoute) {
        guard !LaunchSupport.shared.isCaptureMode, !isInteractionLocked else { return }
        switch route {
        case .todayChallenge:
            startDailyChallenge()
        case .resumeLastRun:
            if SystemEntryService.shared.hasInMemoryResumableRun, !engine.isGameOver {
                cancelDrag()
                clearHighlights()
                hideUtilitySurface()
                syncAll()
                return
            }
            guard SystemEntryService.shared.hasPersistedResumableRun else { return }
            _ = restorePersistedRunIfNeeded(force: true)
        case .scoreSprint:
            beginSceneRun(mode: .normal)
        }
    }

    private func requestContinueAfterLoss() {
        guard !isPresentingContinue,
              !isRestarting,
              !isPresentingSupporterPurchase,
              canShowContinueAfterLoss(),
              let presenter = presentationViewController() else { return }
        let flowEpoch = self.flowEpoch
        isPresentingContinue = true
        overlayContinueButton.alpha = 0.55
        MonetizationService.shared.presentRewardedOffer(.continueAfterLoss, from: presenter) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard flowEpoch == self.flowEpoch else { return }
                self.isPresentingContinue = false
                switch result {
                case .rewarded:
                    guard self.engine.continueAfterLoss() else {
                        self.updateContinueSurface()
                        if !self.canShowContinueAfterLoss() {
                            self.finalizeRunIfNeeded()
                        }
                        return
                    }
                    AnalyticsService.shared.recordContinueUsedSuccessfully(
                        viaSupporterBypass: MonetizationService.shared.capabilities.supporterOwned
                    )
                    MonetizationService.shared.resumeRunAfterContinue()
                    AudioService.shared.play(.continueResume)
                    self.resetVisualActions()
                    self.hideOverlayIfNeeded()
                    self.syncAll()
                case .dismissed, .failed, .unavailable:
                    AnalyticsService.shared.recordContinueAdOutcome(result)
                    self.updateContinueSurface()
                    if !self.canShowContinueAfterLoss() {
                        self.finalizeRunIfNeeded()
                    }
                }
            }
        }
    }

    private func requestReroll(at slotIndex: Int) {
        guard !isPresentingReroll,
              !isPresentingContinue,
              !isRestarting,
              !isPresentingSupporterPurchase,
              dragPiece == nil,
              canShowReroll(for: slotIndex),
              let presenter = presentationViewController() else { return }
        let flowEpoch = self.flowEpoch
        isPresentingReroll = true
        rerollBadges[safe: slotIndex]??.alpha = 0.45
        MonetizationService.shared.presentRewardedOffer(.rerollTrayPiece, from: presenter) { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard flowEpoch == self.flowEpoch else { return }
                self.isPresentingReroll = false
                switch result {
                case .rewarded:
                    guard self.engine.rerollPiece(at: slotIndex) else {
                        self.syncTray()
                        return
                    }
                    AnalyticsService.shared.recordRerollUsedSuccessfully(
                        viaSupporterBypass: MonetizationService.shared.capabilities.supporterOwned
                    )
                    self.syncTray()
                    HapticsService.shared.playPlace()
                    AudioService.shared.play(.rerollSuccess)
                case .dismissed, .failed, .unavailable:
                    AnalyticsService.shared.recordRerollAdOutcome(result)
                    self.syncTray()
                }
            }
        }
    }

    func requestSupporterPackPurchase() {
        guard !isPresentingSupporterPurchase,
              !isRestarting,
              !isPresentingContinue,
              !isPresentingReroll,
              MonetizationService.shared.canPresentSupporterPack() else { return }
        let flowEpoch = self.flowEpoch
        isPresentingSupporterPurchase = true
        utilitySupporterLabel.alpha = 0.55
        Task { [weak self] in
            guard let self else { return }
            let result = await MonetizationService.shared.purchaseSupporterPack()
            await MainActor.run {
                guard flowEpoch == self.flowEpoch else { return }
                if result == .success {
                    AnalyticsService.shared.recordSupporterPurchaseSuccess()
                }
                self.isPresentingSupporterPurchase = false
                self.updateContinueSurface()
                self.syncTray()
            }
        }
    }

    func requestSupporterPackRestore() {
        guard !isPresentingSupporterPurchase,
              !isRestarting,
              !isPresentingContinue,
              !isPresentingReroll,
              !utilityRestoreLabel.isHidden else { return }
        let flowEpoch = self.flowEpoch
        isPresentingSupporterPurchase = true
        utilityRestoreLabel.alpha = 0.3
        Task { [weak self] in
            guard let self else { return }
            let restored = await MonetizationService.shared.restoreSupporterPack()
            await MainActor.run {
                guard flowEpoch == self.flowEpoch else { return }
                if restored {
                    AnalyticsService.shared.recordSupporterRestoreSuccess()
                }
                self.isPresentingSupporterPurchase = false
                self.updateContinueSurface()
                self.syncTray()
            }
        }
    }

    func requestStartNewRun() {
        guard !isPresentingNewRunConfirmation,
              !isPresentingSupporterPurchase,
              !isPresentingContinue,
              !isPresentingReroll,
              !isRestarting,
              LiveRunPersistenceService.shared.hasPersistedRun,
              !engine.isGameOver,
              let presenter = presentationViewController() else { return }
        isPresentingNewRunConfirmation = true
        utilityNewRunLabel.alpha = 0.42
        let alert = UIAlertController(
            title: VexloStrings.Utility.startNewRunAlertTitle,
            message: VexloStrings.Utility.startNewRunAlertMessage,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: VexloStrings.Utility.cancel, style: .cancel) { [weak self] _ in
            guard let self else { return }
            self.isPresentingNewRunConfirmation = false
            self.syncUtilitySurface()
        })
        alert.addAction(UIAlertAction(title: VexloStrings.Utility.startNewRun, style: .default) { [weak self] _ in
            guard let self else { return }
            self.isPresentingNewRunConfirmation = false
            AudioService.shared.play(.startNewRunConfirm)
            self.hideUtilitySurface()
            self.clearPersistedLiveRun()
            self.beginSceneRun(mode: self.engine.runMode)
        })
        presenter.present(alert, animated: true)
    }

    private func presentationViewController() -> UIViewController? {
        var current = view?.window?.rootViewController
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }

    private func presentCenteredActivitySheet(items: [Any]) {
        guard let presenter = presentationViewController() else { return }
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        }
        presenter.present(controller, animated: true)
    }

    func exportDiagnosticsSnapshot() {
        guard AnalyticsService.shared.isTesterExportAvailable else { return }
        let snapshot = AnalyticsService.shared.exportSnapshot()
        presentCenteredActivitySheet(items: [snapshot])
    }

    private func shareResult() {
        guard engine.isGameOver,
              !LaunchSupport.shared.isInternalCapture else { return }
        AudioService.shared.play(.shareTap)
        let dailyRitualHeadline: String?
        if engine.isDailyChallenge {
            let dayID = engine.dailyChallengeDayID ?? DailyChallengeService.shared.currentDayID()
            dailyRitualHeadline = DailyRitualIdentity.identity(for: dayID).shareCardHeadline
        } else {
            dailyRitualHeadline = nil
        }
        let payload = ResultSharePayload(
            mode: engine.isDailyChallenge ? .daily : .normal,
            score: engine.scoreEngine.score,
            badge: overlayBadgeLabel.text?.isEmpty == false ? overlayBadgeLabel.text : nil,
            detail: overlayDetailLabel.text?.isEmpty == false ? overlayDetailLabel.text : nil,
            dailyRitualHeadline: dailyRitualHeadline
        )
        presentCenteredActivitySheet(items: ResultShareService.activityItems(for: payload))
    }

    func expandedHitContains(_ node: SKNode, pointInParent: CGPoint, minimumSize: CGSize = CGSize(width: 44, height: 44), padding: CGFloat = 8) -> Bool {
        let frame = node.calculateAccumulatedFrame()
        guard !frame.isEmpty else { return false }
        let width = max(frame.width + padding * 2, minimumSize.width)
        let height = max(frame.height + padding * 2, minimumSize.height)
        let hitFrame = CGRect(
            x: frame.midX - width * 0.5,
            y: frame.midY - height * 0.5,
            width: width,
            height: height
        )
        return hitFrame.contains(pointInParent)
    }

    func syncTray() {
        let isPlacementHintSurfaceVisible = shouldShowPlacementHintSurface
        var nextVisibleRerollOfferSlots: Set<Int> = []
        for i in 0..<3 {
            trayPreviews[i]?.removeFromParent()
            trayPreviews[i] = nil
            rerollBadges[i]?.removeFromParent()
            rerollBadges[i] = nil
            guard let slot = traySlots[safe: i] else { continue }
            if let piece = engine.pieces[safe: i] as? HexPiece {
                let preview = makeTrayPreview(piece, slotSize: slot.frame.size)
                preview.position = .zero
                slot.addChild(preview)
                trayPreviews[i] = preview
                applyTraySlotStyle(slot, occupied: true)
                slot.strokeColor = UIColor(hex: isPlacementHintSurfaceVisible ? "35356A" : "2E2E5A")
                slot.alpha = 1.0
                if canShowReroll(for: i) {
                    nextVisibleRerollOfferSlots.insert(i)
                    if !visibleRerollOfferSlots.contains(i) {
                        AnalyticsService.shared.recordRerollOfferShown()
                    }
                    let badge = makeRerollBadge()
                    badge.position = CGPoint(
                        x: slot.frame.width * 0.5 - layoutMetrics.rerollBadgeInset,
                        y: slot.frame.height * 0.5 - layoutMetrics.rerollBadgeInset
                    )
                    slot.addChild(badge)
                    rerollBadges[i] = badge
                }
            } else {
                applyTraySlotStyle(slot, occupied: false)
                slot.strokeColor = UIColor(hex: "1C1C3A")
                slot.alpha = 0.45
            }
        }
        visibleRerollOfferSlots = nextVisibleRerollOfferSlots
    }

    private func makeTrayPreview(_ piece: HexPiece, slotSize: CGSize) -> SKNode {
        let node = SKNode()
        let r = HexGeometry.radius * 0.52
        let centers = pieceCenters(for: piece, radius: r)
        let h = r * sqrt(3)
        let minX = centers.map { $0.x - r }.min() ?? 0
        let maxX = centers.map { $0.x + r }.max() ?? 0
        let minY = centers.map { $0.y - h * 0.5 }.min() ?? 0
        let maxY = centers.map { $0.y + h * 0.5 }.max() ?? 0
        let boundsCenter = CGPoint(x: (minX + maxX) * 0.5, y: (minY + maxY) * 0.5)
        let massCenter = centers.reduce(CGPoint.zero) { partial, center in
            CGPoint(x: partial.x + center.x, y: partial.y + center.y)
        }
        let averagedMassCenter = CGPoint(
            x: massCenter.x / max(CGFloat(centers.count), 1),
            y: massCenter.y / max(CGFloat(centers.count), 1)
        )
        let opticalCenter = CGPoint(
            x: boundsCenter.x + (averagedMassCenter.x - boundsCenter.x) * 0.28,
            y: boundsCenter.y + (averagedMassCenter.y - boundsCenter.y) * 0.28
        )
        let safeSize = CGSize(width: slotSize.width - 34, height: slotSize.height - 28)
        let fitScale = min(
            1,
            safeSize.width / max(maxX - minX, 1),
            safeSize.height / max(maxY - minY, 1)
        )
        node.setScale(fitScale)
        for (index, center) in centers.enumerated() {
            let hex = SKShapeNode(path: HexGeometry.hexPath(radius: r - 0.5))
            let localCenter = CGPoint(x: center.x - opticalCenter.x, y: center.y - opticalCenter.y)
            hex.name = "piece.hex"
            applyPieceSurfaceStyle(hex, color: piece.color, emphasis: .tray)
            hex.position = localCenter
            node.addChild(hex)

            let glintWidth = r * (index.isMultiple(of: 2) ? 0.58 : 0.48)
            let glint = SKShapeNode(rectOf: CGSize(width: glintWidth, height: 1.1), cornerRadius: 0.55)
            glint.name = "piece.glint"
            glint.fillColor = UIColor.white.withAlphaComponent(index.isMultiple(of: 2) ? 0.075 : 0.055)
            glint.strokeColor = .clear
            glint.position = CGPoint(
                x: localCenter.x - r * 0.08,
                y: localCenter.y + r * (index.isMultiple(of: 2) ? 0.29 : 0.25)
            )
            glint.zPosition = 1
            node.addChild(glint)
        }
        return node
    }

    private func makeDragNode(_ piece: HexPiece) -> SKNode {
        let node = SKNode()
        for center in pieceCenters(for: piece, radius: HexGeometry.radius) {
            let hex = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius - 1))
            hex.name = "piece.hex"
            applyPieceSurfaceStyle(hex, color: piece.color, emphasis: .dragNeutral)
            hex.position = center
            node.addChild(hex)

            let core = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius * 0.7))
            core.name = "piece.core"
            core.fillColor = UIColor.white.withAlphaComponent(0.045)
            core.strokeColor = UIColor.white.withAlphaComponent(0.04)
            core.lineWidth = 0.4
            core.position = CGPoint(x: center.x, y: center.y + HexGeometry.radius * 0.06)
            core.zPosition = 0.5
            node.addChild(core)

            let glint = SKShapeNode(rectOf: CGSize(width: HexGeometry.radius * 1.22, height: 2), cornerRadius: 1)
            glint.name = "piece.glint"
            glint.fillColor = UIColor.white.withAlphaComponent(0.11)
            glint.strokeColor = .clear
            glint.position = CGPoint(x: center.x, y: center.y + HexGeometry.radius * 0.34)
            glint.zPosition = 1
            node.addChild(glint)
        }
        return node
    }

    private func makeRerollBadge() -> SKNode {
        let container = SKNode()
        container.name = "reroll"
        let radius: CGFloat = size.height < 760 ? 14 : 13
        let bubble = SKShapeNode(circleOfRadius: radius)
        bubble.fillColor = UIColor.white.withAlphaComponent(0.08)
        bubble.strokeColor = UIColor.white.withAlphaComponent(0.16)
        bubble.lineWidth = 1
        container.addChild(bubble)
        let label = self.label("↻", size: size.height < 760 ? 15 : 14, color: .white, alpha: 0.78, align: .center, weight: true)
        label.verticalAlignmentMode = .center
        label.position = .zero
        container.addChild(label)
        return container
    }

    private func anchorScenePosition(_ anchor: HexCoordinate) -> CGPoint {
        HexGeometry.pixelCenter(for: anchor, origin: gridOrigin)
    }

    private func pieceCenters(for piece: HexPiece, radius: CGFloat) -> [CGPoint] {
        return piece.offsets.map { offset in
            HexGeometry.localPieceCenter(for: offset, radius: radius)
        }
    }

    private func handleOverlayTouch(at point: CGPoint) -> Bool {
        guard !overlayNode.isHidden else { return false }
        guard !isRestarting, !isPresentingContinue, !isPresentingSupporterPurchase else { return true }
        let overlayPoint = overlayNode.convert(point, from: self)
        if let progress = overlayNode.childNode(withName: "progress"),
           !progress.isHidden,
           expandedHitContains(progress, pointInParent: overlayPoint, minimumSize: CGSize(width: 120, height: 34), padding: 10) {
            if engine.isDailyChallenge {
                startNormalRunFromDaily()
            } else {
                GameCenterService.shared.showScoreLeaderboard()
            }
            return true
        }
        if let games = overlayNode.childNode(withName: "games"),
           !games.isHidden,
           expandedHitContains(games, pointInParent: overlayPoint, minimumSize: CGSize(width: 150, height: 34), padding: 10) {
            if engine.isDailyChallenge {
                GameCenterService.shared.presentDailyActivityIfAvailable()
            } else if GameCenterService.shared.canPresentScoreChallenge && engine.scoreEngine.score > 0 {
                GameCenterService.shared.presentScoreChallengeIfAvailable()
            } else {
                GameCenterService.shared.presentScoreChaseActivityIfAvailable()
            }
            return true
        }
        if let share = overlayNode.childNode(withName: "share"),
           !share.isHidden,
           expandedHitContains(share, pointInParent: overlayPoint, minimumSize: CGSize(width: 120, height: 34), padding: 10) {
            shareResult()
            return true
        }
        if let continueButton = overlayNode.childNode(withName: "continue"),
           !continueButton.isHidden,
           expandedHitContains(continueButton, pointInParent: overlayPoint, minimumSize: CGSize(width: 220, height: 52), padding: 6) {
            requestContinueAfterLoss()
            return true
        }
        if let restart = overlayNode.childNode(withName: "restart"),
           expandedHitContains(restart, pointInParent: overlayPoint, minimumSize: CGSize(width: 220, height: 56), padding: 6) {
            restartRun()
        }
        return true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if handleUtilityTouch(at: point) {
            return
        }
        if handleOverlayTouch(at: point) {
            return
        }
        if dragPiece == nil, expandedHitContains(modeLabel, pointInParent: point, minimumSize: CGSize(width: 160, height: 34), padding: 10) {
            if engine.isDailyChallenge {
                startNormalRunFromDaily()
            } else {
                startDailyChallenge()
            }
            return
        }
        for i in 0..<3 {
            if let slot = traySlots[safe: i],
               let badge = rerollBadges[safe: i] ?? nil {
                let slotPoint = slot.convert(point, from: self)
                if expandedHitContains(badge, pointInParent: slotPoint, minimumSize: CGSize(width: 44, height: 44), padding: 10) {
                    requestReroll(at: i)
                    return
                }
            }
            guard traySlotFrames[safe: i]?.contains(point) == true,
                  let piece = engine.pieces[safe: i] as? HexPiece else { continue }
            startDrag(piece: piece, slot: i, at: point)
            return
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, dragPiece != nil else { return }
        moveDrag(to: touch.location(in: self))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        endDrag(at: touch.location(in: self))
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelDrag()
    }

    private func startDrag(piece: HexPiece, slot: Int, at point: CGPoint) {
        hideUtilitySurface()
        AudioService.shared.play(.piecePickup)
        dragPiece = piece
        dragSlotIndex = slot
        dragAnchor = nil
        lastDragHighlightAnchor = nil
        lastDragHighlightValid = nil
        dragHighlightedCells.removeAll()
        syncOnboardingSurface()
        let node = makeDragNode(piece)
        node.position = point
        node.alpha = 0.92
        node.zPosition = 150
        addChild(node)
        dragNode = node
        trayPreviews[safe: slot]??.alpha = 0.2
    }

    private func moveDrag(to point: CGPoint) {
        guard let piece = dragPiece else { return }
        if let anchor = HexGeometry.nearestCoordinate(
            to: point, origin: gridOrigin, cols: cols, rows: rows
        ) {
            dragAnchor = anchor
            dragNode?.position = anchorScenePosition(anchor)
            let preview = engine.previewPlacementBundle(piece, at: anchor)
            guard anchor != lastDragHighlightAnchor || preview.resolution.isLegal != lastDragHighlightValid else { return }
            lastDragHighlightAnchor = anchor
            lastDragHighlightValid = preview.resolution.isLegal
            highlightCells(resolution: preview.resolution, evaluation: preview.evaluation)
        } else {
            dragAnchor = nil
            dragNode?.position = point
            guard lastDragHighlightAnchor != nil || !dragHighlightedCells.isEmpty else { return }
            clearHighlights()
        }
    }

    private func endDrag(at point: CGPoint) {
        defer {
            dragPiece = nil
            dragSlotIndex = -1
            dragAnchor = nil
            lastDragHighlightAnchor = nil
            lastDragHighlightValid = nil
            dragNode?.removeFromParent()
            dragNode = nil
            clearHighlights()
        }
        guard let piece = dragPiece,
              let anchor = dragAnchor ?? HexGeometry.nearestCoordinate(
                to: point, origin: gridOrigin, cols: cols, rows: rows
              ) else {
            HapticsService.shared.playInvalid()
            AudioService.shared.play(.invalidPlace)
            syncTray()
            return
        }
        let preview = engine.previewPlacement(piece, at: anchor)
        guard preview.isLegal else {
            HapticsService.shared.playInvalid()
            AudioService.shared.play(.invalidPlace)
            syncTray()
            return
        }
        let prevScore = engine.scoreEngine.score
        let prevCombo = engine.scoreEngine.combo
        let committed = engine.place(piece, at: anchor, slotIndex: dragSlotIndex)

        OnboardingService.shared.markPlacementLearned()
        Self.playCommitPlaceHaptic(Self.moveQualityCommitResponse(for: committed).commitHaptic)
        AudioService.shared.play(.validPlace)
        handlePostPlacementFeedback(
            placedCoords: committed.placedCoordinates,
            pieceColor: piece.color,
            previousScore: prevScore,
            previousCombo: prevCombo,
            clearedCoords: committed.clearedCellCoordinates,
            clearedLineCount: committed.clearedLineCount
        )
    }

    func cancelDrag() {
        dragNode?.removeFromParent()
        dragNode = nil
        dragPiece = nil
        dragSlotIndex = -1
        dragAnchor = nil
        lastDragHighlightAnchor = nil
        lastDragHighlightValid = nil
        clearHighlights()
        syncTray()
        syncOnboardingSurface()
    }

    private func highlightCells(resolution: PlacementResolution, evaluation: PlacementEvaluation?) {
        let coords = resolution.placedCoordinates
        guard coords.allSatisfy({ engine.board.isValid($0) }) else {
            for coord in dragHighlightedCells {
                restoreBoardCell(at: coord)
            }
            dragHighlightedCells.removeAll()
            return
        }
        let previewProfile = Self.dragPreviewProfile(for: resolution)
        let emphasizesOpeningRelief = Self.moveQualityDragResponse(
            evaluation: evaluation,
            previewProfile: previewProfile,
            isOpeningState: engine.placementEvaluationContext().isOpeningState
        ).emphasizesOpeningReliefOnDrag
        let clearCells = Set(resolution.clearedCellCoordinates)
        let nextCells = Set(coords).union(clearCells)
        for coord in dragHighlightedCells.subtracting(nextCells) {
            restoreBoardCell(at: coord)
        }
        dragHighlightedCells = nextCells
        for coord in nextCells {
            guard let node = cellNodes[coord] else { continue }
            node.childNode(withName: "board.emptyMaterial")?.isHidden = true
            switch previewProfile {
            case .invalidPlacement:
                node.fillColor = UIColor(hex: "E8DFF7").withAlphaComponent(0.09)
                node.strokeColor = UIColor.white.withAlphaComponent(0.16)
                node.lineWidth = 0.9
                node.alpha = 0.76
                if !prefersReducedMotion {
                    node.setScale(0.985)
                }
            case .validPlacement:
                node.fillColor = UIColor(hex: emphasizesOpeningRelief ? "B7EFD8" : "9CE7D2").withAlphaComponent(emphasizesOpeningRelief ? 0.28 : 0.2)
                node.strokeColor = UIColor.white.withAlphaComponent(emphasizesOpeningRelief ? 0.4 : 0.3)
                node.lineWidth = emphasizesOpeningRelief ? 1.52 : 1.28
                node.alpha = 1.0
                if !prefersReducedMotion {
                    node.setScale(emphasizesOpeningRelief ? 1.03 : 1.012)
                }
            case .clearPlacement:
                let isClearingCell = clearCells.contains(coord)
                node.fillColor = UIColor(hex: isClearingCell ? "C5F4E4" : "9CE7D2").withAlphaComponent(isClearingCell ? 0.3 : 0.22)
                node.strokeColor = UIColor.white.withAlphaComponent(isClearingCell ? 0.44 : 0.3)
                node.lineWidth = isClearingCell ? 1.55 : 1.25
                node.alpha = isClearingCell ? 1.0 : 0.96
                if !prefersReducedMotion {
                    node.setScale(isClearingCell ? 1.028 : 1.012)
                }
            case .multiClearPlacement:
                let isClearingCell = clearCells.contains(coord)
                node.fillColor = UIColor(hex: isClearingCell ? "D8FBEE" : "AEEFD9").withAlphaComponent(isClearingCell ? 0.34 : 0.24)
                node.strokeColor = UIColor.white.withAlphaComponent(isClearingCell ? 0.5 : 0.34)
                node.lineWidth = isClearingCell ? 1.72 : 1.32
                node.alpha = isClearingCell ? 1.0 : 0.98
                if !prefersReducedMotion {
                    node.setScale(isClearingCell ? 1.036 : 1.016)
                }
            }
        }
        if let dragNode, let piece = dragPiece {
            applyDragSurfaceState(
                dragNode,
                color: piece.color,
                previewProfile: previewProfile,
                emphasizesOpeningRelief: emphasizesOpeningRelief
            )
        }
    }

    private func clearHighlights() {
        for coord in dragHighlightedCells {
            restoreBoardCell(at: coord)
        }
        dragHighlightedCells.removeAll()
        lastDragHighlightAnchor = nil
        lastDragHighlightValid = nil
    }

    private func restoreBoardCell(at coord: HexCoordinate) {
        guard let node = cellNodes[coord] else { return }
        if let color = engine.board.color(at: coord) {
            applyFilledCellStyle(node, color: color)
        } else {
            applyEmptyCellAppearance(for: coord, node: node)
        }
    }

    private func animateClear(coords: [HexCoordinate], completion: @escaping () -> Void) {
        guard !coords.isEmpty else {
            completion()
            return
        }

        let bounds = HexGeometry.boardBounds(cols: cols, rows: rows)
        let boardCenter = CGPoint(x: gridOrigin.x + bounds.midX, y: gridOrigin.y + bounds.midY)
        let sorted = coords.sorted {
            let lhs = HexGeometry.pixelCenter(for: $0, origin: gridOrigin)
            let rhs = HexGeometry.pixelCenter(for: $1, origin: gridOrigin)
            let lhsDistance = hypot(lhs.x - boardCenter.x, lhs.y - boardCenter.y)
            let rhsDistance = hypot(rhs.x - boardCenter.x, rhs.y - boardCenter.y)
            return lhsDistance < rhsDistance
        }

        for (index, coord) in sorted.enumerated() {
            guard let node = cellNodes[coord] else { continue }
            node.removeAllActions()
            let wait = SKAction.wait(forDuration: TimeInterval(index) * 0.03)
            let flash = SKAction.group([
                SKAction.run {
                    node.alpha = 1.0
                    node.fillColor = UIColor(white: 1, alpha: 0.9)
                    node.strokeColor = UIColor.white.withAlphaComponent(0.34)
                    node.lineWidth = 1.2
                },
                SKAction.scale(to: 1.05, duration: 0.05)
            ])
            let settle = SKAction.group([
                SKAction.scale(to: 0.98, duration: 0.05),
                SKAction.wait(forDuration: 0.05)
            ])
            let shatter = SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.13),
                SKAction.fadeAlpha(to: 0.0, duration: 0.13)
            ])
            let restore = SKAction.run { [weak self] in
                guard let self else { return }
                node.setScale(1.0)
                node.alpha = 1.0
                self.applyEmptyCellAppearance(for: coord, node: node)
            }
            node.run(SKAction.sequence([wait, flash, settle, shatter, restore]))
        }

        let total = TimeInterval(max(0, sorted.count - 1)) * 0.03 + 0.23
        run(SKAction.sequence([
            SKAction.wait(forDuration: total),
            SKAction.run(completion)
        ]))
    }
    private func handleFirstClearComprehensionIfNeeded(
        clearedCoords: [HexCoordinate],
        clearedLineCount: Int,
        chainAdvanced: Bool
    ) {
        guard Self.shouldShowFirstClearMasteryHint(
            clearedCellCount: clearedCoords.count,
            clearedLineCount: clearedLineCount,
            chainAdvanced: chainAdvanced,
            shouldShowClearHint: OnboardingService.shared.shouldShowClearHint
        ) else { return }
        OnboardingService.shared.markClearLearned()
        showTransientOnboardingHint(VexloStrings.Onboarding.completeLine)
    }

    private func presentPostClearMasteryCuesIfNeeded(clearedLineCount: Int, chainAdvanced: Bool) {
        let chainCount = engine.scoreEngine.combo
        guard let cueText = Self.masteryEventCueText(clearedLineCount: clearedLineCount, chainCount: chainCount) else {
            return
        }
        showEventCue(cueText)
        showFirstChainMasteryHintIfNeeded(
            clearedLineCount: clearedLineCount,
            chainCount: chainCount,
            chainAdvanced: chainAdvanced
        )
    }

    private func showFirstChainMasteryHintIfNeeded(clearedLineCount: Int, chainCount: Int, chainAdvanced: Bool) {
        guard Self.shouldShowFirstChainMasteryHint(
            clearedLineCount: clearedLineCount,
            chainCount: chainCount,
            chainAdvanced: chainAdvanced,
            hasShownHint: hasShownChainMasteryHint
        ) else { return }
        hasShownChainMasteryHint = true
        run(.sequence([
            .wait(forDuration: prefersReducedMotion ? 0.2 : 0.26),
            .run { [weak self] in
                self?.showTransientOnboardingHint(VexloStrings.Onboarding.chainBuildsScore)
            }
        ]))
    }

    private func applyOnboardingCueStyle(isTransient: Bool) {
        onboardingLabel.fontColor = UIColor(hex: isTransient ? "FDFDFF" : "F6F7FF").withAlphaComponent(isTransient ? 0.982 : 0.92)
        onboardingLabel.fontSize = isTransient ? 16.1 : 15.3
        onboardingLabel.zPosition = isTransient ? 32 : 30
        onboardingLabel.position = CGPoint(
            x: size.width * 0.5,
            y: trayBottom + slotH + (isTransient ? 50 : 46)
        )
        onboardingLabel.setScale(1.0)
    }

    private func comboCuePosition() -> CGPoint {
        CGPoint(x: size.width * 0.5, y: modeLabel.position.y - (size.height < 760 ? 24 : 26))
    }

    func label(
        _ text: String,
        size: CGFloat,
        color: UIColor = .white,
        alpha: CGFloat = 1,
        align: SKLabelHorizontalAlignmentMode = .left,
        weight: Bool = false
    ) -> SKLabelNode {
        let node = SKLabelNode(fontNamed: weight ? "SFProDisplay-Bold" : "SFProText-Regular")
        node.text = text
        node.fontSize = size
        node.fontColor = color.withAlphaComponent(alpha)
        node.horizontalAlignmentMode = align
        node.verticalAlignmentMode = .top
        return node
    }

    func fitLabelWidth(_ label: SKLabelNode, maxWidth: CGFloat, minimumScale: CGFloat) {
        label.xScale = 1
        guard maxWidth > 0 else { return }
        let width = label.frame.width
        guard width > maxWidth, width > 0 else { return }
        label.xScale = max(minimumScale, maxWidth / width)
    }

    static func comboCueText(for clearedLineCount: Int) -> String {
        VexloStrings.Onboarding.comboClear(clearedLineCount)
    }

    static func chainCueText(for chainCount: Int) -> String {
        VexloStrings.Onboarding.chainStreak(chainCount)
    }

    static func masteryEventCueText(clearedLineCount: Int, chainCount: Int) -> String? {
        if clearedLineCount > 1 {
            return comboCueText(for: clearedLineCount)
        }
        if chainCount > 1 {
            return chainCueText(for: chainCount)
        }
        return nil
    }

    static func shouldShowResultGames(
        isResultOverlayCapture: Bool,
        showsGames: Bool,
        canShare: Bool,
        showsContinue: Bool
    ) -> Bool {
        !isResultOverlayCapture && showsGames && !canShare && !showsContinue
    }

    static func shouldShowResultProgress(showsProgress: Bool, progressText: String?) -> Bool {
        showsProgress && !(progressText?.isEmpty ?? true)
    }

    static func shouldShowResultShare(canShare: Bool, showsContinue: Bool) -> Bool {
        canShare && !showsContinue
    }

    static func normalOpeningModeLabelText() -> String {
        VexloStrings.HUD.boardReading
    }

    static func editorialRunCharacter(maxCombo: Int, didClearAny: Bool, hasUsedContinue: Bool) -> String {
        if hasUsedContinue {
            return VexloStrings.Overlay.runRecoveredLate
        }
        if maxCombo >= 2 {
            return VexloStrings.Overlay.runChainLed
        }
        if didClearAny {
            return VexloStrings.Overlay.runSteadyClears
        }
        return VexloStrings.Overlay.runTightBoard
    }

    static func quietNearMissMasteryLine(
        score: Int,
        best: Int,
        maxCombo: Int,
        didClearAny: Bool,
        hasUsedContinue: Bool
    ) -> String? {
        let gap = best - score
        guard gap > 0,
              gap <= 30,
              maxCombo >= 2,
              didClearAny,
              !hasUsedContinue else {
            return nil
        }
        return VexloStrings.Overlay.oneCleanerRun
    }

    static func shouldShowFirstChainMasteryHint(
        clearedLineCount: Int,
        chainCount: Int,
        chainAdvanced: Bool,
        hasShownHint: Bool
    ) -> Bool {
        chainAdvanced && clearedLineCount <= 1 && chainCount > 1 && !hasShownHint
    }

    static func shouldShowFirstClearMasteryHint(
        clearedCellCount: Int,
        clearedLineCount: Int,
        chainAdvanced: Bool,
        shouldShowClearHint: Bool
    ) -> Bool {
        clearedCellCount > 0 && clearedLineCount <= 1 && !chainAdvanced && shouldShowClearHint
    }

    private func applyEmptyCellAppearance(for coord: HexCoordinate, node: SKShapeNode) {
        applyEmptyCellStyle(node)
        let isOpeningState = engine.scoreEngine.score == 0 && !engine.didClearAny
        guard Self.shouldApplyBoardWhisper(
            isOpeningState: isOpeningState,
            isTerminal: terminalOverlayOwnsResultContext
        ),
        let whisper = boardPressureSnapshot?.cellWhisper[coord] else { return }
        Self.applyBoardWhisper(
            to: emptyCellMaterialNode(in: node),
            strokeOn: node,
            whisper: whisper
        )
    }

    private func applyEmptyCellStyle(_ node: SKShapeNode) {
        let isOpeningState = engine.scoreEngine.score == 0 && !engine.didClearAny
        let isTerminal = terminalOverlayOwnsResultContext
        let isCompactTerminal = isTerminal && size.height < 760
        let isWeakScoreTerminal = isTerminal && !engine.isDailyChallenge && engine.scoreEngine.score < 10
        node.fillColor = UIColor.white.withAlphaComponent(
            isTerminal ? (isWeakScoreTerminal ? 0.016 : 0.02) : (isOpeningState ? 0.058 : 0.049)
        )
        node.strokeColor = UIColor(hex: "B9C3E6").withAlphaComponent(
            isTerminal ? (isWeakScoreTerminal ? 0.068 : 0.094) : (isOpeningState ? 0.136 : 0.118)
        )
        node.lineWidth = 0.9
        node.alpha = isTerminal ? (isWeakScoreTerminal ? (isCompactTerminal ? 0.38 : 0.44) : (isCompactTerminal ? 0.46 : 0.52)) : 1.0
        node.setScale(1.0)
        let material = emptyCellMaterialNode(in: node)
        material.isHidden = false
        material.fillColor = UIColor(hex: engine.isDailyChallenge ? "F8FBFF" : "A8B4FF").withAlphaComponent(
            isTerminal ? (
                isWeakScoreTerminal
                    ? (isCompactTerminal ? (engine.isDailyChallenge ? 0.001 : 0.0008) : (engine.isDailyChallenge ? 0.0014 : 0.0011))
                    : (isCompactTerminal ? (engine.isDailyChallenge ? 0.0015 : 0.0012) : (engine.isDailyChallenge ? 0.002 : 0.0016))
            ) :
                (isOpeningState ? (engine.isDailyChallenge ? 0.026 : 0.02) : (engine.isDailyChallenge ? 0.018 : 0.014))
        )
        material.strokeColor = UIColor.clear
        if let h = node.childNode(withName: "fillHighlight") as? SKShapeNode { h.isHidden = true }
    }

    private func applyFilledCellStyle(_ node: SKShapeNode, color: UIColor) {
        let isTerminal = terminalOverlayOwnsResultContext
        let isCompactTerminal = isTerminal && size.height < 760
        let isWeakScoreTerminal = isTerminal && !engine.isDailyChallenge && engine.scoreEngine.score < 10
        node.childNode(withName: "board.emptyMaterial")?.isHidden = true
        applyPieceSurfaceStyle(node, color: color, emphasis: .board)
        if isTerminal {
            node.alpha = isWeakScoreTerminal ? (isCompactTerminal ? 0.13 : 0.17) : (isCompactTerminal ? 0.16 : 0.20)
            node.strokeColor = UIColor.white.withAlphaComponent(
                isWeakScoreTerminal ? (isCompactTerminal ? 0.022 : 0.032) : (isCompactTerminal ? 0.036 : 0.05)
            )
            node.lineWidth = 1.0
        }
        if let highlight = node.childNode(withName: "fillHighlight") as? SKShapeNode {
            highlight.isHidden = false
            highlight.fillColor = UIColor(
                white: 1,
                alpha: isTerminal ? (isWeakScoreTerminal ? (isCompactTerminal ? 0.005 : 0.008) : (isCompactTerminal ? 0.009 : 0.014)) : 0.148
            )
        } else {
            let highlight = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius * 0.68))
            highlight.name = "fillHighlight"
            highlight.fillColor = UIColor(
                white: 1,
                alpha: isTerminal ? (isWeakScoreTerminal ? (isCompactTerminal ? 0.005 : 0.008) : (isCompactTerminal ? 0.009 : 0.014)) : 0.148
            )
            highlight.strokeColor = .clear
            highlight.lineWidth = 0
            highlight.position = CGPoint(x: 0, y: HexGeometry.radius * 0.15)
            highlight.zPosition = 2
            node.addChild(highlight)
        }
    }

    private func emptyCellMaterialNode(in node: SKShapeNode) -> SKShapeNode {
        if let material = node.childNode(withName: "board.emptyMaterial") as? SKShapeNode {
            return material
        }
        let material = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius * 0.42))
        material.name = "board.emptyMaterial"
        material.lineWidth = 0
        material.zPosition = -0.1
        node.addChild(material)
        return material
    }

    private func applyTraySlotStyle(_ slot: SKShapeNode, occupied: Bool) {
        slot.alpha = occupied ? 1 : 0.92
        slot.fillColor = occupied
            ? UIColor(hex: "16162F").withAlphaComponent(0.96)
            : UIColor(hex: "111124").withAlphaComponent(0.88)
        slot.strokeColor = occupied
            ? UIColor(hex: "303052").withAlphaComponent(0.92)
            : UIColor(hex: "232342").withAlphaComponent(0.7)

        if let inner = slot.childNode(withName: "slot.inner") as? SKShapeNode {
            inner.alpha = occupied ? 1 : 0.7
        }
        if let sheen = slot.childNode(withName: "slot.sheen") as? SKShapeNode {
            sheen.alpha = occupied ? 0.95 : 0.45
        }
        if let restMark = slot.childNode(withName: "slot.restMark") as? SKShapeNode {
            restMark.isHidden = occupied
            restMark.alpha = occupied ? 0 : 1
        }
    }

    private enum PieceSurfaceEmphasis {
        case tray
        case board
        case dragNeutral
        case dragValid
        case dragInvalid
    }

    private func applyPieceSurfaceStyle(_ node: SKShapeNode, color: UIColor, emphasis: PieceSurfaceEmphasis) {
        switch emphasis {
        case .tray:
            node.fillColor = color.withAlphaComponent(0.98)
            node.strokeColor = UIColor.white.withAlphaComponent(0.16)
            node.lineWidth = 0.62
            node.alpha = 1.0
            node.setScale(1.0)
        case .board:
            node.fillColor = color.withAlphaComponent(0.975)
            node.strokeColor = UIColor.white.withAlphaComponent(0.3)
            node.lineWidth = 1.18
            node.alpha = 1.0
            node.setScale(1.0)
        case .dragNeutral:
            node.fillColor = color.withAlphaComponent(0.9)
            node.strokeColor = UIColor.white.withAlphaComponent(0.24)
            node.lineWidth = 0.95
            node.alpha = 0.94
            node.setScale(1.0)
        case .dragValid:
            node.fillColor = color.withAlphaComponent(0.96)
            node.strokeColor = UIColor.white.withAlphaComponent(0.38)
            node.lineWidth = 1.1
            node.alpha = 1.0
            node.setScale(prefersReducedMotion ? 1.0 : 1.015)
        case .dragInvalid:
            node.fillColor = color.withAlphaComponent(0.62)
            node.strokeColor = UIColor.white.withAlphaComponent(0.1)
            node.lineWidth = 0.78
            node.alpha = 0.74
            node.setScale(prefersReducedMotion ? 1.0 : 0.99)
        }
    }

    private func applyDragSurfaceState(
        _ dragNode: SKNode,
        color: UIColor,
        previewProfile: DragPreviewProfile,
        emphasizesOpeningRelief: Bool = false
    ) {
        let emphasis: PieceSurfaceEmphasis
        switch previewProfile {
        case .invalidPlacement:
            emphasis = .dragInvalid
        case .validPlacement:
            emphasis = .dragValid
        case .clearPlacement, .multiClearPlacement:
            emphasis = .dragValid
        }
        for case let hex as SKShapeNode in dragNode.children where hex.name == "piece.hex" {
            applyPieceSurfaceStyle(hex, color: color, emphasis: emphasis)
            switch previewProfile {
            case .clearPlacement:
                hex.fillColor = color.withAlphaComponent(0.994)
                hex.strokeColor = UIColor.white.withAlphaComponent(0.475)
                hex.lineWidth = 1.24
                if !prefersReducedMotion {
                    hex.setScale(1.034)
                }
            case .multiClearPlacement:
                hex.fillColor = color.withAlphaComponent(1.0)
                hex.strokeColor = UIColor.white.withAlphaComponent(0.585)
                hex.lineWidth = 1.38
                if !prefersReducedMotion {
                    hex.setScale(1.05)
                }
            case .validPlacement where emphasizesOpeningRelief:
                hex.fillColor = color.withAlphaComponent(0.978)
                hex.strokeColor = UIColor.white.withAlphaComponent(0.43)
                hex.lineWidth = 1.16
                if !prefersReducedMotion {
                    hex.setScale(1.024)
                }
            default:
                break
            }
        }
        for case let glint as SKShapeNode in dragNode.children where glint.name == "piece.glint" {
            switch previewProfile {
            case .invalidPlacement:
                glint.fillColor = UIColor.white.withAlphaComponent(0.05)
                glint.alpha = 0.7
            case .validPlacement:
                glint.fillColor = UIColor.white.withAlphaComponent(emphasizesOpeningRelief ? 0.156 : 0.122)
                glint.alpha = emphasizesOpeningRelief ? 0.92 : 0.88
            case .clearPlacement:
                glint.fillColor = UIColor.white.withAlphaComponent(0.262)
                glint.alpha = 1.0
            case .multiClearPlacement:
                glint.fillColor = UIColor.white.withAlphaComponent(0.355)
                glint.alpha = 1.0
            }
        }
        for case let core as SKShapeNode in dragNode.children where core.name == "piece.core" {
            switch previewProfile {
            case .invalidPlacement:
                core.fillColor = UIColor.white.withAlphaComponent(0.025)
                core.strokeColor = UIColor.white.withAlphaComponent(0.02)
                core.alpha = 0.7
            case .validPlacement:
                core.fillColor = UIColor.white.withAlphaComponent(emphasizesOpeningRelief ? 0.048 : 0.034)
                core.strokeColor = UIColor.white.withAlphaComponent(emphasizesOpeningRelief ? 0.038 : 0.028)
                core.alpha = emphasizesOpeningRelief ? 0.84 : 0.79
                core.setScale(prefersReducedMotion ? 1.0 : (emphasizesOpeningRelief ? 0.994 : 0.986))
            case .clearPlacement:
                core.fillColor = UIColor.white.withAlphaComponent(0.132)
                core.strokeColor = UIColor.white.withAlphaComponent(0.106)
                core.alpha = 1.0
                core.setScale(prefersReducedMotion ? 1.0 : 1.038)
            case .multiClearPlacement:
                core.fillColor = UIColor.white.withAlphaComponent(0.192)
                core.strokeColor = UIColor.white.withAlphaComponent(0.154)
                core.alpha = 1.0
                core.setScale(prefersReducedMotion ? 1.0 : 1.06)
            }
        }
        switch previewProfile {
        case .invalidPlacement:
            dragNode.alpha = 0.86
            dragNode.setScale(1.0)
        case .validPlacement:
            dragNode.alpha = emphasizesOpeningRelief ? 0.99 : 0.975
            dragNode.setScale(prefersReducedMotion ? 1.0 : (emphasizesOpeningRelief ? 1.008 : 1.0))
        case .clearPlacement:
            dragNode.alpha = 1.0
            dragNode.setScale(prefersReducedMotion ? 1.0 : 1.032)
        case .multiClearPlacement:
            dragNode.alpha = 1.0
            dragNode.setScale(prefersReducedMotion ? 1.0 : 1.054)
        }
    }

    private func buildAtmosphere() {
        children.filter {
            guard let name = $0.name else { return false }
            return name.hasPrefix("atmosphere.")
        }.forEach { $0.removeFromParent() }

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let topGlow = SKShapeNode(ellipseOf: CGSize(width: size.width * 1.02, height: size.height * 0.3))
        topGlow.name = "atmosphere.topGlow"
        topGlow.fillColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.022)
        topGlow.strokeColor = .clear
        topGlow.position = CGPoint(x: center.x, y: size.height * 0.845)
        topGlow.zPosition = -12
        addChild(topGlow)

        let boardAura = SKShapeNode(circleOfRadius: min(size.width, size.height) * 0.29)
        boardAura.name = "atmosphere.boardAura"
        boardAura.fillColor = UIColor(hex: "7A74F7").withAlphaComponent(0.022)
        boardAura.strokeColor = .clear
        boardAura.position = CGPoint(x: center.x, y: gridOrigin.y + HexGeometry.boardBounds(cols: cols, rows: rows).midY)
        boardAura.zPosition = -11
        addChild(boardAura)

        let lowerVeil = SKShapeNode(rectOf: CGSize(width: size.width * 1.08, height: size.height * 0.24), cornerRadius: size.height * 0.08)
        lowerVeil.name = "atmosphere.lowerVeil"
        lowerVeil.fillColor = UIColor.black.withAlphaComponent(0.12)
        lowerVeil.strokeColor = .clear
        lowerVeil.position = CGPoint(x: center.x, y: size.height * 0.14)
        lowerVeil.zPosition = -10
        addChild(lowerVeil)

        let brandFacet = SKShapeNode(path: HexGeometry.hexPath(radius: size.height < 760 ? 7 : 8))
        brandFacet.name = "atmosphere.brandFacet"
        brandFacet.fillColor = UIColor(hex: "C7D0FF").withAlphaComponent(0.035)
        brandFacet.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.08)
        brandFacet.lineWidth = 0.8
        brandFacet.position = CGPoint(x: size.width * 0.5 + (size.height < 760 ? 58 : 64), y: layoutMetrics.titleAccentY + 1)
        brandFacet.zPosition = -1
        addChild(brandFacet)
    }

    private func updateAccessibilitySurfaces() {
        configureAccessibility(
            utilityButton,
            label: VexloStrings.Accessibility.utilityMenu,
            help: VexloStrings.Accessibility.utilityMenuHint,
            enabled: !utilityButton.isHidden && !isInteractionLocked && dragPiece == nil
        )
        configureAccessibility(
            modeLabel,
            label: engine.isDailyChallenge ? VexloStrings.Accessibility.modeSwitchToMain : VexloStrings.Accessibility.modeSwitchToDaily,
            help: engine.isDailyChallenge ? VexloStrings.Accessibility.modeSwitchToMainHint : VexloStrings.Accessibility.modeSwitchToDailyHint,
            enabled: dragPiece == nil && overlayNode.isHidden
        )

        let soundState = AudioService.shared.isEnabled ? VexloStrings.Accessibility.on : VexloStrings.Accessibility.off
        configureAccessibility(
            utilitySoundLabel,
            label: "\(VexloStrings.Accessibility.soundState), \(soundState)",
            enabled: !utilitySoundLabel.isHidden
        )

        let hapticsState = HapticsService.shared.isEnabled ? VexloStrings.Accessibility.on : VexloStrings.Accessibility.off
        configureAccessibility(
            utilityHapticsLabel,
            label: "\(VexloStrings.Accessibility.hapticsState), \(hapticsState)",
            enabled: !utilityHapticsLabel.isHidden
        )

        configureAccessibility(
            utilitySupporterLabel,
            label: VexloStrings.Overlay.supporterPack,
            help: VexloStrings.Accessibility.supporterPackHint,
            enabled: !utilitySupporterLabel.isHidden && !isPresentingSupporterPurchase
        )
        configureAccessibility(
            utilityRestoreLabel,
            label: VexloStrings.Overlay.restorePurchases,
            help: VexloStrings.Accessibility.restorePurchasesHint,
            enabled: !utilityRestoreLabel.isHidden && !isPresentingSupporterPurchase
        )
        configureAccessibility(
            utilityExportLabel,
            label: VexloStrings.Overlay.exportDiagnostics,
            help: VexloStrings.Accessibility.exportDiagnosticsHint,
            enabled: !utilityExportLabel.isHidden
        )
        configureAccessibility(
            utilityNewRunLabel,
            label: VexloStrings.Accessibility.startNewRun,
            help: VexloStrings.Accessibility.startNewRunHint,
            enabled: !utilityNewRunLabel.isHidden && !isPresentingNewRunConfirmation
        )

        let progressLabel = engine.isDailyChallenge ? VexloStrings.Accessibility.modeSwitchToMain : VexloStrings.Accessibility.leaderboard
        let progressHelp = engine.isDailyChallenge ? VexloStrings.Accessibility.modeSwitchToMainHint : VexloStrings.Accessibility.leaderboardHint
        configureAccessibility(
            overlayProgressLabel,
            label: progressLabel,
            help: progressHelp,
            enabled: !overlayProgressLabel.isHidden && overlayNode.isHidden == false && !isInteractionLocked
        )

        let gamesLabel: String
        let gamesHelp: String
        if engine.isDailyChallenge {
            gamesLabel = VexloStrings.Accessibility.dailyActivity
            gamesHelp = VexloStrings.Accessibility.dailyActivityHint
        } else if GameCenterService.shared.canPresentScoreChallenge && engine.scoreEngine.score > 0 {
            gamesLabel = VexloStrings.Accessibility.challengeFriends
            gamesHelp = VexloStrings.Accessibility.challengeFriendsHint
        } else {
            gamesLabel = VexloStrings.Accessibility.playTogether
            gamesHelp = VexloStrings.Accessibility.playTogetherHint
        }
        configureAccessibility(
            overlayGamesLabel,
            label: gamesLabel,
            help: gamesHelp,
            enabled: !overlayGamesLabel.isHidden && overlayNode.isHidden == false && !isInteractionLocked
        )
        configureAccessibility(
            overlayShareLabel,
            label: VexloStrings.Accessibility.shareResult,
            help: VexloStrings.Accessibility.shareResultHint,
            enabled: !overlayShareLabel.isHidden && overlayNode.isHidden == false && !isInteractionLocked
        )

        configureAccessibility(
            overlayContinueButton,
            label: VexloStrings.Overlay.continueRun,
            help: VexloStrings.Accessibility.continueRunHint,
            enabled: !overlayContinueButton.isHidden && !isPresentingContinue && !isRestarting
        )
        if let restart = overlayNode.childNode(withName: "restart") {
            configureAccessibility(
                restart,
                label: VexloStrings.Overlay.playAgain,
                help: VexloStrings.Accessibility.playAgainHint,
                enabled: !isRestarting && !isPresentingContinue
            )
        }

        let resultSummary = engine.isDailyChallenge ? VexloStrings.Accessibility.dailyCompleteSummary : VexloStrings.Accessibility.gameOverSummary
        configureAccessibility(
            overlayScoreLabel,
            label: "\(resultSummary), \(engine.scoreEngine.score)",
            enabled: !overlayNode.isHidden
        )
        configureAccessibility(
            overlayBadgeLabel,
            label: overlayBadgeLabel.text?.isEmpty == false ? overlayBadgeLabel.text : nil,
            enabled: !overlayNode.isHidden && overlayBadgeLabel.text?.isEmpty == false
        )

        for badge in rerollBadges {
            guard let badge else { continue }
            configureAccessibility(
                badge,
                label: VexloStrings.Accessibility.rerollPiece,
                help: VexloStrings.Accessibility.rerollPieceHint,
                enabled: !isInteractionLocked && dragPiece == nil
            )
        }
    }

    private func configureAccessibility(
        _ node: SKNode,
        label: String?,
        help: String? = nil,
        enabled: Bool
    ) {
        let visible = !node.isHidden && node.alpha > 0.01 && !node.calculateAccumulatedFrame().isEmpty
        node.isAccessibilityElement = enabled && visible && label != nil
        node.accessibilityLabel = label
        node.accessibilityHint = help
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
