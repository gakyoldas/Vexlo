import Foundation

enum CaptureState: String {
    case normalRun = "normal-run"
    case dailyChallenge = "daily-challenge"
    case normalResult = "normal-result"
    case dailyResult = "daily-result"
}

final class LaunchSupport {
    static let shared = LaunchSupport()

    private enum Arguments {
        static let captureState = "-VexloCaptureState"
    }

    private init() {}

    var captureState: CaptureState? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: Arguments.captureState),
              arguments.indices.contains(index + 1) else {
            return nil
        }
        return CaptureState(rawValue: arguments[index + 1])
    }

    var isCaptureMode: Bool {
        captureState != nil
    }

    var isResultOverlayCapture: Bool {
        switch captureState {
        case .normalResult, .dailyResult:
            return true
        default:
            return false
        }
    }

    var captureNormalSeed: UInt64 {
        0x0000C0FFEE42
    }

    var captureDailyDayID: String {
        "2025-01-15"
    }
}
