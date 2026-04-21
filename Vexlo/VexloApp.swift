import SwiftUI

struct VexloApp: App {
    init() {
        ICloudProgressSyncService.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            GameView()
                .onOpenURL { url in
                    SystemEntryService.shared.queue(url: url)
                }
        }
    }
}
