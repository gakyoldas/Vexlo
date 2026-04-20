import UIKit
import GameKit
import SwiftUI

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        AnalyticsService.shared.recordSessionStart()
        MonetizationService.shared.beginSessionIfNeeded()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: GameView())
        window.makeKeyAndVisible()
        self.window = window
        GameCenterService.shared.configure { [weak self] in
            self?.window?.rootViewController
        }
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        GameScene.shared.persistLiveRunIfNeeded()
    }
}
