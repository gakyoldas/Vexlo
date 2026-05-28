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
            let residueLine: String?
            let masteryLine: String?
            let ritualBlock: String?
            let profileBlock: String?
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
        let residueLabel: SKLabelNode
        let masteryLabel: SKLabelNode
        let ritualHeaderLabel: SKLabelNode
        let ritualLabel: SKLabelNode
        let profileHeaderLabel: SKLabelNode
        let profileLabel: SKLabelNode
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
            if let residueLine = state.residueLine, state.isPresented {
                residueLabel.text = residueLine
                residueLabel.isHidden = false
                residueLabel.alpha = 0.60
            } else {
                residueLabel.isHidden = true
                residueLabel.alpha = 0
            }
            if let masteryLine = state.masteryLine, state.isPresented {
                masteryLabel.text = masteryLine
                masteryLabel.isHidden = false
                masteryLabel.alpha = 0.58
            } else {
                masteryLabel.isHidden = true
                masteryLabel.alpha = 0
            }
            if let ritualBlock = state.ritualBlock, state.isPresented {
                let split = Self.splitRitualBlock(ritualBlock)
                ritualHeaderLabel.text = split.header
                ritualHeaderLabel.isHidden = split.header == nil
                ritualHeaderLabel.alpha = split.header == nil ? 0 : 0.66
                ritualLabel.text = split.body
                ritualLabel.isHidden = split.body == nil
                ritualLabel.alpha = split.body == nil ? 0 : 0.60
                ritualLabel.numberOfLines = 0
            } else {
                ritualHeaderLabel.isHidden = true
                ritualHeaderLabel.alpha = 0
                ritualLabel.isHidden = true
                ritualLabel.alpha = 0
            }
            if let profileBlock = state.profileBlock, state.isPresented {
                let split = Self.splitProfileBlock(profileBlock)
                profileHeaderLabel.text = split.header
                profileHeaderLabel.isHidden = split.header == nil
                profileHeaderLabel.alpha = split.header == nil ? 0 : 0.66
                profileLabel.text = split.body
                profileLabel.isHidden = split.body == nil
                profileLabel.alpha = split.body == nil ? 0 : 0.60
                profileLabel.numberOfLines = 0
            } else {
                profileHeaderLabel.isHidden = true
                profileHeaderLabel.alpha = 0
                profileLabel.isHidden = true
                profileLabel.alpha = 0
            }
            studioLabel.isHidden = false
            studioLabel.alpha = 0.26

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
            let compact = size.height < 760
            let retentionTextWidth = panelWidth - 34
            let retentionSingleLineHeight: CGFloat = compact ? 14 : 15
            let retentionHeaderLineHeight: CGFloat = compact ? 12.5 : 13.5
            let retentionBlockLineHeight: CGFloat = compact ? 13 : 14
            let retentionBlockPadding: CGFloat = compact ? 5 : 6
            let retentionHeaderBodyGap: CGFloat = compact ? 4 : 5
            let retentionSectionGap: CGFloat = compact ? 10 : 12
            let retentionEditorialLeadGap: CGFloat = compact ? 10 : 12
            let controlRetentionGap: CGFloat = compact ? 14 : 17
            let studioBandHeight: CGFloat = compact ? 15 : 17
            let studioTopGap: CGFloat = compact ? 10 : 12
            let labelFitScale: CGFloat = 0.88

            func multilineBlockHeight(for label: SKLabelNode) -> CGFloat {
                guard !label.isHidden, let text = label.text, !text.isEmpty else { return 0 }
                let lineCount = max(1, text.components(separatedBy: "\n").count)
                return CGFloat(lineCount) * retentionBlockLineHeight + retentionBlockPadding
            }

            func singleLineBandHeight(isVisible: Bool) -> CGFloat {
                guard isVisible else { return 0 }
                return retentionSingleLineHeight + retentionSectionGap
            }

            func editorialSectionHeight(header: SKLabelNode, body: SKLabelNode) -> CGFloat {
                guard !header.isHidden else { return 0 }
                var height = retentionEditorialLeadGap + retentionHeaderLineHeight
                if !body.isHidden {
                    height += retentionHeaderBodyGap + multilineBlockHeight(for: body)
                }
                return height + retentionSectionGap
            }

            let residueBandHeight = singleLineBandHeight(isVisible: !residueLabel.isHidden)
            let masteryBandHeight = singleLineBandHeight(isVisible: !masteryLabel.isHidden)
            let ritualBandHeight = editorialSectionHeight(header: ritualHeaderLabel, body: ritualLabel)
            let profileBandHeight = editorialSectionHeight(header: profileHeaderLabel, body: profileLabel)
            let retentionStackHeight = residueBandHeight + masteryBandHeight + ritualBandHeight + profileBandHeight
            let studioBand = studioBandHeight + bottomInset + 6
            let controlsHeight = topInset + CGFloat(visibleRows.count) * rowHeight
            let panelHeight = max(
                72,
                controlsHeight + (retentionStackHeight > 0 ? controlRetentionGap + retentionStackHeight : 0)
                    + studioBand
            )

            let buttonPosition = button.position
            let maxPanelX = size.width - metrics.sideInset - panelWidth * 0.5
            let targetX = min(buttonPosition.x - panelWidth * 0.5 + 16, maxPanelX)
            menuNode.position = CGPoint(x: targetX, y: buttonPosition.y - panelHeight * 0.5 - (compact ? 24 : 28))
            let rect = CGRect(x: -panelWidth * 0.5, y: -panelHeight * 0.5, width: panelWidth, height: panelHeight)
            menuBackground.path = UIBezierPath(roundedRect: rect, cornerRadius: compact ? 16 : 18).cgPath

            var currentY = panelHeight * 0.5 - topInset - 1
            for row in visibleRows {
                row.position = CGPoint(x: leftX, y: currentY)
                fitLabelWidth(row, panelWidth - 32, 0.82)
                currentY -= rowHeight
            }

            let footerFloor = -panelHeight * 0.5 + bottomInset + 4
            studioLabel.position = CGPoint(x: 0, y: footerFloor + studioBandHeight * 0.5)
            fitLabelWidth(studioLabel, retentionTextWidth, labelFitScale)

            var cursorY = currentY - controlRetentionGap

            func placeEditorialSectionTopDown(header: SKLabelNode, body: SKLabelNode) {
                guard !header.isHidden else { return }
                cursorY -= retentionEditorialLeadGap
                header.position = CGPoint(x: 0, y: cursorY - retentionHeaderLineHeight * 0.5)
                fitLabelWidth(header, retentionTextWidth, labelFitScale)
                cursorY -= retentionHeaderLineHeight
                if !body.isHidden {
                    cursorY -= retentionHeaderBodyGap
                    let blockHeight = multilineBlockHeight(for: body)
                    body.position = CGPoint(x: 0, y: cursorY - blockHeight * 0.5)
                    fitLabelWidth(body, retentionTextWidth, labelFitScale)
                    cursorY -= blockHeight
                }
                cursorY -= retentionSectionGap
            }

            func placeSingleLineTopDown(_ label: SKLabelNode) {
                guard !label.isHidden else { return }
                label.position = CGPoint(x: 0, y: cursorY - retentionSingleLineHeight * 0.5)
                fitLabelWidth(label, retentionTextWidth, labelFitScale)
                cursorY -= retentionSingleLineHeight + retentionSectionGap
            }

            placeEditorialSectionTopDown(header: profileHeaderLabel, body: profileLabel)
            placeEditorialSectionTopDown(header: ritualHeaderLabel, body: ritualLabel)
            placeSingleLineTopDown(masteryLabel)
            placeSingleLineTopDown(residueLabel)
        }

        private static func splitRitualBlock(_ block: String) -> (header: String?, body: String?) {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard let header = lines.first else { return (nil, nil) }
            let body = Array(lines.dropFirst().prefix(2)).joined(separator: "\n")
            return (header, body.isEmpty ? nil : body)
        }

        private static func splitProfileBlock(_ block: String) -> (header: String?, body: String?) {
            let lines = block.components(separatedBy: "\n").filter { !$0.isEmpty }
            guard let header = lines.first else { return (nil, nil) }
            let body = Array(lines.dropFirst().prefix(2)).joined(separator: "\n")
            return (header, body.isEmpty ? nil : body)
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
            residueLabel: utilityResidueLabel,
            masteryLabel: utilityMasteryLabel,
            ritualHeaderLabel: utilityRitualHeaderLabel,
            ritualLabel: utilityRitualLabel,
            profileHeaderLabel: utilityProfileHeaderLabel,
            profileLabel: utilityProfileLabel,
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

        utilityResidueLabel = label("", size: 11, alpha: 0.60, align: .center, weight: true)
        utilityResidueLabel.name = "utility.residue"
        utilityResidueLabel.fontColor = UIColor(hex: "D2D8EA")
        utilityResidueLabel.isHidden = true
        utilityMenuNode.addChild(utilityResidueLabel)

        utilityMasteryLabel = label("", size: 11, alpha: 0.58, align: .center, weight: true)
        utilityMasteryLabel.name = "utility.mastery"
        utilityMasteryLabel.fontColor = UIColor(hex: "C8CEDF")
        utilityMasteryLabel.isHidden = true
        utilityMenuNode.addChild(utilityMasteryLabel)

        utilityRitualHeaderLabel = label("", size: 10.5, alpha: 0.66, align: .center, weight: true)
        utilityRitualHeaderLabel.name = "utility.ritual.header"
        utilityRitualHeaderLabel.fontColor = UIColor(hex: "DDE2F2")
        utilityRitualHeaderLabel.isHidden = true
        utilityMenuNode.addChild(utilityRitualHeaderLabel)

        utilityRitualLabel = label("", size: 10.5, alpha: 0.60, align: .center, weight: false)
        utilityRitualLabel.name = "utility.ritual"
        utilityRitualLabel.fontColor = UIColor(hex: "B8C0D6")
        utilityRitualLabel.isHidden = true
        utilityRitualLabel.numberOfLines = 0
        utilityMenuNode.addChild(utilityRitualLabel)

        utilityProfileHeaderLabel = label("", size: 10.5, alpha: 0.66, align: .center, weight: true)
        utilityProfileHeaderLabel.name = "utility.profile.header"
        utilityProfileHeaderLabel.fontColor = UIColor(hex: "DDE2F2")
        utilityProfileHeaderLabel.isHidden = true
        utilityMenuNode.addChild(utilityProfileHeaderLabel)

        utilityProfileLabel = label("", size: 10.5, alpha: 0.60, align: .center, weight: false)
        utilityProfileLabel.name = "utility.profile"
        utilityProfileLabel.fontColor = UIColor(hex: "B8C0D6")
        utilityProfileLabel.isHidden = true
        utilityProfileLabel.numberOfLines = 0
        utilityMenuNode.addChild(utilityProfileLabel)

        utilityStudioLabel = label(VexloStrings.Utility.studio, size: 9.5, alpha: 0.26, align: .center, weight: true)
        utilityStudioLabel.name = "utility.studio"
        utilityMenuNode.addChild(utilityStudioLabel)

        syncUtilitySurface()
    }

    private func utilityResidueLine() -> String? {
        guard !LaunchSupport.shared.isCaptureMode else { return nil }
        return RunResiduePersistenceService.shared.loadLast()?.utilityResidueLine()
    }

    private func utilityMasteryLine() -> String? {
        MasteryRecognitionService.shared.utilityMasteryLine()
    }

    private func utilityRitualBlock() -> String? {
        DailyCodexService.shared.utilityRitualBlock()
    }

    private func utilityProfileBlock() -> String? {
        ReaderProfileService.shared.utilityProfileBlock()
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
                    !isPresentingNewRunConfirmation,
                residueLine: utilityResidueLine(),
                masteryLine: utilityMasteryLine(),
                ritualBlock: utilityRitualBlock(),
                profileBlock: utilityProfileBlock()
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
