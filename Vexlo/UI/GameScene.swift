import SpriteKit
import UIKit

final class GameScene: SKScene {

    static let shared: GameScene = {
        let s = GameScene(size: UIScreen.main.bounds.size)
        s.scaleMode = .resizeFill
        return s
    }()

    private let engine = GameEngine()
    private var cellNodes: [HexCoordinate: SKShapeNode] = [:]
    private var traySlots: [SKShapeNode] = []
    private var traySlotFrames: [CGRect] = []
    private var trayPreviews: [SKNode?] = [nil, nil, nil]
    private var rerollBadges: [SKNode?] = [nil, nil, nil]
    private var dragNode: SKNode?
    private var dragPiece: HexPiece?
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
    private var utilityButton = SKShapeNode()
    private var utilityMenuNode = SKNode()
    private var utilityMenuBackground = SKShapeNode()
    private var utilitySoundLabel = SKLabelNode()
    private var utilityHapticsLabel = SKLabelNode()
    private var utilitySupporterLabel = SKLabelNode()
    private var utilityRestoreLabel = SKLabelNode()
    private var utilityExportLabel = SKLabelNode()
    private var overlayNode = SKNode()
    private var overlayCaptionLabel = SKLabelNode()
    private var overlayScoreLabel = SKLabelNode()
    private var overlayDetailLabel = SKLabelNode()
    private var overlayBadgeLabel = SKLabelNode()
    private var overlayProgressLabel = SKLabelNode()
    private var overlayGamesLabel = SKLabelNode()
    private var overlayShareLabel = SKLabelNode()
    private var overlayContinueButton = SKShapeNode()
    private var overlaySupporterLabel = SKLabelNode()
    private var overlayRestoreLabel = SKLabelNode()
    private var overlayExportLabel = SKLabelNode()
    private var lastScoreValue: Int = 0
    private var lastBestValue: Int = 0
    private var isOverlayPresented = false
    private var isRestarting = false
    private var isPresentingContinue = false
    private var isPresentingReroll = false
    private var isPresentingSupporterPurchase = false
    private var hasFinalizedRun = false
    private var hasStartedMonetizationRun = false
    private var hasStartedAnalyticsRun = false
    private var isUtilityPresented = false
    private var hasRecordedContinueOfferForCurrentLoss = false
    private var visibleRerollOfferSlots: Set<Int> = []
    private var flowEpoch: Int = 0
    private var lastLayoutSignature: LayoutSignature?
    private var hasBuiltScene = false
    private var runStartBest: Int = 0
    private var lastDailyCompletion: DailyChallengeCompletion?
    private var hasAppliedCaptureState = false
    private var hasAttemptedPersistedRestore = false
    private var isShowingTransientOnboardingHint = false

    private let cols = 7
    private let rows = 7
    private let pad: CGFloat = 16
    private let slotH: CGFloat = 96
    private let slotSpacing: CGFloat = 12
    private let trayBottom: CGFloat = 80
    private let hudH: CGFloat = 64

    private var gridOrigin: CGPoint = .zero

    private struct LayoutMetrics {
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

    private var layoutMetrics: LayoutMetrics {
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
            y: topY - (compact ? 16 : 18)
        )
        let utilityPanelWidth = min(max(size.width - sideInset * 2 - 12, 188), compact ? 204 : 224)
        let actionWidth = min(max(size.width - sideInset * 2 - 28, 200), compact ? 216 : 228)
        return LayoutMetrics(
            sideInset: sideInset,
            topY: topY,
            modeY: topY - (compact ? 37 : 41),
            titleY: topY - (compact ? 10 : 11),
            titleAccentY: topY - (compact ? 22 : 24),
            utilityRadius: utilityRadius,
            utilityCenter: utilityCenter,
            utilityPanelWidth: utilityPanelWidth,
            utilityRowHeight: compact ? 33 : 35,
            utilityRowHitHeight: compact ? 44 : 46,
            utilityPanelTopInset: compact ? 16 : 17,
            utilityPanelBottomInset: compact ? 13 : 15,
            overlayCaptionOffset: compact ? 82 : 91,
            overlayScoreOffset: compact ? 20 : 23,
            overlayBadgeOffset: compact ? -31 : -36,
            overlayDetailOffset: compact ? -55 : -62,
            overlayActionsStartOffset: compact ? -82 : -92,
            overlaySecondarySpacing: compact ? 18 : 19,
            overlayContinueSize: CGSize(width: actionWidth, height: compact ? 46 : 48),
            overlayRestartSize: CGSize(width: actionWidth, height: compact ? 52 : 54),
            overlayScoreFontSize: compact ? 56 : 64,
            rerollBadgeInset: compact ? 16 : 18,
            boardVerticalBias: compact ? 0.53 : (tall ? 0.5 : 0.525)
        )
    }

    private var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    private var isInteractionLocked: Bool {
        isRestarting || isPresentingContinue || isPresentingReroll || isPresentingSupporterPurchase
    }

    private var canShowUtilityAffordance: Bool {
        (!LaunchSupport.shared.isCaptureMode || LaunchSupport.shared.isUtilitySurfaceCapture) &&
        overlayNode.isHidden &&
        !isOverlayPresented
    }

    private var isPublicEditorialCapture: Bool {
        LaunchSupport.shared.isCaptureMode && !LaunchSupport.shared.isInternalCapture
    }

    private var canShowFirstSessionHintSurface: Bool {
        !LaunchSupport.shared.isCaptureMode &&
        !engine.isDailyChallenge &&
        overlayNode.isHidden &&
        !isUtilityPresented &&
        !isInteractionLocked
    }

    private var terminalOverlayOwnsResultContext: Bool {
        engine.isGameOver || isOverlayPresented || !overlayNode.isHidden
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
            x: (size.width - bounds.width) * 0.5 - bounds.minX,
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
        bestLabel.position = CGPoint(x: metrics.sideInset, y: metrics.topY - 20)
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

        let titleFacet = SKShapeNode(path: HexGeometry.hexPath(radius: size.height < 760 ? 4.5 : 5))
        titleFacet.name = "hud.titleFacet"
        titleFacet.fillColor = UIColor(hex: "C7D0FF").withAlphaComponent(0.055)
        titleFacet.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.1)
        titleFacet.lineWidth = 0.8
        titleFacet.position = CGPoint(x: size.width * 0.5 - (size.height < 760 ? 22 : 25), y: metrics.titleAccentY + 1)
        addChild(titleFacet)

        scoreCaptionLabel = label(VexloStrings.HUD.score, size: 10.75, alpha: 0.31, align: .right)
        scoreCaptionLabel.name = "hud.scoreCaption"
        scoreCaptionLabel.position = CGPoint(x: size.width - metrics.sideInset - metrics.utilityRadius * 2 - 12, y: metrics.topY)
        addChild(scoreCaptionLabel)

        scoreLabel = label("0", size: 28, color: .white, align: .right, weight: true)
        scoreLabel.name = "hud.score"
        scoreLabel.position = CGPoint(x: size.width - metrics.sideInset - metrics.utilityRadius * 2 - 12, y: metrics.topY - 20)
        addChild(scoreLabel)

        comboCueLabel = label("", size: 12, color: UIColor(hex: "8EDFCB"), alpha: 0, align: .right, weight: true)
        comboCueLabel.name = "hud.comboCue"
        comboCueLabel.position = CGPoint(x: scoreLabel.position.x, y: metrics.topY - 48)
        comboCueLabel.isHidden = true
        addChild(comboCueLabel)

        modeLabel = label("", size: 10.75, alpha: 0.46, align: .center, weight: true)
        modeLabel.name = "hud.mode"
        modeLabel.position = CGPoint(x: size.width * 0.5, y: metrics.modeY)
        addChild(modeLabel)
    }

    private func buildUtilitySurface() {
        utilityButton.removeFromParent()
        utilityMenuNode.removeFromParent()
        let metrics = layoutMetrics

        utilityButton = SKShapeNode(circleOfRadius: metrics.utilityRadius)
        utilityButton.name = "utility.button"
        utilityButton.fillColor = UIColor(hex: "14142A").withAlphaComponent(0.62)
        utilityButton.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.09)
        utilityButton.lineWidth = 0.8
        utilityButton.position = metrics.utilityCenter
        utilityButton.zPosition = 240
        addChild(utilityButton)

        let utilityGlow = SKShapeNode(circleOfRadius: metrics.utilityRadius + 3)
        utilityGlow.name = "utility.glow"
        utilityGlow.fillColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.018)
        utilityGlow.strokeColor = .clear
        utilityGlow.zPosition = -1
        utilityButton.addChild(utilityGlow)

        let glyph = label("···", size: 15, color: .white, alpha: 0.54, align: .center, weight: true)
        glyph.verticalAlignmentMode = .center
        glyph.position = CGPoint(x: 0, y: -0.5)
        utilityButton.addChild(glyph)

        utilityMenuNode = SKNode()
        utilityMenuNode.zPosition = 241
        utilityMenuNode.isHidden = true
        utilityMenuNode.alpha = 0
        addChild(utilityMenuNode)

        utilityMenuBackground = SKShapeNode()
        utilityMenuBackground.fillColor = UIColor(hex: "12122A").withAlphaComponent(0.965)
        utilityMenuBackground.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.1)
        utilityMenuBackground.lineWidth = 1
        utilityMenuNode.addChild(utilityMenuBackground)

        utilitySoundLabel = label("", size: 13, alpha: 0.92, align: .left, weight: true)
        utilitySoundLabel.name = "utility.sound"
        utilityMenuNode.addChild(utilitySoundLabel)

        utilityHapticsLabel = label("", size: 13, alpha: 0.92, align: .left, weight: true)
        utilityHapticsLabel.name = "utility.haptics"
        utilityMenuNode.addChild(utilityHapticsLabel)

        utilitySupporterLabel = label(VexloStrings.Overlay.supporterPack, size: 13, alpha: 0.92, align: .left, weight: true)
        utilitySupporterLabel.name = "utility.supporter"
        utilityMenuNode.addChild(utilitySupporterLabel)

        utilityRestoreLabel = label(VexloStrings.Overlay.restorePurchases, size: 12, alpha: 0.7, align: .left, weight: true)
        utilityRestoreLabel.name = "utility.restore"
        utilityMenuNode.addChild(utilityRestoreLabel)

        utilityExportLabel = label(VexloStrings.Overlay.exportDiagnostics, size: 12, alpha: 0.64, align: .left, weight: true)
        utilityExportLabel.name = "utility.export"
        utilityMenuNode.addChild(utilityExportLabel)

        syncUtilitySurface()
    }

    private func buildOnboardingSurface() {
        onboardingLabel.removeFromParent()
        onboardingLabel = label("", size: 12, alpha: 0.58, align: .center, weight: true)
        onboardingLabel.name = "hud.onboarding"
        onboardingLabel.position = CGPoint(x: size.width * 0.5, y: trayBottom + slotH + 18)
        onboardingLabel.zPosition = 20
        onboardingLabel.isHidden = true
        onboardingLabel.alpha = 0
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
        halo.fillColor = UIColor(hex: "92A1FF").withAlphaComponent(0.024)
        halo.strokeColor = .clear
        halo.zPosition = -4
        addChild(halo)

        let backdrop = SKShapeNode(rect: boardRect, cornerRadius: 30)
        backdrop.name = "board.backdrop"
        backdrop.fillColor = UIColor(hex: "101020").withAlphaComponent(0.635)
        backdrop.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.072)
        backdrop.lineWidth = 1
        backdrop.zPosition = -3
        addChild(backdrop)

        let frame = SKShapeNode(rect: boardRect.insetBy(dx: 8, dy: 8), cornerRadius: 24)
        frame.name = "board.frame"
        frame.fillColor = UIColor.clear
        frame.strokeColor = UIColor.white.withAlphaComponent(0.048)
        frame.lineWidth = 1
        frame.zPosition = -2
        addChild(frame)

        let signatureFacetRadius: CGFloat = size.height < 760 ? 6.5 : 7.5
        let signatureFacetPositions = [
            CGPoint(x: boardRect.minX + 28, y: boardRect.maxY - 28),
            CGPoint(x: boardRect.maxX - 30, y: boardRect.minY + 30)
        ]
        for (index, position) in signatureFacetPositions.enumerated() {
            if index == 0 { continue }
            let facet = SKShapeNode(path: HexGeometry.hexPath(radius: signatureFacetRadius))
            facet.name = "board.signatureFacet.\(index)"
            facet.fillColor = UIColor(hex: index == 0 ? "C7D0FF" : "7A74F7").withAlphaComponent(0.032)
            facet.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.07)
            facet.lineWidth = 0.75
            facet.position = position
            facet.zPosition = -1.5
            addChild(facet)
        }

        for col in 0..<cols {
            for row in 0..<rows {
                let coord = HexCoordinate(col, row)
                let node = SKShapeNode(path: HexGeometry.hexPath(radius: HexGeometry.radius - 1))
                applyEmptyCellStyle(node)
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
        overlayNode.removeFromParent()
        overlayNode = SKNode()
        overlayNode.zPosition = 200
        overlayNode.isHidden = true
        overlayNode.alpha = 0
        addChild(overlayNode)

        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = UIColor(hex: "06060E").withAlphaComponent(0.40)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        overlayNode.addChild(bg)

        let metrics = layoutMetrics

        overlayCaptionLabel = label(VexloStrings.Overlay.gameOver, size: 12, alpha: 0.36, align: .center)
        overlayCaptionLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayCaptionOffset)
        overlayNode.addChild(overlayCaptionLabel)

        overlayScoreLabel = label("0", size: metrics.overlayScoreFontSize, color: .white, align: .center, weight: true)
        overlayScoreLabel.fontName = "SFProRounded-Heavy"
        overlayScoreLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayScoreOffset)
        overlayNode.addChild(overlayScoreLabel)

        overlayBadgeLabel = label("", size: 11, color: UIColor(hex: "6C5CE7"), alpha: 0.95, align: .center, weight: true)
        overlayBadgeLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayBadgeOffset)
        overlayNode.addChild(overlayBadgeLabel)

        overlayDetailLabel = label("", size: 13, alpha: 0.54, align: .center)
        overlayDetailLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayDetailOffset)
        overlayNode.addChild(overlayDetailLabel)

        overlayProgressLabel = label(VexloStrings.Overlay.gameCenter, size: 12, alpha: 0.44, align: .center, weight: true)
        overlayProgressLabel.name = "progress"
        overlayProgressLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset)
        overlayNode.addChild(overlayProgressLabel)

        overlayGamesLabel = label("", size: 12, alpha: 0.44, align: .center, weight: true)
        overlayGamesLabel.name = "games"
        overlayGamesLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - metrics.overlaySecondarySpacing)
        overlayGamesLabel.isHidden = true
        overlayNode.addChild(overlayGamesLabel)

        overlayShareLabel = label("↑  \(VexloStrings.Overlay.share)", size: 12.5, color: UIColor(hex: "6C5CE7"), align: .center, weight: true)
        overlayShareLabel.name = "share"
        overlayShareLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - metrics.overlaySecondarySpacing * 2)
        overlayShareLabel.isHidden = true
        overlayNode.addChild(overlayShareLabel)

        overlaySupporterLabel = label(VexloStrings.Overlay.supporterPack, size: 12, alpha: 0.56, align: .center, weight: true)
        overlaySupporterLabel.name = "supporter"
        overlaySupporterLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 - 114)
        overlaySupporterLabel.isHidden = true
        overlayNode.addChild(overlaySupporterLabel)

        overlayRestoreLabel = label(VexloStrings.Overlay.restorePurchases, size: 11, alpha: 0.38, align: .center, weight: true)
        overlayRestoreLabel.name = "restore"
        overlayRestoreLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 - 132)
        overlayRestoreLabel.isHidden = true
        overlayNode.addChild(overlayRestoreLabel)

        overlayExportLabel = label(VexloStrings.Overlay.exportDiagnostics, size: 11, alpha: 0.36, align: .center, weight: true)
        overlayExportLabel.name = "export"
        overlayExportLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 - 150)
        overlayExportLabel.isHidden = true
        overlayNode.addChild(overlayExportLabel)

        overlayContinueButton = SKShapeNode(
            rectOf: metrics.overlayContinueSize,
            cornerRadius: metrics.overlayContinueSize.height * 0.5
        )
        overlayContinueButton.name = "continue"
        overlayContinueButton.fillColor = UIColor(hex: "14142A").withAlphaComponent(0.96)
        overlayContinueButton.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.16)
        overlayContinueButton.lineWidth = 1
        overlayContinueButton.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - 60)
        overlayContinueButton.zPosition = 201
        overlayContinueButton.isHidden = true
        overlayNode.addChild(overlayContinueButton)

        let continueLabel = label(VexloStrings.Overlay.continueRun, size: 14, color: .white, align: .center, weight: true)
        continueLabel.verticalAlignmentMode = .center
        continueLabel.position = .zero
        overlayContinueButton.addChild(continueLabel)

        let btn = SKShapeNode(
            rectOf: CGSize(width: 280, height: metrics.overlayRestartSize.height),
            cornerRadius: metrics.overlayRestartSize.height * 0.5
        )
        btn.name = "restart"
        btn.fillColor = UIColor(hex: "6C5CE7")
        btn.strokeColor = .clear
        btn.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5 + metrics.overlayActionsStartOffset - 118)
        btn.zPosition = 201
        overlayNode.addChild(btn)

        let btnLabel = label(VexloStrings.Overlay.playAgain, size: 15, color: .white, align: .center, weight: true)
        btnLabel.verticalAlignmentMode = .center
        btnLabel.position = .zero
        btn.addChild(btnLabel)
    }

    private func syncAll() {
        DailyChallengeService.shared.refreshForCurrentDay()
        syncBoard()
        syncModeSurface()
        syncModeIdentitySurface()
        syncScores()
        syncTray()
        syncOnboardingSurface()
        syncUtilitySurface()
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
            updateSupporterSurface()
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

    private func restoreLiveRun(from snapshot: GameEngine.LiveRunSnapshot) {
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
        visibleRerollOfferSlots.removeAll()
        isRestarting = false
        isPresentingContinue = false
        isPresentingReroll = false
        isPresentingSupporterPurchase = false
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
        overlayScoreLabel.text = "\(score)"
        if engine.isDailyChallenge {
            overlayCaptionLabel.text = VexloStrings.Overlay.dailyComplete
            let completion = lastDailyCompletion
            overlayBadgeLabel.text = completion?.isNewBestToday == true ? VexloStrings.Overlay.bestToday : ""
            overlayDetailLabel.text = VexloStrings.Overlay.streak(
                completion?.streakCount ?? DailyChallengeService.shared.previewStreakIfCompleted(
                    dayID: engine.dailyChallengeDayID ?? DailyChallengeService.shared.currentDayID()
                )
            )
            overlayProgressLabel.text = ""
        } else {
            let best = engine.scoreEngine.best
            overlayCaptionLabel.text = VexloStrings.Overlay.gameOver
            overlayProgressLabel.text = VexloStrings.Overlay.leaderboard
            if score >= best && score > runStartBest {
                overlayBadgeLabel.text = VexloStrings.Overlay.newBest
                overlayDetailLabel.text = ""
            } else {
                overlayBadgeLabel.text = ""
                let gap = max(0, best - score)
                overlayDetailLabel.text = gap == 0 ? VexloStrings.Overlay.oneCleanerRun : VexloStrings.Overlay.gapToBest(gap)
            }
        }
        applyOverlayResultVisualState()
        layoutOverlayActions()
    }

    private func updateGameCenterSurface() {
        guard !LaunchSupport.shared.isResultOverlayCapture else {
            overlayProgressLabel.isHidden = true
            overlayProgressLabel.alpha = 0
            overlayGamesLabel.isHidden = true
            overlayGamesLabel.alpha = 0
            layoutOverlayActions()
            return
        }
        if engine.isDailyChallenge {
            overlayGamesLabel.text = VexloStrings.Overlay.playTogether
            overlayGamesLabel.isHidden = !GameCenterService.shared.canPresentDailyActivity
            overlayProgressLabel.isHidden = true
            overlayProgressLabel.alpha = 0
        } else {
            let earnedBest = engine.scoreEngine.score >= engine.scoreEngine.best && engine.scoreEngine.score > runStartBest
            let canChallenge = GameCenterService.shared.canPresentScoreChallenge && engine.scoreEngine.score > 0
            let canScoreChaseActivity = earnedBest && GameCenterService.shared.canPresentScoreChaseActivity
            if canChallenge {
                overlayGamesLabel.text = VexloStrings.Overlay.challengeFriends
                overlayGamesLabel.isHidden = false
            } else if canScoreChaseActivity {
                overlayGamesLabel.text = VexloStrings.Overlay.playTogether
                overlayGamesLabel.isHidden = false
            } else {
                overlayGamesLabel.isHidden = true
            }
            overlayProgressLabel.isHidden = !GameCenterService.shared.isAuthenticated
            overlayProgressLabel.alpha = overlayProgressLabel.isHidden ? 0 : 1
        }
        overlayGamesLabel.alpha = overlayGamesLabel.isHidden ? 0 : 1
        layoutOverlayActions()
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
        overlayNode.removeAllActions()
        overlayNode.isHidden = false
        syncModeSurface()
        syncScores()
        syncUtilitySurface()
        guard !prefersReducedMotion else {
            overlayNode.alpha = 1
            overlayNode.setScale(1)
            playOverlayResultAudioIfNeeded()
            return
        }
        overlayNode.alpha = 0
        overlayNode.setScale(1.02)
        overlayNode.run(.group([
            .fadeIn(withDuration: 0.16),
            .scale(to: 1.0, duration: 0.16)
        ]))
        if !LaunchSupport.shared.isCaptureMode {
            HapticsService.shared.playInvalid()
            playOverlayResultAudioIfNeeded()
        }
    }

    private func hideOverlayIfNeeded() {
        guard isOverlayPresented || !overlayNode.isHidden else { return }
        isOverlayPresented = false
        isRestarting = false
        isPresentingContinue = false
        isPresentingReroll = false
        isPresentingSupporterPurchase = false
        hasRecordedContinueOfferForCurrentLoss = false
        overlayNode.removeAllActions()
        overlayNode.alpha = 0
        overlayNode.setScale(1)
        overlayNode.isHidden = true
        overlayGamesLabel.isHidden = true
        overlayShareLabel.isHidden = true
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
        clearedCoords: [HexCoordinate]
    ) {
        animatePlacement(coords: placedCoords, color: pieceColor) { [weak self] in
            guard let self else { return }
            if self.engine.scoreEngine.score > previousScore {
                self.syncScores()
                HapticsService.shared.playClear()
                AudioService.shared.play(.clear)
                if self.engine.scoreEngine.combo > previousCombo && self.engine.scoreEngine.combo > 1 {
                    HapticsService.shared.playCombo()
                    AudioService.shared.play(.combo)
                    self.showComboCue(self.engine.scoreEngine.combo)
                }
                if !clearedCoords.isEmpty {
                    self.animateClear(coords: clearedCoords) { [weak self] in
                        guard let self else { return }
                        self.syncAll()
                        self.handleFirstClearComprehensionIfNeeded(clearedCoords: clearedCoords)
                    }
                } else {
                    self.syncAll()
                }
            } else {
                self.syncAll()
            }
            if self.engine.isGameOver {
                self.updateOverlayResult()
            }
        }
    }

    private func resetVisualActions() {
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
        overlaySupporterLabel.removeAllActions()
        overlayRestoreLabel.removeAllActions()
        overlayExportLabel.removeAllActions()
        utilityButton.removeAllActions()
        utilityMenuNode.removeAllActions()
        utilitySoundLabel.removeAllActions()
        utilityHapticsLabel.removeAllActions()
        utilitySupporterLabel.removeAllActions()
        utilityRestoreLabel.removeAllActions()
        utilityExportLabel.removeAllActions()
        hasRecordedContinueOfferForCurrentLoss = false
        for node in cellNodes.values {
            node.removeAllActions()
            node.setScale(1.0)
            node.alpha = 1.0
        }
    }

    private func syncBoard() {
        for col in 0..<cols {
            for row in 0..<rows {
                let coord = HexCoordinate(col, row)
                guard let node = cellNodes[coord] else { continue }
                if let color = engine.board.color(at: coord) {
                    applyFilledCellStyle(node, color: color)
                } else {
                    applyEmptyCellStyle(node)
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
        overlayScoreLabel.text = "\(score)"
        bestCaptionLabel.fontColor = UIColor.white.withAlphaComponent(0.31)
        bestLabel.fontColor = UIColor(hex: "6C5CE7")
        scoreCaptionLabel.fontColor = UIColor.white.withAlphaComponent(0.31)
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

    private func showComboCue(_ combo: Int) {
        guard !terminalOverlayOwnsResultContext else { return }
        comboCueLabel.removeAllActions()
        comboCueLabel.text = "×\(combo)"
        comboCueLabel.position = CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y - 27)
        comboCueLabel.isHidden = false
        comboCueLabel.alpha = 0
        comboCueLabel.setScale(0.98)

        guard !prefersReducedMotion else {
            comboCueLabel.alpha = 0.82
            comboCueLabel.run(.sequence([
                .wait(forDuration: 0.48),
                .fadeOut(withDuration: 0.12),
                .run { [weak self] in
                    self?.comboCueLabel.isHidden = true
                }
            ]))
            return
        }

        comboCueLabel.run(.sequence([
            .group([
                .fadeAlpha(to: 0.82, duration: 0.08),
                .scale(to: 1.0, duration: 0.08),
                .moveBy(x: 0, y: 3, duration: 0.08)
            ]),
            .wait(forDuration: 0.36),
            .group([
                .fadeOut(withDuration: 0.14),
                .moveBy(x: 0, y: 5, duration: 0.14)
            ]),
            .run { [weak self] in
                self?.comboCueLabel.isHidden = true
            }
        ]))
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

        let shouldShowPlacementHint =
            OnboardingService.shared.shouldShowPlacementHint &&
            engine.scoreEngine.score == 0 &&
            !engine.didClearAny &&
            engine.board.allCoordinates().allSatisfy { engine.board.color(at: $0) == nil }

        if shouldShowPlacementHint {
            let text = VexloStrings.Onboarding.dragToBoard
            let textChanged = onboardingLabel.text != text || onboardingLabel.isHidden
            onboardingLabel.text = text
            onboardingLabel.isHidden = false
            fitLabelWidth(onboardingLabel, maxWidth: size.width - pad * 4, minimumScale: 0.82)
            guard textChanged else { return }
            onboardingLabel.removeAllActions()
            if prefersReducedMotion {
                onboardingLabel.alpha = 0.58
            } else {
                onboardingLabel.alpha = 0
                onboardingLabel.run(.fadeAlpha(to: 0.58, duration: 0.18))
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
        onboardingLabel.text = text
        onboardingLabel.isHidden = false
        fitLabelWidth(onboardingLabel, maxWidth: size.width - pad * 4, minimumScale: 0.82)
        if prefersReducedMotion {
            onboardingLabel.alpha = 0.64
        } else {
            onboardingLabel.alpha = 0
            onboardingLabel.run(.fadeAlpha(to: 0.64, duration: 0.16))
        }
        onboardingLabel.run(.sequence([
            .wait(forDuration: prefersReducedMotion ? 2.2 : 2.4),
            prefersReducedMotion ? .run {} : .fadeOut(withDuration: 0.2),
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

    private func canShowContinueAfterLoss() -> Bool {
        guard !engine.isDailyChallenge else { return false }
        guard engine.canResumeAfterLoss() else { return false }
        return MonetizationService.shared.canPresent(.continueAfterLoss)
    }

    private func canShowReroll(for slotIndex: Int) -> Bool {
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
            overlayContinueButton.isHidden = true
            overlayContinueButton.alpha = 0
            hasRecordedContinueOfferForCurrentLoss = false
            layoutOverlayActions()
            return
        }
        let isVisible = canShowContinueAfterLoss() && !isPresentingContinue
        overlayContinueButton.isHidden = !isVisible
        overlayContinueButton.alpha = isVisible ? 1 : 0
        if isVisible && !hasRecordedContinueOfferForCurrentLoss {
            AnalyticsService.shared.recordContinueOfferShown()
            hasRecordedContinueOfferForCurrentLoss = true
        } else if !isVisible {
            hasRecordedContinueOfferForCurrentLoss = false
        }
        layoutOverlayActions()
    }

    private func updateShareSurface() {
        let canShare = engine.isGameOver && !LaunchSupport.shared.isInternalCapture
        overlayShareLabel.text = "↑  \(VexloStrings.Overlay.share)"
        overlayShareLabel.isHidden = !canShare
        overlayShareLabel.alpha = canShare ? 0.9 : 0
        layoutOverlayActions()
    }

    private func updateSupporterSurface() {
        overlaySupporterLabel.isHidden = true
        overlaySupporterLabel.alpha = 0
        overlayRestoreLabel.isHidden = true
        overlayRestoreLabel.alpha = 0
        overlayExportLabel.isHidden = true
        overlayExportLabel.alpha = 0
        layoutOverlayActions()
        syncUtilitySurface()
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
        if terminalOverlayOwnsResultContext {
            modeLabel.isHidden = true
            modeLabel.alpha = 0
            return
        }
        modeLabel.isHidden = false
        let status = DailyChallengeService.shared.currentStatus()
        if LaunchSupport.shared.isCaptureMode {
            modeLabel.text = engine.isDailyChallenge ? VexloStrings.HUD.todaysChallenge : VexloStrings.HUD.mainRun
            modeLabel.alpha = isPublicEditorialCapture ? (engine.isDailyChallenge ? 0.6 : 0.52) : 0.54
        } else if engine.isDailyChallenge {
            modeLabel.text = VexloStrings.HUD.mainRun
            modeLabel.alpha = 0.54
        } else if status.streakCount > 0 {
            modeLabel.text = VexloStrings.HUD.todaysChallenge(streak: status.streakCount)
            modeLabel.alpha = 0.54
        } else {
            modeLabel.text = VexloStrings.HUD.todaysChallenge
            modeLabel.alpha = 0.5
        }
        fitLabelWidth(modeLabel, maxWidth: size.width * 0.48, minimumScale: 0.78)
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
        if let accent = childNode(withName: "hud.titleAccent") as? SKShapeNode {
            accent.fillColor = UIColor(hex: isDaily ? "C7D0FF" : "7A74F7").withAlphaComponent(isDaily ? 0.24 : 0.3)
            accent.strokeColor = UIColor(hex: isDaily ? "F4F3FF" : "A8B4FF").withAlphaComponent(isDaily ? 0.07 : 0.08)
        }
        if let titleFacet = childNode(withName: "hud.titleFacet") as? SKShapeNode {
            titleFacet.fillColor = UIColor(hex: isDaily ? "E8EDFF" : "C7D0FF").withAlphaComponent(isDaily ? 0.048 : 0.055)
            titleFacet.strokeColor = UIColor(hex: isDaily ? "DDE6FF" : "A8B4FF").withAlphaComponent(isDaily ? 0.085 : 0.1)
        }
        for index in 0..<2 {
            guard let facet = childNode(withName: "board.signatureFacet.\(index)") as? SKShapeNode else { continue }
            let dailyHex = index == 0 ? "E8EDFF" : "BFD4FF"
            let normalHex = index == 0 ? "C7D0FF" : "7A74F7"
            facet.fillColor = UIColor(hex: isDaily ? dailyHex : normalHex).withAlphaComponent(isDaily ? 0.038 : 0.032)
            facet.strokeColor = UIColor(hex: isDaily ? "DDE6FF" : "A8B4FF").withAlphaComponent(isDaily ? 0.078 : 0.07)
        }
    }

    private func beginSceneRun(mode: GameEngine.RunMode) {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        clearPersistedLiveRun()
        lastDailyCompletion = nil
        isShowingTransientOnboardingHint = false
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
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
            engine.startDailyRun(dayID: dayID, seed: seed)
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
    }

    private func playOverlayResultAudioIfNeeded() {
        guard !engine.isDailyChallenge else {
            AudioService.shared.play(.fail)
            return
        }
        let earnedBest = engine.scoreEngine.score >= engine.scoreEngine.best && engine.scoreEngine.score > runStartBest
        AudioService.shared.play(earnedBest ? .bestScore : .fail)
    }

    private func applyCaptureModeIfNeeded() -> Bool {
        guard !hasAppliedCaptureState, let captureState = LaunchSupport.shared.captureState else {
            return false
        }
        hasAppliedCaptureState = true
        switch captureState {
        case .normalRun:
            beginCaptureNormalRun()
        case .normalHero:
            beginCaptureNormalHeroRun()
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

    private func beginCaptureNormalRun(seed: UInt64 = LaunchSupport.shared.captureNormalSeed) {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        lastDailyCompletion = nil
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
        engine.startNormalRun(seed: seed)
        MonetizationService.shared.resetRunState()
        hasStartedMonetizationRun = false
        hasStartedAnalyticsRun = false
        hasFinalizedRun = false
        isRestarting = false
        runStartBest = engine.scoreEngine.best
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        syncAll()
    }

    private func beginCaptureNormalHeroRun() {
        beginCaptureNormalRun(seed: LaunchSupport.shared.captureNormalHeroSeed)
        playCaptureHeroSequence(
            maxPlacements: 6,
            preferredAnchors: [
                HexCoordinate(2, 2), HexCoordinate(3, 2), HexCoordinate(1, 3),
                HexCoordinate(4, 1), HexCoordinate(0, 4), HexCoordinate(5, 3),
                HexCoordinate(2, 5), HexCoordinate(4, 4), HexCoordinate(1, 1),
                HexCoordinate(5, 0), HexCoordinate(0, 1), HexCoordinate(3, 5)
            ]
        )
        syncAll()
    }

    private func beginCaptureDailyRun() {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        lastDailyCompletion = nil
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
        let dayID = LaunchSupport.shared.captureDailyDayID
        engine.startDailyRun(dayID: dayID, seed: DailyChallengeService.shared.seed(for: dayID))
        MonetizationService.shared.resetRunState()
        hasStartedMonetizationRun = false
        hasStartedAnalyticsRun = false
        hasFinalizedRun = false
        isRestarting = false
        runStartBest = DailyChallengeService.shared.bestScore(for: dayID)
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        syncAll()
    }

    private func beginCaptureDailyHeroRun() {
        beginCaptureDailyRun()
        playCaptureHeroSequence(
            maxPlacements: 6,
            preferredAnchors: [
                HexCoordinate(3, 2), HexCoordinate(2, 3), HexCoordinate(4, 2),
                HexCoordinate(1, 1), HexCoordinate(5, 3), HexCoordinate(0, 4),
                HexCoordinate(3, 5), HexCoordinate(4, 0), HexCoordinate(1, 4),
                HexCoordinate(5, 1), HexCoordinate(2, 0), HexCoordinate(0, 2)
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
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        lastDailyCompletion = nil
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
        overlayExportLabel.isHidden = true
        overlayExportLabel.alpha = 0
        runStartBest = 180
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
        MonetizationService.shared.resetRunState()
        hasStartedMonetizationRun = false
        hasStartedAnalyticsRun = false
        hasFinalizedRun = true
        isRestarting = false
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        syncAll()
    }

    private func beginCaptureDailyResult() {
        cancelDrag()
        resetVisualActions()
        hideOverlayIfNeeded()
        hideUtilitySurface()
        flowEpoch &+= 1
        hasRecordedContinueOfferForCurrentLoss = false
        visibleRerollOfferSlots.removeAll()
        isPresentingSupporterPurchase = false
        overlayExportLabel.isHidden = true
        overlayExportLabel.alpha = 0
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
        MonetizationService.shared.resetRunState()
        hasStartedMonetizationRun = false
        hasStartedAnalyticsRun = false
        hasFinalizedRun = true
        isRestarting = false
        lastScoreValue = engine.scoreEngine.score
        lastBestValue = currentDisplayedBest()
        syncAll()
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

    private func applySystemEntryRoute(_ route: SystemEntryRoute) {
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

    private func requestSupporterPackPurchase() {
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
                self.updateSupporterSurface()
                self.updateContinueSurface()
                self.syncTray()
            }
        }
    }

    private func requestSupporterPackRestore() {
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
                self.updateSupporterSurface()
                self.updateContinueSurface()
                self.syncTray()
            }
        }
    }

    private func presentationViewController() -> UIViewController? {
        var current = view?.window?.rootViewController
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }

    private func exportDiagnosticsSnapshot() {
        guard AnalyticsService.shared.isTesterExportAvailable,
              let presenter = presentationViewController() else { return }
        let snapshot = AnalyticsService.shared.exportSnapshot()
        let controller = UIActivityViewController(activityItems: [snapshot], applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        }
        presenter.present(controller, animated: true)
    }

    private func shareResult() {
        guard engine.isGameOver,
              !LaunchSupport.shared.isInternalCapture,
              let presenter = presentationViewController() else { return }
        let payload = ResultSharePayload(
            mode: engine.isDailyChallenge ? .daily : .normal,
            score: engine.scoreEngine.score,
            badge: overlayBadgeLabel.text?.isEmpty == false ? overlayBadgeLabel.text : nil,
            detail: overlayDetailLabel.text?.isEmpty == false ? overlayDetailLabel.text : nil
        )
        let controller = UIActivityViewController(
            activityItems: ResultShareService.activityItems(for: payload),
            applicationActivities: nil
        )
        if let popover = controller.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 1, height: 1)
        }
        presenter.present(controller, animated: true)
    }

    private func layoutOverlayActions() {
        let metrics = layoutMetrics
        let centerY = size.height * 0.5
        var currentY = centerY + metrics.overlayActionsStartOffset
        overlayProgressLabel.position = CGPoint(x: size.width * 0.5, y: currentY)
        currentY -= metrics.overlaySecondarySpacing
        fitLabelWidth(overlayProgressLabel, maxWidth: size.width - metrics.sideInset * 2 - 24, minimumScale: 0.78)
        fitLabelWidth(overlayGamesLabel, maxWidth: size.width - metrics.sideInset * 2 - 24, minimumScale: 0.78)
        fitLabelWidth(overlayShareLabel, maxWidth: size.width - metrics.sideInset * 2 - 24, minimumScale: 0.78)
        fitLabelWidth(overlayDetailLabel, maxWidth: size.width - metrics.sideInset * 2 - 16, minimumScale: 0.8)
        fitLabelWidth(overlayBadgeLabel, maxWidth: size.width - metrics.sideInset * 2 - 16, minimumScale: 0.8)

        if !overlayGamesLabel.isHidden {
            overlayGamesLabel.position = CGPoint(x: size.width * 0.5, y: currentY)
            currentY -= metrics.overlaySecondarySpacing
        }
        if !overlayShareLabel.isHidden {
            overlayShareLabel.position = CGPoint(x: size.width * 0.5, y: currentY)
            currentY -= metrics.overlaySecondarySpacing
        }
        if !overlayContinueButton.isHidden {
            overlayContinueButton.position = CGPoint(x: size.width * 0.5, y: currentY - metrics.overlayContinueSize.height * 0.55)
            currentY -= metrics.overlayContinueSize.height + 10
        } else {
            overlayContinueButton.position = CGPoint(x: size.width * 0.5, y: centerY + metrics.overlayActionsStartOffset - 60)
        }

        if let restart = overlayNode.childNode(withName: "restart") {
            restart.position = CGPoint(x: size.width * 0.5, y: currentY - metrics.overlayRestartSize.height * 0.5)
        }
    }

    private func expandedHitContains(_ node: SKNode, pointInParent: CGPoint, minimumSize: CGSize = CGSize(width: 44, height: 44), padding: CGFloat = 8) -> Bool {
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

    private func syncUtilitySurface() {
        let canShowSurface = canShowUtilityAffordance
        utilityButton.isHidden = !canShowSurface
        utilityMenuNode.isHidden = !canShowSurface || !isUtilityPresented
        guard canShowSurface else { return }

        utilitySoundLabel.text = AudioService.shared.isEnabled ? VexloStrings.Utility.soundOn : VexloStrings.Utility.soundOff
        utilitySoundLabel.isHidden = false
        utilitySoundLabel.alpha = 1

        let canShowHaptics = HapticsService.shared.isSupported
        utilityHapticsLabel.text = HapticsService.shared.isEnabled ? VexloStrings.Utility.hapticsOn : VexloStrings.Utility.hapticsOff
        utilityHapticsLabel.isHidden = !canShowHaptics
        utilityHapticsLabel.alpha = canShowHaptics ? 1 : 0

        let isPublicUtilityCapture = LaunchSupport.shared.isUtilitySurfaceCapture && !LaunchSupport.shared.isInternalCapture
        let canShowSupporter = !isPublicUtilityCapture &&
            MonetizationService.shared.canPresentSupporterPack() &&
            !isPresentingSupporterPurchase
        utilitySupporterLabel.isHidden = !canShowSupporter
        utilitySupporterLabel.alpha = canShowSupporter ? 1 : 0

        let canRestore = !isPublicUtilityCapture &&
            SupporterPackService.shared.isProductLoaded &&
            !MonetizationService.shared.capabilities.supporterOwned &&
            !isPresentingSupporterPurchase
        utilityRestoreLabel.isHidden = !canRestore
        utilityRestoreLabel.alpha = canRestore ? 0.68 : 0

        let canExport = LaunchSupport.shared.isInternalCapture &&
            AnalyticsService.shared.isTesterExportAvailable
        utilityExportLabel.isHidden = !canExport
        utilityExportLabel.alpha = canExport ? 0.58 : 0

        utilityButton.fillColor = UIColor(hex: "16162E").withAlphaComponent(isUtilityPresented ? 0.97 : 0.9)
        utilityButton.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(isUtilityPresented ? 0.22 : 0.14)
        if let utilityGlow = utilityButton.childNode(withName: "utility.glow") as? SKShapeNode {
            utilityGlow.fillColor = UIColor(hex: "A8B4FF").withAlphaComponent(isUtilityPresented ? 0.052 : 0.03)
        }
        layoutUtilitySurface()
    }

    private func layoutUtilitySurface() {
        let metrics = layoutMetrics
        let panelWidth = metrics.utilityPanelWidth
        let leftX = -panelWidth * 0.5 + 17
        let visibleRows = [utilitySoundLabel, utilityHapticsLabel, utilitySupporterLabel, utilityRestoreLabel, utilityExportLabel]
            .filter { !$0.isHidden }
        let rowHeight = metrics.utilityRowHeight
        let topInset = metrics.utilityPanelTopInset
        let bottomInset = metrics.utilityPanelBottomInset
        let panelHeight = max(58, topInset + CGFloat(visibleRows.count) * rowHeight + bottomInset)
        let buttonPosition = utilityButton.position
        let maxPanelX = size.width - layoutMetrics.sideInset - panelWidth * 0.5
        let targetX = min(buttonPosition.x - panelWidth * 0.5 + 16, maxPanelX)
        utilityMenuNode.position = CGPoint(x: targetX, y: buttonPosition.y - panelHeight * 0.5 - (size.height < 760 ? 24 : 28))
        let rect = CGRect(x: -panelWidth * 0.5, y: -panelHeight * 0.5, width: panelWidth, height: panelHeight)
        utilityMenuBackground.path = UIBezierPath(roundedRect: rect, cornerRadius: size.height < 760 ? 16 : 18).cgPath

        var currentY = panelHeight * 0.5 - topInset
        for row in visibleRows {
            row.position = CGPoint(x: leftX, y: currentY)
            fitLabelWidth(row, maxWidth: panelWidth - 32, minimumScale: 0.82)
            currentY -= rowHeight
        }
    }

    private func toggleUtilitySurface() {
        guard !LaunchSupport.shared.isCaptureMode, dragPiece == nil, !isInteractionLocked else { return }
        isUtilityPresented.toggle()
        utilityMenuNode.removeAllActions()
        syncUtilitySurface()
        guard !prefersReducedMotion else {
            utilityMenuNode.alpha = isUtilityPresented ? 1 : 0
            return
        }
        if isUtilityPresented {
            utilityMenuNode.setScale(0.98)
            utilityMenuNode.run(.group([
                .fadeIn(withDuration: 0.14),
                .scale(to: 1.0, duration: 0.14)
            ]))
        } else {
            utilityMenuNode.run(.group([
                .fadeOut(withDuration: 0.12),
                .scale(to: 0.98, duration: 0.12)
            ]))
        }
    }

    private func hideUtilitySurface() {
        guard isUtilityPresented else { return }
        isUtilityPresented = false
        utilityMenuNode.removeAllActions()
        utilityMenuNode.alpha = 0
        utilityMenuNode.isHidden = true
        syncUtilitySurface()
    }

    private func handleUtilityTouch(at point: CGPoint) -> Bool {
        guard !utilityButton.isHidden else { return false }
        if expandedHitContains(utilityButton, pointInParent: point, minimumSize: CGSize(width: 44, height: 44), padding: 8) {
            toggleUtilitySurface()
            return true
        }
        guard isUtilityPresented else { return false }
        let menuPoint = utilityMenuNode.convert(point, from: self)
        if !utilitySoundLabel.isHidden,
           expandedHitContains(utilitySoundLabel, pointInParent: menuPoint, minimumSize: CGSize(width: layoutMetrics.utilityPanelWidth - 16, height: layoutMetrics.utilityRowHitHeight), padding: 8) {
            AudioService.shared.isEnabled.toggle()
            syncUtilitySurface()
            return true
        }
        if !utilityHapticsLabel.isHidden,
           expandedHitContains(utilityHapticsLabel, pointInParent: menuPoint, minimumSize: CGSize(width: layoutMetrics.utilityPanelWidth - 16, height: layoutMetrics.utilityRowHitHeight), padding: 8) {
            HapticsService.shared.isEnabled.toggle()
            syncUtilitySurface()
            return true
        }
        if !utilitySupporterLabel.isHidden,
           expandedHitContains(utilitySupporterLabel, pointInParent: menuPoint, minimumSize: CGSize(width: layoutMetrics.utilityPanelWidth - 16, height: layoutMetrics.utilityRowHitHeight), padding: 8) {
            requestSupporterPackPurchase()
            return true
        }
        if !utilityRestoreLabel.isHidden,
           expandedHitContains(utilityRestoreLabel, pointInParent: menuPoint, minimumSize: CGSize(width: layoutMetrics.utilityPanelWidth - 16, height: layoutMetrics.utilityRowHitHeight), padding: 8) {
            requestSupporterPackRestore()
            return true
        }
        if !utilityExportLabel.isHidden,
           expandedHitContains(utilityExportLabel, pointInParent: menuPoint, minimumSize: CGSize(width: layoutMetrics.utilityPanelWidth - 16, height: layoutMetrics.utilityRowHitHeight), padding: 8) {
            exportDiagnosticsSnapshot()
            return true
        }
        hideUtilitySurface()
        return true
    }

    private func syncTray() {
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

    private func predictedClearCoordinates(for piece: HexPiece, at anchor: HexCoordinate) -> [HexCoordinate] {
        let placed = Set(piece.offsets.map { HexGeometry.coordinate(for: $0, anchoredAt: anchor) })
        let filled: (HexCoordinate) -> Bool = { coord in
            placed.contains(coord) || self.engine.board.color(at: coord) != nil
        }
        let clearedRows = (0..<rows).filter { row in
            (0..<cols).allSatisfy { col in
                filled(HexCoordinate(col, row))
            }
        }
        let clearedCols = (0..<cols).filter { col in
            (0..<rows).allSatisfy { row in
                filled(HexCoordinate(col, row))
            }
        }
        return Array(Set(
            engine.board.coordinatesForRows(clearedRows) +
            engine.board.coordinatesForCols(clearedCols)
        ))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if handleUtilityTouch(at: point) {
            return
        }
        if !overlayNode.isHidden {
            guard !isRestarting, !isPresentingContinue, !isPresentingSupporterPurchase else { return }
            let overlayPoint = overlayNode.convert(point, from: self)
            if let progress = overlayNode.childNode(withName: "progress"),
               !progress.isHidden,
               expandedHitContains(progress, pointInParent: overlayPoint, minimumSize: CGSize(width: 120, height: 34), padding: 10) {
                if engine.isDailyChallenge {
                    startNormalRunFromDaily()
                } else {
                    GameCenterService.shared.showScoreLeaderboard()
                }
                return
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
                return
            }
            if let share = overlayNode.childNode(withName: "share"),
               !share.isHidden,
               expandedHitContains(share, pointInParent: overlayPoint, minimumSize: CGSize(width: 120, height: 34), padding: 10) {
                shareResult()
                return
            }
            if let continueButton = overlayNode.childNode(withName: "continue"),
               !continueButton.isHidden,
               expandedHitContains(continueButton, pointInParent: overlayPoint, minimumSize: CGSize(width: 220, height: 52), padding: 6) {
                requestContinueAfterLoss()
                return
            }
            if let btn = overlayNode.childNode(withName: "restart"),
               expandedHitContains(btn, pointInParent: overlayPoint, minimumSize: CGSize(width: 220, height: 56), padding: 6) {
                restartRun()
            }
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
            let coords = piece.offsets.map {
                HexGeometry.coordinate(for: $0, anchoredAt: anchor)
            }
            let valid = coords.allSatisfy { engine.board.isValid($0) }
                && engine.canPlace(piece, at: anchor)
            guard anchor != lastDragHighlightAnchor || valid != lastDragHighlightValid else { return }
            lastDragHighlightAnchor = anchor
            lastDragHighlightValid = valid
            highlightCells(coords, valid: valid)
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
            syncTray()
            return
        }
        let coords = piece.offsets.map {
            HexGeometry.coordinate(for: $0, anchoredAt: anchor)
        }
        guard coords.allSatisfy({ engine.board.isValid($0) }),
              engine.canPlace(piece, at: anchor) else {
            HapticsService.shared.playInvalid()
            syncTray()
            return
        }
        let prevScore = engine.scoreEngine.score
        let prevCombo = engine.scoreEngine.combo
        let allCleared = predictedClearCoordinates(for: piece, at: anchor)

        engine.place(piece, at: anchor, slotIndex: dragSlotIndex)
        OnboardingService.shared.markPlacementLearned()
        HapticsService.shared.playPlace()
        AudioService.shared.play(.placement)
        handlePostPlacementFeedback(
            placedCoords: coords,
            pieceColor: piece.color,
            previousScore: prevScore,
            previousCombo: prevCombo,
            clearedCoords: allCleared
        )
    }

    private func cancelDrag() {
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

    private func highlightCells(_ coords: [HexCoordinate], valid: Bool) {
        guard coords.allSatisfy({ engine.board.isValid($0) }) else {
            for coord in dragHighlightedCells {
                restoreBoardCell(at: coord)
            }
            dragHighlightedCells.removeAll()
            return
        }
        let nextCells = Set(coords)
        for coord in dragHighlightedCells.subtracting(nextCells) {
            restoreBoardCell(at: coord)
        }
        dragHighlightedCells = nextCells
        for coord in nextCells {
            guard let node = cellNodes[coord] else { continue }
            node.childNode(withName: "board.emptyMaterial")?.isHidden = true
            if valid {
                node.fillColor = UIColor(hex: "9CE7D2").withAlphaComponent(0.24)
                node.strokeColor = UIColor.white.withAlphaComponent(0.34)
                node.lineWidth = 1.4
                node.alpha = 1.0
                if !prefersReducedMotion {
                    node.setScale(1.02)
                }
            } else {
                node.fillColor = UIColor(hex: "E8DFF7").withAlphaComponent(0.09)
                node.strokeColor = UIColor.white.withAlphaComponent(0.16)
                node.lineWidth = 0.9
                node.alpha = 0.76
                if !prefersReducedMotion {
                    node.setScale(0.985)
                }
            }
        }
        if let dragNode, let piece = dragPiece {
            applyDragSurfaceState(dragNode, color: piece.color, isValid: valid)
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
            applyEmptyCellStyle(node)
        }
    }

    private func animateClear(coords: [HexCoordinate], completion: @escaping () -> Void) {
        let sorted = coords.sorted { $0.row < $1.row || ($0.row == $1.row && $0.col < $1.col) }
        var delay: TimeInterval = 0
        for coord in sorted {
            guard let node = cellNodes[coord] else { continue }
            node.removeAllActions()
            let wait = SKAction.wait(forDuration: delay)
            let flash = SKAction.sequence([
                SKAction.run {
                    node.alpha = 1.0
                    node.strokeColor = UIColor(hex: "DDE5FF").withAlphaComponent(0.34)
                    node.lineWidth = 1.35
                },
                SKAction.group([
                    SKAction.run {
                        node.strokeColor = UIColor(hex: "F5F7FF").withAlphaComponent(0.48)
                        node.fillColor = UIColor(hex: "DDE5FF").withAlphaComponent(0.2)
                    },
                    SKAction.scale(to: prefersReducedMotion ? 1.0 : 1.075, duration: 0.055),
                    SKAction.fadeAlpha(to: 0.98, duration: 0.055)
                ]),
                SKAction.group([
                    SKAction.run {
                        node.fillColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.08)
                        node.strokeColor = UIColor.white.withAlphaComponent(0.16)
                        node.lineWidth = 0.9
                    },
                    SKAction.scale(to: prefersReducedMotion ? 1.0 : 0.9, duration: 0.095),
                    SKAction.fadeAlpha(to: 0.0, duration: 0.095)
                ]),
                SKAction.run {
                    node.setScale(1.0)
                    node.alpha = 1.0
                    self.applyEmptyCellStyle(node)
                }
            ])
            node.run(SKAction.sequence([wait, flash]))
            delay += 0.035
        }
        let total = delay + 0.17
        run(SKAction.sequence([
            SKAction.wait(forDuration: total),
            SKAction.run(completion)
        ]))
    }

    private func handleFirstClearComprehensionIfNeeded(clearedCoords: [HexCoordinate]) {
        guard !clearedCoords.isEmpty,
              OnboardingService.shared.shouldShowClearHint else { return }
        OnboardingService.shared.markClearLearned()
        showTransientOnboardingHint(VexloStrings.Onboarding.completeLine)
    }

    private func label(
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

    private func fitLabelWidth(_ label: SKLabelNode, maxWidth: CGFloat, minimumScale: CGFloat) {
        label.xScale = 1
        guard maxWidth > 0 else { return }
        let width = label.frame.width
        guard width > maxWidth, width > 0 else { return }
        label.xScale = max(minimumScale, maxWidth / width)
    }

    private func applyEmptyCellStyle(_ node: SKShapeNode) {
        node.fillColor = UIColor(hex: engine.isDailyChallenge ? "EAF2FF" : "DEE7FF").withAlphaComponent(engine.isDailyChallenge ? 0.058 : 0.054)
        node.strokeColor = UIColor(hex: engine.isDailyChallenge ? "DDE6FF" : "F5F7FF").withAlphaComponent(engine.isDailyChallenge ? 0.108 : 0.115)
        node.lineWidth = 0.95
        node.alpha = 1.0
        node.setScale(1.0)
        let material = emptyCellMaterialNode(in: node)
        material.isHidden = false
        material.fillColor = UIColor(hex: engine.isDailyChallenge ? "F8FBFF" : "A8B4FF").withAlphaComponent(engine.isDailyChallenge ? 0.018 : 0.016)
        material.strokeColor = UIColor.clear
    }

    private func applyFilledCellStyle(_ node: SKShapeNode, color: UIColor) {
        node.childNode(withName: "board.emptyMaterial")?.isHidden = true
        applyPieceSurfaceStyle(node, color: color, emphasis: .board)
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
            node.fillColor = color.withAlphaComponent(0.97)
            node.strokeColor = UIColor.white.withAlphaComponent(0.28)
            node.lineWidth = 1.15
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

    private func applyDragSurfaceState(_ dragNode: SKNode, color: UIColor, isValid: Bool) {
        for case let hex as SKShapeNode in dragNode.children where hex.name == "piece.hex" {
            applyPieceSurfaceStyle(hex, color: color, emphasis: isValid ? .dragValid : .dragInvalid)
        }
        for case let glint as SKShapeNode in dragNode.children where glint.name == "piece.glint" {
            glint.fillColor = UIColor.white.withAlphaComponent(isValid ? 0.14 : 0.05)
            glint.alpha = isValid ? 1.0 : 0.7
        }
        dragNode.alpha = isValid ? 1.0 : 0.86
    }

    private func applyOverlayResultVisualState() {
        let isDaily = engine.isDailyChallenge
        let isSpecial = overlayBadgeLabel.text?.isEmpty == false
        let score = engine.scoreEngine.score
        let lowScoreScale: CGFloat
        if isSpecial {
            lowScoreScale = 1
        } else if score == 0 {
            lowScoreScale = 0.82
        } else if score < 10 {
            lowScoreScale = 0.88
        } else if score < 25 {
            lowScoreScale = 0.94
        } else {
            lowScoreScale = 1
        }

        overlayCaptionLabel.fontColor = UIColor(hex: "A8B4FF")
        overlayDetailLabel.fontColor = UIColor.white.withAlphaComponent(isSpecial ? 0.58 : (score == 0 ? 0.44 : 0.52))
        overlayScoreLabel.fontSize = layoutMetrics.overlayScoreFontSize * lowScoreScale

        if isDaily {
            overlayBadgeLabel.fontColor = UIColor(hex: "8EDFCB").withAlphaComponent(0.93)
            overlayBadgeLabel.fontSize = 11.5
            overlayDetailLabel.fontSize = 12.5
            overlayScoreLabel.fontColor = UIColor(hex: "F8FBFF")
        } else if isSpecial {
            overlayBadgeLabel.fontColor = UIColor(hex: "B5A8FF").withAlphaComponent(0.94)
            overlayBadgeLabel.fontSize = 11.5
            overlayDetailLabel.fontSize = 12.5
            overlayScoreLabel.fontColor = UIColor(hex: "FBF9FF")
        } else {
            overlayBadgeLabel.fontColor = UIColor(hex: "6C5CE7").withAlphaComponent(0.86)
            overlayBadgeLabel.fontSize = 11.5
            overlayDetailLabel.fontSize = 12.5
            overlayScoreLabel.fontColor = UIColor.white
        }
    }

    private func buildAtmosphere() {
        children.filter {
            guard let name = $0.name else { return false }
            return name.hasPrefix("atmosphere.")
        }.forEach { $0.removeFromParent() }

        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let topGlow = SKShapeNode(rectOf: CGSize(width: size.width * 0.88, height: size.height * 0.36), cornerRadius: size.height * 0.12)
        topGlow.name = "atmosphere.topGlow"
        topGlow.fillColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.028)
        topGlow.strokeColor = .clear
        topGlow.position = CGPoint(x: center.x, y: size.height * 0.82)
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
