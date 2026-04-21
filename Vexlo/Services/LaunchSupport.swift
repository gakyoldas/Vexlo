import Foundation

enum CaptureState: String {
    case normalRun = "normal-run"
    case normalHero = "normal-hero"
    case dailyChallenge = "daily-challenge"
    case dailyHero = "daily-hero"
    case normalResult = "normal-result"
    case dailyResult = "daily-result"
    case utilitySurface = "utility-surface"
}

enum CaptureIntent: String {
    case editorial
    case `internal`
}

final class LaunchSupport {
    static let shared = LaunchSupport()

    private enum Arguments {
        static let captureState = "-VexloCaptureState"
        static let captureScore = "-VexloCaptureScore"
        static let captureIntent = "-VexloCaptureIntent"
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

    var captureIntent: CaptureIntent {
        guard let value = argumentValue(for: Arguments.captureIntent) else { return .editorial }
        return CaptureIntent(rawValue: value) ?? .editorial
    }

    var isInternalCapture: Bool {
        isCaptureMode && captureIntent == .internal
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

    var captureNormalHeroSeed: UInt64 {
        0x0000FACADE17
    }

    var captureDailyDayID: String {
        "2025-01-15"
    }
}
