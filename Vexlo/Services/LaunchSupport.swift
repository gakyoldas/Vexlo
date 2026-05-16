import Foundation

enum CaptureState: String {
    case normalRun = "normal-run"
    case normalHero = "normal-hero"
    case normalComboReview = "normal-combo-review"
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

struct CaptureLaunchConfiguration: Equatable {
    private enum Arguments {
        static let captureState = "-VexloCaptureState"
        static let captureScore = "-VexloCaptureScore"
        static let captureIntent = "-VexloCaptureIntent"
    }

    let state: CaptureState?
    let intent: CaptureIntent
    let resultScoreOverride: Int?

    var isCaptureMode: Bool {
        state != nil
    }

    var isResultOverlayCapture: Bool {
        switch state {
        case .normalResult, .dailyResult:
            return true
        default:
            return false
        }
    }

    var isUtilitySurfaceCapture: Bool {
        state == .utilitySurface
    }

    var isInternalCapture: Bool {
        isCaptureMode && intent == .internal
    }

    init(arguments: [String]) {
        state = CaptureLaunchConfiguration.captureState(in: arguments)
        intent = CaptureLaunchConfiguration.captureIntent(in: arguments)

        if state == .normalResult || state == .dailyResult {
            resultScoreOverride = CaptureLaunchConfiguration.captureScoreOverride(in: arguments)
        } else {
            resultScoreOverride = nil
        }
    }

    private static func captureState(in arguments: [String]) -> CaptureState? {
        guard let value = argumentValue(for: Arguments.captureState, in: arguments) else { return nil }
        return CaptureState(rawValue: value)
    }

    private static func captureIntent(in arguments: [String]) -> CaptureIntent {
        guard let value = argumentValue(for: Arguments.captureIntent, in: arguments) else { return .editorial }
        return CaptureIntent(rawValue: value) ?? .editorial
    }

    private static func captureScoreOverride(in arguments: [String]) -> Int? {
        guard let value = argumentValue(for: Arguments.captureScore, in: arguments),
              let score = Int(value) else { return nil }
        return max(0, score)
    }

    private static func argumentValue(for key: String, in arguments: [String]) -> String? {
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
}

final class LaunchSupport {
    static let shared = LaunchSupport()

    private var configuration: CaptureLaunchConfiguration {
        CaptureLaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)
    }

    private init() {}

    var captureState: CaptureState? {
        configuration.state
    }

    var isCaptureMode: Bool {
        configuration.isCaptureMode
    }

    var isResultOverlayCapture: Bool {
        configuration.isResultOverlayCapture
    }

    var isUtilitySurfaceCapture: Bool {
        configuration.isUtilitySurfaceCapture
    }

    var captureIntent: CaptureIntent {
        configuration.intent
    }

    var isInternalCapture: Bool {
        configuration.isInternalCapture
    }

    var captureScoreOverride: Int? {
        configuration.resultScoreOverride
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
