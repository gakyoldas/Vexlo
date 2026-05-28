import Foundation

/// Deterministic editorial profile synthesis from retention spine data (Reader Profile v1).
enum ReaderProfileEvaluator {
    static let profileWindow = 7
    static let minimumRunCount = 3

    enum DominantReadingStyle: Equatable {
        case chainLed
        case anchorLed
        case pressureLed
        case laneLed
        case recoveryLed
        case tightBoard
    }

    struct SynthesisInput: Equatable {
        let recentResidues: [RunResidueRecord]
        let recognizedMastery: Set<MasteryCompetency>
    }

    static func synthesize(
        input: SynthesisInput,
        timestamp: Date = Date()
    ) -> ReaderProfile? {
        let window = Array(input.recentResidues.prefix(profileWindow))
        guard window.count >= minimumRunCount else { return nil }

        let lessonCounts = lessonCounts(in: window)
        let style = dominantStyle(in: window, lessonCounts: lessonCounts)
        let strength = strengthLine(
            for: style,
            recognizedMastery: input.recognizedMastery,
            lessonCounts: lessonCounts
        )
        let growthEdge = growthEdgeLine(
            for: style,
            in: window,
            lessonCounts: lessonCounts
        )

        return ReaderProfile(
            schemaVersion: ReaderProfile.currentSchemaVersion,
            headline: headline(for: style),
            strength: strength,
            growthEdge: growthEdge,
            basisRunCount: window.count,
            synthesizedAt: timestamp
        )
    }

    private static func lessonCounts(in window: [RunResidueRecord]) -> [RunResidueRecord.LessonFlag: Int] {
        var counts: [RunResidueRecord.LessonFlag: Int] = [:]
        for residue in window where residue.didClearAny {
            counts[residue.lessonFlag, default: 0] += 1
        }
        return counts
    }

    private static func dominantStyle(
        in window: [RunResidueRecord],
        lessonCounts: [RunResidueRecord.LessonFlag: Int]
    ) -> DominantReadingStyle {
        let clearCount = window.filter(\.didClearAny).count
        let noClearCount = window.count - clearCount
        if noClearCount >= (window.count + 1) / 2, clearCount < 2 {
            return .tightBoard
        }

        let ranked: [(RunResidueRecord.LessonFlag, Int)] = [
            (.chainConversion, lessonCounts[.chainConversion, default: 0]),
            (.pressureRelease, lessonCounts[.pressureRelease, default: 0]),
            (.anchorDiscipline, lessonCounts[.anchorDiscipline, default: 0]),
            (.laneOpening, lessonCounts[.laneOpening, default: 0]),
            (.recoveryTiming, lessonCounts[.recoveryTiming, default: 0])
        ]
        guard let top = ranked.max(by: { $0.1 < $1.1 }), top.1 > 0 else {
            return .anchorLed
        }

        switch top.0 {
        case .chainConversion:
            return .chainLed
        case .pressureRelease:
            return .pressureLed
        case .anchorDiscipline:
            return .anchorLed
        case .laneOpening:
            return .laneLed
        case .recoveryTiming:
            return .recoveryLed
        case .noClear:
            return .tightBoard
        }
    }

    private static func headline(for style: DominantReadingStyle) -> String {
        switch style {
        case .chainLed:
            return VexloStrings.ReaderProfile.headlineChainLed
        case .anchorLed:
            return VexloStrings.ReaderProfile.headlineAnchorLed
        case .pressureLed:
            return VexloStrings.ReaderProfile.headlinePressureLed
        case .laneLed:
            return VexloStrings.ReaderProfile.headlineLaneLed
        case .recoveryLed:
            return VexloStrings.ReaderProfile.headlineRecoveryLed
        case .tightBoard:
            return VexloStrings.ReaderProfile.headlineTightBoard
        }
    }

    private static func strengthLine(
        for style: DominantReadingStyle,
        recognizedMastery: Set<MasteryCompetency>,
        lessonCounts: [RunResidueRecord.LessonFlag: Int]
    ) -> String {
        if recognizedMastery.contains(.chainReader), style == .chainLed {
            return VexloStrings.ReaderProfile.strengthChainReader
        }
        if recognizedMastery.contains(.pressureReader), style == .pressureLed {
            return VexloStrings.ReaderProfile.strengthPressureReader
        }
        if recognizedMastery.contains(.anchorReader), style == .anchorLed {
            return VexloStrings.ReaderProfile.strengthAnchorReader
        }
        if recognizedMastery.contains(.laneReader), style == .laneLed {
            return VexloStrings.ReaderProfile.strengthLaneReader
        }
        if recognizedMastery.contains(.recoveryReader), style == .recoveryLed {
            return VexloStrings.ReaderProfile.strengthRecoveryReader
        }

        switch style {
        case .chainLed:
            return VexloStrings.ReaderProfile.strengthChainLed
        case .anchorLed:
            return VexloStrings.ReaderProfile.strengthAnchorLed
        case .pressureLed:
            return VexloStrings.ReaderProfile.strengthPressureLed
        case .laneLed:
            return VexloStrings.ReaderProfile.strengthLaneLed
        case .recoveryLed:
            return VexloStrings.ReaderProfile.strengthRecoveryLed
        case .tightBoard:
            if lessonCounts[.laneOpening, default: 0] > 0 {
                return VexloStrings.ReaderProfile.strengthTightWithLanes
            }
            return VexloStrings.ReaderProfile.strengthTightBoard
        }
    }

    private static func growthEdgeLine(
        for style: DominantReadingStyle,
        in window: [RunResidueRecord],
        lessonCounts: [RunResidueRecord.LessonFlag: Int]
    ) -> String {
        let laneCount = lessonCounts[.laneOpening, default: 0]
        let pressureCount = lessonCounts[.pressureRelease, default: 0]
        let chainCount = lessonCounts[.chainConversion, default: 0]
        let anchorCount = lessonCounts[.anchorDiscipline, default: 0]
        let tautCount = window.filter { $0.terminalPressureBand == "taut" && $0.didClearAny }.count

        switch style {
        case .chainLed:
            if laneCount >= 2 {
                return VexloStrings.ReaderProfile.growthOpenLaneEarlier
            }
            if pressureCount == 0, tautCount >= 2 {
                return VexloStrings.ReaderProfile.growthReleaseUnderPressure
            }
            return VexloStrings.ReaderProfile.growthExtendChainConversion
        case .anchorLed:
            if chainCount >= 2 {
                return VexloStrings.ReaderProfile.growthExtendChainConversion
            }
            if laneCount >= 2 {
                return VexloStrings.ReaderProfile.growthOpenLaneEarlier
            }
            return VexloStrings.ReaderProfile.growthKeepAnchorOpen
        case .pressureLed:
            if anchorCount >= 2 {
                return VexloStrings.ReaderProfile.growthKeepAnchorOpen
            }
            return VexloStrings.ReaderProfile.growthReleaseEarlier
        case .laneLed:
            if anchorCount >= 2 {
                return VexloStrings.ReaderProfile.growthKeepAnchorOpen
            }
            return VexloStrings.ReaderProfile.growthOpenLaneEarlier
        case .recoveryLed:
            if anchorCount >= 2 {
                return VexloStrings.ReaderProfile.growthStabilizeEarlier
            }
            return VexloStrings.ReaderProfile.growthKeepAnchorOpen
        case .tightBoard:
            return VexloStrings.ReaderProfile.growthOpenLaneEarlier
        }
    }
}
