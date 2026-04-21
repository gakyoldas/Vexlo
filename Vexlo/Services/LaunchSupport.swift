import Foundation

enum CaptureState: String {
    case normalRun = "normal-run"
    case dailyChallenge = "daily-challenge"
    case normalResult = "normal-result"
    case dailyResult = "daily-result"
    case utilitySurface = "utility-surface"
}

final class LaunchSupport {
    static let shared = LaunchSupport()

    private enum Arguments {
        static let captureState = "-VexloCaptureState"
        static let captureScore = "-VexloCaptureScore"
    }

    private init() {}

    var captureState: CaptureState? {
        guard let value = argumentValue(for: Arguments.captureState) else { return nil }
        return CaptureState(rawValue: value)
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

    var isUtilitySurfaceCapture: Bool {
        captureState == .utilitySurface
    }

    var captureScoreOverride: Int? {
        guard let value = argumentValue(for: Arguments.captureScore),
              let score = Int(value) else { return nil }
        return max(0, score)
    }

    private func argumentValue(for key: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        for (index, argument) in arguments.enumerated() {
            if argument == key, arguments.indices.contains(index + 1) {
                return arguments[index + 1]
            }
            if argument.hasPrefix(key + "=") {
                return String(argument.dropFirst(key.count + 1))
            }
            if argument.hasPrefix(key + " ") {
                return String(argument.dropFirst(key.count + 1))
            }
        }
        return nil
    }

    var captureNormalSeed: UInt64 {
        0x0000C0FFEE42
    }

    var captureDailyDayID: String {
        "2025-01-15"
    }
}
