import SpriteKit
import SwiftUI

struct GameView: View {
    var body: some View {
        SpriteView(scene: GameScene.shared)
            .ignoresSafeArea()
    }
}
