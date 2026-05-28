import Foundation
import UIKit

struct HexPiece {
    let offsets: [HexCoordinate]
    let color: UIColor
}

enum PieceFactory {
    struct GenerationMemory {
        struct Snapshot: Codable {
            let recentTemplateIDs: [String]
            let recentAxes: [String]
            let recentSizes: [Int]
            let recentRoles: [String]
            let batchCount: Int
        }

        fileprivate var recentTemplateIDs: [String] = []
        fileprivate var recentAxes: [Axis] = []
        fileprivate var recentSizes: [Int] = []
        fileprivate var recentRoles: [Role] = []
        fileprivate var batchCount: Int = 0

        init() {}

        init(snapshot: Snapshot) {
            recentTemplateIDs = snapshot.recentTemplateIDs
            recentAxes = snapshot.recentAxes.compactMap(Axis.init(rawValue:))
            recentSizes = snapshot.recentSizes
            recentRoles = snapshot.recentRoles.compactMap(Role.init(rawValue:))
            batchCount = snapshot.batchCount
        }

        var snapshot: Snapshot {
            Snapshot(
                recentTemplateIDs: recentTemplateIDs,
                recentAxes: recentAxes.map(\.rawValue),
                recentSizes: recentSizes,
                recentRoles: recentRoles.map(\.rawValue),
                batchCount: batchCount
            )
        }

        fileprivate mutating func record(_ profiles: [TemplateProfile]) {
            recentTemplateIDs = Array((recentTemplateIDs + profiles.map(\.template.id)).suffix(6))
            recentAxes = Array((recentAxes + profiles.map(\.axis)).suffix(4))
            recentSizes = Array((recentSizes + profiles.map(\.size)).suffix(6))
            recentRoles = Array((recentRoles + profiles.map(\.role)).suffix(4))
            batchCount += 1
        }
    }

    struct SeededGenerator: RandomNumberGenerator {
        private var state: UInt64

        init(seed: UInt64) {
            state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
        }

        init(stateSnapshot: UInt64) {
            state = stateSnapshot == 0 ? 0x9E3779B97F4A7C15 : stateSnapshot
        }

        var stateSnapshot: UInt64 {
            state
        }

        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var value = state
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            return value ^ (value >> 31)
        }
    }

    fileprivate struct Template {
        let id: String
        let offsets: [HexCoordinate]
        let tier: Int
    }

    fileprivate enum Axis: String, Hashable {
        case vertical
        case horizontal
        case mixed
    }

    fileprivate enum Role: String, Hashable {
        case relief
        case pivot
        case pressure
    }

    fileprivate enum GenerationProfile {
        case standard
        case normalModeEarlyTension
    }

    enum BoardCharacter: Int {
        case open = 0      // glacial: relief-biased, spacious opening
        case balanced = 1  // lucid: unchanged distribution
        case focused = 2   // iris: pivot-biased, denser reading
    }

    fileprivate struct TemplateProfile {
        let template: Template
        let size: Int
        let axis: Axis
        let role: Role
        let heaviness: Int
        let flexibility: Int
    }

    private static let templates: [Template] = [
        Template(id: "single", offsets: [HexCoordinate(0,0)], tier: 0),
        Template(id: "line2v", offsets: [HexCoordinate(0,0), HexCoordinate(0,1)], tier: 0),
        Template(id: "line3v", offsets: [HexCoordinate(0,0), HexCoordinate(0,1), HexCoordinate(0,2)], tier: 0),
        Template(id: "line2h", offsets: [HexCoordinate(0,0), HexCoordinate(1,0)], tier: 0),
        Template(id: "cornerA", offsets: [HexCoordinate(0,0), HexCoordinate(1,0), HexCoordinate(0,1)], tier: 1),
        Template(id: "cornerB", offsets: [HexCoordinate(0,0), HexCoordinate(1,0), HexCoordinate(1,1)], tier: 1),
        Template(id: "cornerC", offsets: [HexCoordinate(0,0), HexCoordinate(0,1), HexCoordinate(1,1)], tier: 1),
        Template(id: "hook3", offsets: [HexCoordinate(0,0), HexCoordinate(1,0), HexCoordinate(1,2)], tier: 2),
        Template(id: "tee4", offsets: [HexCoordinate(0,0), HexCoordinate(0,1), HexCoordinate(0,2), HexCoordinate(1,1)], tier: 2),
        Template(id: "block4", offsets: [HexCoordinate(0,0), HexCoordinate(1,0), HexCoordinate(0,1), HexCoordinate(1,1)], tier: 2),
        Template(id: "line4h", offsets: [HexCoordinate(0,0), HexCoordinate(1,0), HexCoordinate(2,0), HexCoordinate(3,0)], tier: 2),
    ]

    private static let palette: [UIColor] = [
        UIColor(hex: "7A74F7"),
        UIColor(hex: "6A8CFA"),
        UIColor(hex: "55A7F6"),
        UIColor(hex: "52C0E0"),
        UIColor(hex: "63C7B0"),
        UIColor(hex: "8DBB8A"),
    ]

    static func openingBatch(count: Int) -> [HexPiece] {
        var generator = SystemRandomNumberGenerator()
        var memory = GenerationMemory()
        return makeBatch(
            count: count,
            occupiedCellCount: 0,
            opening: true,
            generationProfile: .normalModeEarlyTension,
            memory: &memory,
            using: &generator
        )
    }

    static func randomBatch(count: Int, occupiedCellCount: Int) -> [HexPiece] {
        var generator = SystemRandomNumberGenerator()
        var memory = GenerationMemory()
        return makeBatch(
            count: count,
            occupiedCellCount: occupiedCellCount,
            opening: false,
            generationProfile: .normalModeEarlyTension,
            memory: &memory,
            using: &generator
        )
    }

    static func openingBatch<R: RandomNumberGenerator>(count: Int, using generator: inout R) -> [HexPiece] {
        var memory = GenerationMemory()
        return makeBatch(
            count: count,
            occupiedCellCount: 0,
            opening: true,
            generationProfile: .normalModeEarlyTension,
            memory: &memory,
            using: &generator
        )
    }

    static func randomBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        using generator: inout R
    ) -> [HexPiece] {
        var memory = GenerationMemory()
        return makeBatch(
            count: count,
            occupiedCellCount: occupiedCellCount,
            opening: false,
            generationProfile: .normalModeEarlyTension,
            memory: &memory,
            using: &generator
        )
    }

    static func openingBatch<R: RandomNumberGenerator>(
        count: Int,
        memory: inout GenerationMemory,
        using generator: inout R
    ) -> [HexPiece] {
        makeBatch(
            count: count,
            occupiedCellCount: 0,
            opening: true,
            generationProfile: .normalModeEarlyTension,
            memory: &memory,
            using: &generator
        )
    }

    static func openingBatch<R: RandomNumberGenerator>(
        count: Int,
        memory: inout GenerationMemory,
        using generator: inout R,
        boardCharacter: BoardCharacter = .balanced
    ) -> [HexPiece] {
        makeBatch(
            count: count,
            occupiedCellCount: 0,
            opening: true,
            boardCharacter: boardCharacter,
            generationProfile: .standard,
            memory: &memory,
            using: &generator
        )
    }

    static func randomBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        memory: inout GenerationMemory,
        using generator: inout R
    ) -> [HexPiece] {
        makeBatch(
            count: count,
            occupiedCellCount: occupiedCellCount,
            opening: false,
            generationProfile: .normalModeEarlyTension,
            memory: &memory,
            using: &generator
        )
    }

    static func randomBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        memory: inout GenerationMemory,
        using generator: inout R,
        boardCharacter: BoardCharacter = .balanced
    ) -> [HexPiece] {
        makeBatch(
            count: count,
            occupiedCellCount: occupiedCellCount,
            opening: false,
            boardCharacter: boardCharacter,
            generationProfile: .standard,
            memory: &memory,
            using: &generator
        )
    }

    static func rescueBatch(
        count: Int,
        occupiedCellCount: Int,
        canPlace: (HexPiece) -> Bool
    ) -> [HexPiece]? {
        let playableTemplates = templates
            .sorted {
                if $0.offsets.count == $1.offsets.count {
                    return $0.tier < $1.tier
                }
                return $0.offsets.count < $1.offsets.count
            }
            .filter { canPlace(HexPiece(offsets: $0.offsets, color: palette[0])) }
        guard let guaranteed = playableTemplates.first else { return nil }
        var generator = SystemRandomNumberGenerator()
        var memory = GenerationMemory()
        var batch = makeBatch(
            count: max(0, count - 1),
            occupiedCellCount: occupiedCellCount,
            opening: false,
            memory: &memory,
            using: &generator
        )
        batch.insert(
            HexPiece(offsets: guaranteed.offsets, color: randomColor(using: &generator)),
            at: 0
        )
        return Array(batch.prefix(count))
    }

    static func rerollReplacement(
        replacing piece: HexPiece,
        occupiedCellCount: Int,
        canPlace: (HexPiece) -> Bool
    ) -> HexPiece? {
        let candidates = templates
            .filter { $0.offsets != piece.offsets }
            .sorted {
                if $0.offsets.count == $1.offsets.count {
                    return $0.tier < $1.tier
                }
                return $0.offsets.count < $1.offsets.count
            }
            .map { template in
                var generator = SystemRandomNumberGenerator()
                return HexPiece(offsets: template.offsets, color: randomColor(using: &generator))
            }
            .filter(canPlace)
        guard !candidates.isEmpty else { return nil }
        let weighted = weightedTemplates(for: occupiedCellCount, opening: false)
            .filter { weighted in
                weighted.template.offsets != piece.offsets &&
                candidates.contains { $0.offsets == weighted.template.offsets }
            }
        guard !weighted.isEmpty else { return candidates.first }
        var generator = SystemRandomNumberGenerator()
        let picked = pickTemplate(from: weighted, using: &generator)
        return HexPiece(offsets: picked.offsets, color: randomColor(using: &generator))
    }

    private static func makeBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        opening: Bool,
        boardCharacter: BoardCharacter = .balanced,
        generationProfile: GenerationProfile = .standard,
        memory: inout GenerationMemory,
        using generator: inout R
    ) -> [HexPiece] {
        let attempts = opening
            ? (generationProfile == .normalModeEarlyTension ? 5 : 4)
            : 7
        var bestProfiles: [TemplateProfile] = []
        var bestScore = Int.min
        for _ in 0..<attempts {
            let candidate = sampleBatch(
                count: count,
                occupiedCellCount: occupiedCellCount,
                opening: opening,
                boardCharacter: boardCharacter,
                generationProfile: generationProfile,
                memory: memory,
                using: &generator
            )
            let score = scoreBatch(
                candidate,
                occupiedCellCount: occupiedCellCount,
                opening: opening,
                generationProfile: generationProfile,
                memory: memory
            )
            if score > bestScore {
                bestScore = score
                bestProfiles = candidate
            }
        }
        memory.record(bestProfiles)
        return bestProfiles.map { profile in
            HexPiece(offsets: profile.template.offsets, color: randomColor(using: &generator))
        }
    }

    private struct WeightedTemplate {
        let template: Template
        let weight: Int
    }

    private static func isGapPivot(_ template: Template) -> Bool {
        template.id == "hook3"
    }

    /// Tier-0/1 spans that most readily suggest row/col clear runway (not tier-2 pressure).
    private static func isNearLineTemplate(_ template: Template) -> Bool {
        switch template.id {
        case "line2v", "line2h", "line3v":
            return true
        default:
            return false
        }
    }

    private static func nearLineSpanCount(in batch: [TemplateProfile]) -> Int {
        batch.reduce(into: 0) { count, profile in
            if isNearLineTemplate(profile.template) {
                count += 1
            }
        }
    }

    private static func earlySessionRefillWindow(
        opening: Bool,
        occupiedCellCount: Int,
        memory: GenerationMemory
    ) -> Bool {
        !opening && occupiedCellCount < 8 && memory.batchCount <= 2
    }

    private static func weightedTemplates(
        for occupiedCellCount: Int,
        opening: Bool,
        boardCharacter: BoardCharacter = .balanced,
        generationProfile: GenerationProfile = .standard
    ) -> [WeightedTemplate] {
        templates.compactMap { template in
            let profile = profile(for: template)
            let size = profile.size
            var weight = 100
            if opening {
                guard template.tier < 2 else { return nil }
                weight += template.tier == 0 ? 120 : 40
                weight += size <= 2 ? 25 : 0
                if generationProfile == .normalModeEarlyTension {
                    if isNearLineTemplate(template) {
                        weight += template.id == "line3v" ? 34 : 18
                    }
                    if profile.role == .pivot && size == 3 && !isGapPivot(template) {
                        weight += 12
                    }
                    if template.id == "single" {
                        weight -= 22
                    } else if template.tier == 0 {
                        weight -= 8
                    }
                    if size <= 2 && !isNearLineTemplate(template) {
                        weight -= 6
                    }
                }
            } else if occupiedCellCount < 8 {
                weight += template.tier == 0 ? 60 : 15
                weight += size <= 3 ? 20 : -10
                if profile.role == .pivot && size == 3 && !isGapPivot(template) {
                    weight += 14
                }
                if template.id == "single" {
                    weight -= 10
                }
                if generationProfile == .normalModeEarlyTension {
                    if isNearLineTemplate(template) {
                        weight += template.id == "line3v" ? 22 : 12
                    }
                    if profile.role == .pivot && size == 3 && !isGapPivot(template) {
                        weight += 10
                    }
                    if template.id == "single" {
                        weight -= 14
                    } else if template.tier == 0 {
                        weight -= 4
                    }
                }
            } else if occupiedCellCount < 18 {
                weight += template.tier == 1 ? 20 : 0
                weight += size == 3 ? 15 : 0
                weight += size == 4 ? 5 : 0
            } else {
                weight += size <= 2 ? 80 : 0
                weight += size == 3 ? 30 : 0
                weight += size == 4 ? -20 : 0
                weight += template.tier == 2 ? -15 : 10
            }
            if !opening {
                switch profile.role {
                case .relief:
                    weight += occupiedCellCount >= 18 ? 25 : 8
                case .pivot:
                    weight += occupiedCellCount >= 8 && occupiedCellCount < 18 ? 12 : 6
                case .pressure:
                    weight += occupiedCellCount < 8 ? -18 : (occupiedCellCount < 18 ? 6 : -8)
                }
                if isGapPivot(template) {
                    let earlyGapPivotPenalty = generationProfile == .normalModeEarlyTension ? -20 : -32
                    weight += occupiedCellCount < 8 ? earlyGapPivotPenalty : (occupiedCellCount < 18 ? 8 : 2)
                }
            }
            switch boardCharacter {
            case .open:
                switch profile.role {
                case .relief:
                    weight += opening ? 12 : (occupiedCellCount < 18 ? 14 : 8)
                case .pressure:
                    weight = max(1, weight - (opening ? 8 : (occupiedCellCount < 8 ? 10 : 4)))
                case .pivot:
                    break
                }
            case .focused:
                switch profile.role {
                case .pivot:
                    weight += opening ? 16 : (occupiedCellCount < 8 ? 16 : (occupiedCellCount < 18 ? 12 : 6))
                case .pressure:
                    weight += (!opening && occupiedCellCount >= 8 && occupiedCellCount < 18) ? 10 : 0
                case .relief:
                    break
                }
            case .balanced:
                break
            }
            return WeightedTemplate(template: template, weight: max(1, weight))
        }
    }

    private static func sampleBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        opening: Bool,
        boardCharacter: BoardCharacter = .balanced,
        generationProfile: GenerationProfile = .standard,
        memory: GenerationMemory,
        using generator: inout R
    ) -> [TemplateProfile] {
        var available = weightedTemplates(
            for: occupiedCellCount,
            opening: opening,
            boardCharacter: boardCharacter,
            generationProfile: generationProfile
        )
        var selected: [TemplateProfile] = []
        while selected.count < count && !available.isEmpty {
            let picked = pickTemplate(from: available, using: &generator)
            let selectedProfile = profile(for: picked)
            selected.append(selectedProfile)
            available.removeAll { $0.template.id == picked.id }
            available = available.map { weighted in
                let candidate = profile(for: weighted.template)
                var weight = weighted.weight
                if selected.contains(where: { $0.size == candidate.size }) {
                    weight = max(1, weight / 2)
                }
                if selected.contains(where: { $0.axis == candidate.axis }) {
                    weight = max(1, weight - 18)
                }
                if selected.contains(where: { $0.role == candidate.role }) {
                    weight = max(1, weight - 22)
                }
                if selected.contains(where: { $0.role == .relief }) && candidate.role == .relief {
                    weight = max(1, weight - (occupiedCellCount >= 18 ? 30 : 18))
                }
                if selected.contains(where: { $0.heaviness >= 5 }) && candidate.heaviness >= 5 {
                    weight = max(1, weight - 24)
                }
                if isGapPivot(candidate.template),
                   selected.contains(where: { $0.role == .pivot || $0.flexibility >= 5 }) {
                    weight = max(1, weight - 28)
                }
                if memory.recentTemplateIDs.contains(candidate.template.id) {
                    weight = max(1, weight - 35)
                }
                if isGapPivot(candidate.template) && memory.recentTemplateIDs.contains("hook3") {
                    weight = max(1, weight - 55)
                }
                if memory.recentAxes.contains(candidate.axis) {
                    weight = max(1, weight - 12)
                }
                if memory.recentRoles.contains(candidate.role) {
                    weight = max(1, weight - 14)
                }
                return WeightedTemplate(template: weighted.template, weight: weight)
            }
        }
        return selected
    }

    private static func scoreBatch(
        _ batch: [TemplateProfile],
        occupiedCellCount: Int,
        opening: Bool,
        generationProfile: GenerationProfile = .standard,
        memory: GenerationMemory
    ) -> Int {
        guard !batch.isEmpty else { return Int.min }
        var score = 0
        let axes = Set(batch.map(\.axis))
        let roles = Set(batch.map(\.role))
        let sizes = Set(batch.map(\.size))
        score += axes.count * 18
        score += roles.count * 22
        score += sizes.count * 10
        score += batch.reduce(0) { $0 + $1.flexibility * 4 }
        score -= max(0, batch.reduce(0) { $0 + $1.heaviness } - 8) * 6

        let reliefCount = batch.filter { $0.role == .relief }.count
        let pivotCount = batch.filter { $0.role == .pivot }.count
        let pressureCount = batch.filter { $0.role == .pressure }.count
        let heavyCount = batch.filter { $0.heaviness >= 5 }.count
        let flexCount = batch.filter { $0.flexibility >= 4 }.count
        let lowFootprintCount = batch.filter { $0.size <= 2 }.count
        let nearLineSpanCount = nearLineSpanCount(in: batch)
        let hasLine3Span = batch.contains { $0.template.id == "line3v" }
        let earlyMasteryWindow = opening || (occupiedCellCount < 8 && memory.batchCount <= 1)
        let earlySessionRefill = earlySessionRefillWindow(
            opening: opening,
            occupiedCellCount: occupiedCellCount,
            memory: memory
        )

        if roles.count >= 2 && axes.count >= 2 {
            score += 14
        }
        if roles.count == 1 {
            score -= opening ? 10 : 24
        }
        if flexCount >= 2 && pressureCount <= 1 {
            score += 10
        }
        if heavyCount > 1 {
            score -= occupiedCellCount >= 18 ? 24 : 14
        }

        if earlyMasteryWindow {
            if reliefCount >= 1 && pivotCount >= 1 {
                score += 18
            }
            if axes.count >= 2 {
                score += 10
            }
            if sizes.contains(2) && sizes.contains(3) {
                score += 12
            }
            if reliefCount == batch.count {
                score -= 18
            }
            if pivotCount == batch.count {
                score -= 14
            }
            if pressureCount > 0 {
                score -= opening ? 24 : 10
            }
            if heavyCount > 0 {
                score -= opening ? 16 : 8
            }
        }

        if opening {
            score += reliefCount * (generationProfile == .normalModeEarlyTension ? 18 : 22)
            score += pivotCount * 14
            score -= pressureCount * 18
            if reliefCount == 1 && pivotCount == 2 {
                score += 22
            } else if reliefCount == 2 && pivotCount == 1 {
                score += generationProfile == .normalModeEarlyTension ? 2 : 6
            }
            if sizes.contains(1) && sizes.contains(2) && sizes.contains(3) {
                score += 20
            } else if lowFootprintCount >= 1 && sizes.contains(3) {
                score += generationProfile == .normalModeEarlyTension ? 8 : 10
            }
            if generationProfile == .normalModeEarlyTension {
                score += nearLineSpanCount * 12
                if nearLineSpanCount >= 2 {
                    score += 16
                }
                if hasLine3Span {
                    score += 14
                }
                if sizes.contains(3) && (sizes.contains(2) || sizes.contains(1)) {
                    score += 20
                }
                if nearLineSpanCount == 0 && reliefCount == batch.count {
                    score -= 22
                }
                if lowFootprintCount == batch.count {
                    score -= 16
                }
            }
        } else if occupiedCellCount < 8 {
            score += reliefCount * (generationProfile == .normalModeEarlyTension ? 8 : 10)
            score += pivotCount * (generationProfile == .normalModeEarlyTension ? 16 : 14)
            score -= max(0, pressureCount - 1) * 14
            if memory.batchCount <= 1 && reliefCount == 1 && pivotCount >= 1 {
                score += 10
            }
            if generationProfile == .normalModeEarlyTension {
                score += nearLineSpanCount * 10
                if earlySessionRefill {
                    if nearLineSpanCount >= 1 && pivotCount >= 1 {
                        score += 14
                    }
                    if hasLine3Span {
                        score += 12
                    }
                    if sizes.contains(3) && sizes.contains(2) {
                        score += 14
                    }
                    if axes.count >= 2 && nearLineSpanCount >= 1 {
                        score += 10
                    }
                }
            }
        } else if occupiedCellCount < 18 {
            if reliefCount > 0 { score += 16 }
            if pivotCount > 0 { score += 20 }
            if pressureCount > 0 { score += 12 }
            if reliefCount == 0 || pivotCount == 0 { score -= 18 }
        } else {
            if reliefCount == 1 { score += 26 }
            if pivotCount > 0 { score += 14 }
            if pressureCount == 1 { score += 8 }
            if reliefCount == 0 { score -= 30 }
            if pressureCount > 1 { score -= 16 }
        }

        if !opening {
            if occupiedCellCount < 8 {
                if reliefCount > 1 { score -= generationProfile == .normalModeEarlyTension ? 18 : 14 }
                if reliefCount == 0 { score -= 6 }
            } else if occupiedCellCount < 18 {
                if reliefCount == 1 { score += 8 }
                if reliefCount > 1 { score -= 20 }
            } else {
                if reliefCount == 1 && pivotCount > 0 { score += 10 }
                if reliefCount > 1 { score -= 28 }
                if lowFootprintCount == 0 { score -= 10 }
                if lowFootprintCount > 1 { score -= 12 }
            }
        }

        let gapPivotCount = batch.filter { isGapPivot($0.template) }.count
        if opening && gapPivotCount > 0 {
            score -= 80
        } else if occupiedCellCount < 8 && gapPivotCount > 0 {
            score -= generationProfile == .normalModeEarlyTension ? 20 : 34
        } else if occupiedCellCount < 18 {
            if gapPivotCount == 1 { score += 8 }
            if gapPivotCount > 1 { score -= 36 }
        } else {
            if gapPivotCount == 1 { score += 4 }
            if gapPivotCount > 1 { score -= 32 }
        }

        for profile in batch {
            if memory.recentTemplateIDs.contains(profile.template.id) {
                score -= 24
            }
            if memory.recentSizes.contains(profile.size) {
                score -= 6
            }
            if memory.recentAxes.contains(profile.axis) {
                score -= 7
            }
            if isGapPivot(profile.template) && memory.batchCount > 0 {
                score -= 10
            }
        }

        if memory.batchCount >= 2 && sizes.count == 1 {
            score -= 18
        }
        return score
    }

    private static func profile(for template: Template) -> TemplateProfile {
        let cols = template.offsets.map(\.col)
        let rows = template.offsets.map(\.row)
        let colSpan = (cols.max() ?? 0) - (cols.min() ?? 0)
        let rowSpan = (rows.max() ?? 0) - (rows.min() ?? 0)
        let axis: Axis
        if colSpan == 0 {
            axis = .vertical
        } else if rowSpan == 0 {
            axis = .horizontal
        } else {
            axis = .mixed
        }
        let size = template.offsets.count
        let role: Role
        switch template.id {
        case "single", "line2v", "line2h":
            role = .relief
        case "line3v", "cornerA", "cornerB", "cornerC", "hook3":
            role = .pivot
        default:
            role = .pressure
        }
        let flexibility: Int
        switch template.id {
        case "hook3":
            flexibility = 5
        case "line4h":
            flexibility = 1
        default:
            switch role {
            case .relief:
                flexibility = 3
            case .pivot:
                flexibility = 4
            case .pressure:
                flexibility = 2
            }
        }
        let heaviness = size + template.tier
        return TemplateProfile(
            template: template,
            size: size,
            axis: axis,
            role: role,
            heaviness: heaviness,
            flexibility: flexibility
        )
    }

    private static func pickTemplate<R: RandomNumberGenerator>(
        from weightedTemplates: [WeightedTemplate],
        using generator: inout R
    ) -> Template {
        let totalWeight = weightedTemplates.reduce(0) { $0 + $1.weight }
        var ticket = Int.random(in: 0..<max(1, totalWeight), using: &generator)
        for weighted in weightedTemplates {
            if ticket < weighted.weight {
                return weighted.template
            }
            ticket -= weighted.weight
        }
        return weightedTemplates[0].template
    }

    private static func randomColor<R: RandomNumberGenerator>(using generator: inout R) -> UIColor {
        palette.randomElement(using: &generator) ?? palette[0]
    }
}

extension UIColor {
    convenience init(hex: String) {
        var n: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&n)
        self.init(
            red:   CGFloat((n >> 16) & 0xFF) / 255,
            green: CGFloat((n >>  8) & 0xFF) / 255,
            blue:  CGFloat( n        & 0xFF) / 255,
            alpha: 1
        )
    }

    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "000000"
        }
        return String(
            format: "%02X%02X%02X",
            Int(round(red * 255)),
            Int(round(green * 255)),
            Int(round(blue * 255))
        )
    }
}
