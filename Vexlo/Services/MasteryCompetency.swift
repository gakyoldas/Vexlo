import Foundation

/// Behavioral reading competencies (Mastery v1). Binary recognized state only.
enum MasteryCompetency: String, Codable, CaseIterable, Equatable {
    case laneReader = "lane_reader"
    case anchorReader = "anchor_reader"
    case pressureReader = "pressure_reader"
    case chainReader = "chain_reader"
    case recoveryReader = "recovery_reader"

    var displayName: String {
        switch self {
        case .laneReader:
            return VexloStrings.Mastery.laneReader
        case .anchorReader:
            return VexloStrings.Mastery.anchorReader
        case .pressureReader:
            return VexloStrings.Mastery.pressureReader
        case .chainReader:
            return VexloStrings.Mastery.chainReader
        case .recoveryReader:
            return VexloStrings.Mastery.recoveryReader
        }
    }

    static let utilityDisplayOrder: [MasteryCompetency] = [
        .anchorReader,
        .laneReader,
        .pressureReader,
        .chainReader,
        .recoveryReader
    ]
}

struct MasteryRecognitionState: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let recognized: [String]

    static let empty = MasteryRecognitionState(
        schemaVersion: currentSchemaVersion,
        recognized: []
    )

    var recognizedCompetencies: Set<MasteryCompetency> {
        Set(recognized.compactMap(MasteryCompetency.init(rawValue:)))
    }

    init(schemaVersion: Int, recognized: Set<MasteryCompetency>) {
        self.schemaVersion = schemaVersion
        self.recognized = recognized.map(\.rawValue).sorted()
    }

    init(schemaVersion: Int, recognized: [String]) {
        self.schemaVersion = schemaVersion
        self.recognized = recognized.sorted()
    }

    func utilityLine() -> String? {
        let names = MasteryCompetency.utilityDisplayOrder
            .filter { recognizedCompetencies.contains($0) }
            .map(\.displayName)
        guard !names.isEmpty else { return nil }
        return VexloStrings.Mastery.readingPattern(names.joined(separator: " · "))
    }
}
