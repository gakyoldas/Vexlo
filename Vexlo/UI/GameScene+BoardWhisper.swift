import SpriteKit
import UIKit

extension GameScene {
    static func shouldApplyBoardWhisper(boardStructuralSemanticsActive: Bool, isTerminal: Bool) -> Bool {
        boardStructuralSemanticsActive && !isTerminal
    }

    static func boardWhisperMaterialAlphaDelta(for whisper: BoardCellWhisper) -> CGFloat {
        switch whisper {
        case .calm:
            return 0
        case .attentive:
            return 0.006
        case .taut:
            return 0.012
        }
    }

    static func boardWhisperStrokeAlphaDelta(for whisper: BoardCellWhisper) -> CGFloat {
        switch whisper {
        case .calm:
            return 0
        case .attentive:
            return 0.012
        case .taut:
            return 0.020
        }
    }

    static func applyBoardWhisper(
        to material: SKShapeNode,
        strokeOn node: SKShapeNode,
        whisper: BoardCellWhisper
    ) {
        guard whisper != .calm else { return }
        let materialAlpha = material.fillColor.cgColor.alpha + boardWhisperMaterialAlphaDelta(for: whisper)
        let strokeAlpha = node.strokeColor.cgColor.alpha + boardWhisperStrokeAlphaDelta(for: whisper)
        material.fillColor = material.fillColor.withAlphaComponent(min(1, materialAlpha))
        node.strokeColor = node.strokeColor.withAlphaComponent(min(1, strokeAlpha))
    }
}
