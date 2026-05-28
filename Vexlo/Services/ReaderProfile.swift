import Foundation

/// Editorial synthesis of recent reading play (Reader Profile v1).
struct ReaderProfile: Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let headline: String
    let strength: String
    let growthEdge: String
    let basisRunCount: Int
    let synthesizedAt: Date

    func utilityBlock() -> String {
        [
            VexloStrings.ReaderProfile.sectionHeader,
            headline,
            strength,
            growthEdge
        ].joined(separator: "\n")
    }
}
