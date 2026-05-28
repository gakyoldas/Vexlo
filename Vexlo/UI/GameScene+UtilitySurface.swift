import SpriteKit
import UIKit

extension GameScene {
    struct UtilitySurface {
        enum Action {
            case toggleMenu
            case toggleSound
            case toggleHaptics
            case purchaseSupporter
            case restoreSupporter
            case exportDiagnostics
            case startNewRun
            case dismissMenu
        }

        struct State {
            let canShowSurface: Bool
            let isPresented: Bool
            let isSoundEnabled: Bool
            let canShowHaptics: Bool
            let isHapticsEnabled: Bool
            let canShowSupporter: Bool
            let canRestore: Bool
            let canExport: Bool
            let canStartNewRun: Bool
        }

        let button: SKShapeNode
        let menuNode: SKNode
        let menuBackground: SKShapeNode
        let soundLabel: SKLabelNode
        let hapticsLabel: SKLabelNode
        let supporterLabel: SKLabelNode
        let restoreLabel: SKLabelNode
        let exportLabel: SKLabelNode
        let newRunLabel: SKLabelNode
        let studioLabel: SKLabelNode

        private var visibleRows: [SKLabelNode] {
            [soundLabel, hapticsLabel, supporterLabel, restoreLabel, exportLabel, newRunLabel]
                .filter { !$0.isHidden }
        }

        func sync(
            state: State,
            size: CGSize,
            metrics: LayoutMetrics,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            button.isHidden = !state.canShowSurface
            menuNode.isHidden = !state.canShowSurface || !state.isPresented
            guard state.canShowSurface else { return }

            soundLabel.text = state.isSoundEnabled ? VexloStrings.Utility.soundOn : VexloStrings.Utility.soundOff
            soundLabel.isHidden = false
            soundLabel.alpha = 1

            hapticsLabel.text = state.isHapticsEnabled ? VexloStrings.Utility.hapticsOn : VexloStrings.Utility.hapticsOff
            hapticsLabel.isHidden = !state.canShowHaptics
            hapticsLabel.alpha = state.canShowHaptics ? 1 : 0

            supporterLabel.isHidden = !state.canShowSupporter
            supporterLabel.alpha = state.canShowSupporter ? 1 : 0

            restoreLabel.isHidden = !state.canRestore
            restoreLabel.alpha = state.canRestore ? 0.72 : 0

            exportLabel.isHidden = !state.canExport
            exportLabel.alpha = state.canExport ? 0.58 : 0

            newRunLabel.isHidden = !state.canStartNewRun
            newRunLabel.alpha = state.canStartNewRun ? 0.72 : 0
            studioLabel.isHidden = false
            studioLabel.alpha = 0.34

            button.fillColor = UIColor(hex: "16162E").withAlphaComponent(state.isPresented ? 0.97 : 0.94)
            button.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(state.isPresented ? 0.22 : 0.18)
            if let utilityGlow = button.childNode(withName: "utility.glow") as? SKShapeNode {
                utilityGlow.fillColor = UIColor(hex: "A8B4FF").withAlphaComponent(state.isPresented ? 0.052 : 0.04)
            }
            layout(size: size, metrics: metrics, fitLabelWidth: fitLabelWidth)
        }

        func layout(
            size: CGSize,
            metrics: LayoutMetrics,
            fitLabelWidth: (SKLabelNode, CGFloat, CGFloat) -> Void
        ) {
            let panelWidth = metrics.utilityPanelWidth
            let leftX = -panelWidth * 0.5 + 18
            let rowHeight = metrics.utilityRowHeight
            let topInset = metrics.utilityPanelTopInset
            let bottomInset = metrics.utilityPanelBottomInset
            let studioFooterHeight: CGFloat = 16
            let panelHeight = max(58, topInset + CGFloat(visibleRows.count) * rowHeight + studioFooterHeight + bottomInset)
            let buttonPosition = button.position
            let maxPanelX = size.width - metrics.sideInset - panelWidth * 0.5
            let targetX = min(buttonPosition.x - panelWidth * 0.5 + 16, maxPanelX)
            menuNode.position = CGPoint(x: targetX, y: buttonPosition.y - panelHeight * 0.5 - (size.height < 760 ? 24 : 28))
            let rect = CGRect(x: -panelWidth * 0.5, y: -panelHeight * 0.5, width: panelWidth, height: panelHeight)
            menuBackground.path = UIBezierPath(roundedRect: rect, cornerRadius: size.height < 760 ? 16 : 18).cgPath

            var currentY = panelHeight * 0.5 - topInset - 1
            for row in visibleRows {
                row.position = CGPoint(x: leftX, y: currentY)
                fitLabelWidth(row, panelWidth - 32, 0.82)
                currentY -= rowHeight
            }
            studioLabel.position = CGPoint(x: 0, y: -panelHeight * 0.5 + bottomInset + 6)
            fitLabelWidth(studioLabel, panelWidth - 34, 0.82)
        }

        func action(
            at point: CGPoint,
            in scene: SKScene,
            metrics: LayoutMetrics,
            expandedHitContains: (SKNode, CGPoint, CGSize, CGFloat) -> Bool
        ) -> Action? {
            guard !button.isHidden else { return nil }
            if expandedHitContains(button, point, CGSize(width: 44, height: 44), 8) {
                return .toggleMenu
            }
            guard !menuNode.isHidden else { return nil }
            let menuPoint = menuNode.convert(point, from: scene)
            let rowMinimumSize = CGSize(
                width: metrics.utilityPanelWidth - 16,
                height: metrics.utilityRowHitHeight
            )
            if !soundLabel.isHidden, expandedHitContains(soundLabel, menuPoint, rowMinimumSize, 8) {
                return .toggleSound
            }
            if !hapticsLabel.isHidden, expandedHitContains(hapticsLabel, menuPoint, rowMinimumSize, 8) {
                return .toggleHaptics
            }
            if !supporterLabel.isHidden, expandedHitContains(supporterLabel, menuPoint, rowMinimumSize, 8) {
                return .purchaseSupporter
            }
            if !restoreLabel.isHidden, expandedHitContains(restoreLabel, menuPoint, rowMinimumSize, 8) {
                return .restoreSupporter
            }
            if !exportLabel.isHidden, expandedHitContains(exportLabel, menuPoint, rowMinimumSize, 8) {
                return .exportDiagnostics
            }
            if !newRunLabel.isHidden, expandedHitContains(newRunLabel, menuPoint, rowMinimumSize, 8) {
                return .startNewRun
            }
            return .dismissMenu
        }
    }

    var utilitySurface: UtilitySurface {
        UtilitySurface(
            button: utilityButton,
            menuNode: utilityMenuNode,
            menuBackground: utilityMenuBackground,
            soundLabel: utilitySoundLabel,
            hapticsLabel: utilityHapticsLabel,
            supporterLabel: utilitySupporterLabel,
            restoreLabel: utilityRestoreLabel,
            exportLabel: utilityExportLabel,
            newRunLabel: utilityNewRunLabel,
            studioLabel: utilityStudioLabel
        )
    }

    func buildUtilitySurface() {
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
        utilityMenuBackground.fillColor = UIColor(hex: "12122A").withAlphaComponent(0.97)
        utilityMenuBackground.strokeColor = UIColor(hex: "A8B4FF").withAlphaComponent(0.12)
        utilityMenuBackground.lineWidth = 1
        utilityMenuNode.addChild(utilityMenuBackground)

        utilitySoundLabel = label("", size: 13, alpha: 0.92, align: .left, weight: true)
        utilitySoundLabel.name = "utility.sound"
        utilityMenuNode.addChild(utilitySoundLabel)

        utilityHapticsLabel = label("", size: 13, alpha: 0.92, align: .left, weight: true)
        utilityHapticsLabel.name = "utility.haptics"
        utilityMenuNode.addChild(utilityHapticsLabel)

        utilitySupporterLabel = label(VexloStrings.Overlay.supporterPackValue, size: 12.5, alpha: 0.92, align: .left, weight: true)
        utilitySupporterLabel.name = "utility.supporter"
        utilityMenuNode.addChild(utilitySupporterLabel)

        utilityRestoreLabel = label(VexloStrings.Overlay.restorePurchases, size: 12, alpha: 0.74, align: .left, weight: true)
        utilityRestoreLabel.name = "utility.restore"
        utilityMenuNode.addChild(utilityRestoreLabel)

        utilityExportLabel = label(VexloStrings.Overlay.exportDiagnostics, size: 12, alpha: 0.64, align: .left, weight: true)
        utilityExportLabel.name = "utility.export"
        utilityMenuNode.addChild(utilityExportLabel)

        utilityNewRunLabel = label(VexloStrings.Utility.startNewRun, size: 12.5, alpha: 0.72, align: .left, weight: true)
        utilityNewRunLabel.name = "utility.newRun"
        utilityMenuNode.addChild(utilityNewRunLabel)

        utilityStudioLabel = label(VexloStrings.Utility.studio, size: 10.5, alpha: 0.34, align: .center, weight: true)
        utilityStudioLabel.name = "utility.studio"
        utilityMenuNode.addChild(utilityStudioLabel)

        syncUtilitySurface()
    }

    func syncUtilitySurface() {
        let canShowSurface = canShowUtilityAffordance
        let isPublicUtilityCapture = LaunchSupport.shared.isUtilitySurfaceCapture && !LaunchSupport.shared.isInternalCapture
        utilitySurface.sync(
            state: .init(
                canShowSurface: canShowSurface,
                isPresented: isUtilityPresented,
                isSoundEnabled: AudioService.shared.isEnabled,
                canShowHaptics: HapticsService.shared.isSupported,
                isHapticsEnabled: HapticsService.shared.isEnabled,
                canShowSupporter: !isPublicUtilityCapture &&
                    MonetizationService.shared.canPresentSupporterPack() &&
                    !isPresentingSupporterPurchase,
                canRestore: !isPublicUtilityCapture &&
                    SupporterPackService.shared.isProductLoaded &&
                    !MonetizationService.shared.capabilities.supporterOwned &&
                    !isPresentingSupporterPurchase,
                canExport: LaunchSupport.shared.isInternalCapture &&
                    AnalyticsService.shared.isTesterExportAvailable,
                canStartNewRun: LiveRunPersistenceService.shared.hasPersistedRun &&
                    !engine.isGameOver &&
                    !isPresentingNewRunConfirmation
            ),
            size: size,
            metrics: layoutMetrics
        ) { [weak self] label, maxWidth, minimumScale in
            self?.fitLabelWidth(label, maxWidth: maxWidth, minimumScale: minimumScale)
        }
    }

    func layoutUtilitySurface() {
        utilitySurface.layout(size: size, metrics: layoutMetrics) { [weak self] label, maxWidth, minimumScale in
            self?.fitLabelWidth(label, maxWidth: maxWidth, minimumScale: minimumScale)
        }
    }

    func toggleUtilitySurface() {
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

    func hideUtilitySurface() {
        guard isUtilityPresented else { return }
        isUtilityPresented = false
        utilityMenuNode.removeAllActions()
        utilityMenuNode.alpha = 0
        utilityMenuNode.isHidden = true
        syncUtilitySurface()
    }

    func handleUtilityTouch(at point: CGPoint) -> Bool {
        guard let action = utilitySurface.action(
            at: point,
            in: self,
            metrics: layoutMetrics,
            expandedHitContains: { [weak self] node, hitPoint, minimumSize, padding in
                self?.expandedHitContains(node, pointInParent: hitPoint, minimumSize: minimumSize, padding: padding) ?? false
            }
        ) else {
            return false
        }
        switch action {
        case .toggleMenu:
            toggleUtilitySurface()
        case .toggleSound:
            let nextSoundEnabled = !AudioService.shared.isEnabled
            AudioService.shared.isEnabled = nextSoundEnabled
            syncUtilitySurface()
        case .toggleHaptics:
            HapticsService.shared.isEnabled.toggle()
            syncUtilitySurface()
        case .purchaseSupporter:
            requestSupporterPackPurchase()
        case .restoreSupporter:
            requestSupporterPackRestore()
        case .exportDiagnostics:
            exportDiagnosticsSnapshot()
        case .startNewRun:
            requestStartNewRun()
        case .dismissMenu:
            hideUtilitySurface()
        }
        return true
    }
}
