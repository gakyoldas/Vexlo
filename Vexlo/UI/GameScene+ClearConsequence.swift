import SpriteKit
import UIKit

extension GameScene {
    func applyClearConsequenceEmptyDragPreview(
        to node: SKShapeNode,
        multiClear: Bool,
        accentColor: UIColor?
    ) {
        node.setScale(multiClear ? 1.042 : 1.036)
        node.alpha = multiClear ? 1.0 : 0.98
        node.fillColor = ClearConsequenceSurface.previewEmptyFill(accent: accentColor, multiClear: multiClear)
        node.strokeColor = ClearConsequenceSurface.previewEmptyStroke(multiClear: multiClear)
        node.lineWidth = multiClear ? 1.52 : 1.42
        node.lineJoin = .round
        if let material = node.childNode(withName: "board.emptyMaterial") as? SKShapeNode {
            material.isHidden = false
            material.alpha = 1.0
            let accent = accentColor ?? UIColor(hex: "EAF7F2")
            material.fillColor = accent.withAlphaComponent(multiClear ? 0.40 : 0.34)
            material.strokeColor = UIColor.white.withAlphaComponent(multiClear ? 0.26 : 0.22)
            material.setScale(multiClear ? 1.10 : 1.06)
        }
        if let highlight = node.childNode(withName: "highlight") as? SKShapeNode {
            highlight.isHidden = false
            highlight.alpha = 1.0
            highlight.fillColor = ClearConsequenceSurface.previewEmptyGlint(multiClear: multiClear).withAlphaComponent(multiClear ? 0.30 : 0.26)
            highlight.strokeColor = .clear
            highlight.setScale(multiClear ? 1.04 : 1.01)
        }
    }

    func applyClearConsequenceOccupiedDragPreview(
        to node: SKShapeNode,
        boardColor: UIColor,
        multiClear: Bool
    ) {
        applyFilledCellStyle(node, color: boardColor)
        suppressDragPreviewMaskingLayers(on: node)
        node.setScale(multiClear ? 1.034 : 1.028)
        node.alpha = 1.0
        node.fillColor = boardColor.withAlphaComponent(0.985)
        node.strokeColor = ClearConsequenceSurface.jewelCommitGlint(boardColor, multiClear: multiClear)
            .withAlphaComponent(multiClear ? 0.54 : 0.48)
        node.lineWidth = multiClear ? 1.34 : 1.24
        node.lineJoin = .round
        if let highlight = node.childNode(withName: "fillHighlight") as? SKShapeNode {
            highlight.isHidden = false
            highlight.alpha = 1.0
            highlight.fillColor = ClearConsequenceSurface.jewelCommitGlint(boardColor, multiClear: multiClear).withAlphaComponent(multiClear ? 0.61 : 0.55)
            highlight.setScale(multiClear ? 1.10 : 1.06)
        }
    }

    func runLineClearCommitAnimation(
        coords: [HexCoordinate],
        completingPlacementCoords: Set<HexCoordinate>,
        clearedJewelColors: [HexCoordinate: UIColor],
        prefersReducedMotion: Bool,
        cellNodes: [HexCoordinate: SKShapeNode],
        applyEmptyCellAppearance: @escaping (HexCoordinate, SKShapeNode) -> Void,
        completion: @escaping () -> Void
    ) {
        guard !coords.isEmpty else {
            completion()
            return
        }

        let sortCoords: (HexCoordinate, HexCoordinate) -> Bool = { lhs, rhs in
            (lhs.col, lhs.row) < (rhs.col, rhs.row)
        }
        let completing = coords.filter { completingPlacementCoords.contains($0) }.sorted(by: sortCoords)
        let remainder = coords.filter { !completingPlacementCoords.contains($0) }.sorted(by: sortCoords)
        let sorted = completing + remainder
        let timing = ClearConsequenceSurface.commitAnimationTiming(
            prefersReducedMotion: prefersReducedMotion
        )

        if prefersReducedMotion {
            for coord in sorted {
                guard let node = cellNodes[coord] else { continue }
                node.removeAllActions()
                applyEmptyCellAppearance(coord, node)
                node.setScale(1.0)
                node.alpha = 1.0
            }
            completion()
            return
        }

        for (index, coord) in sorted.enumerated() {
            guard let node = cellNodes[coord] else { continue }
            node.removeAllActions()
            suppressDragPreviewMaskingLayers(on: node)
            let jewelColor = clearedJewelColors[coord]
            let wait = SKAction.wait(forDuration: TimeInterval(index) * timing.stagger)
            let brighten = SKAction.run {
                node.alpha = 1.0
                node.setScale(1.022)
                if let jewelColor {
                    node.fillColor = ClearConsequenceSurface.jewelCommitFill(jewelColor)
                    node.strokeColor = ClearConsequenceSurface.jewelCommitStroke(jewelColor, multiClear: false)
                    node.lineWidth = 1.08
                    if let highlight = node.childNode(withName: "fillHighlight") as? SKShapeNode {
                        highlight.isHidden = false
                        highlight.alpha = 1.0
                        highlight.fillColor = ClearConsequenceSurface.jewelCommitGlint(jewelColor, multiClear: false)
                    } else if let highlight = node.childNode(withName: "highlight") as? SKShapeNode {
                        highlight.isHidden = false
                        highlight.alpha = 1.0
                        highlight.fillColor = ClearConsequenceSurface.jewelCommitGlint(jewelColor, multiClear: false)
                    }
                } else {
                    let mineral = ClearConsequenceSurface.emptyDissolveMineral()
                    node.fillColor = mineral.withAlphaComponent(0.34)
                    node.strokeColor = UIColor.white.withAlphaComponent(0.28)
                    node.lineWidth = 1.02
                }
            }
            let dwell = SKAction.wait(forDuration: timing.dwell)
            let dissolve = SKAction.group([
                SKAction.fadeAlpha(to: 0.0, duration: timing.dissolve),
                SKAction.scale(to: 0.968, duration: timing.dissolve)
            ])
            let restore = SKAction.run {
                node.removeAllActions()
                node.setScale(1.0)
                node.alpha = 1.0
                applyEmptyCellAppearance(coord, node)
            }
            node.run(SKAction.sequence([wait, brighten, dwell, dissolve, restore]))
        }

        let total = timing.totalDuration(cellCount: sorted.count)
        run(SKAction.sequence([
            SKAction.wait(forDuration: total),
            SKAction.run(completion)
        ]))
    }
}
