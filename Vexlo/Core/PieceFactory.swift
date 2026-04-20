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
        Template(id: "hook3", offsets: [HexCoordinate(0,0), HexCoordinate(1,0), HexCoordinate(1,2)], tier: 1),
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
        return makeBatch(count: count, occupiedCellCount: 0, opening: true, memory: &memory, using: &generator)
    }

    static func randomBatch(count: Int, occupiedCellCount: Int) -> [HexPiece] {
        var generator = SystemRandomNumberGenerator()
        var memory = GenerationMemory()
        return makeBatch(count: count, occupiedCellCount: occupiedCellCount, opening: false, memory: &memory, using: &generator)
    }

    static func openingBatch<R: RandomNumberGenerator>(count: Int, using generator: inout R) -> [HexPiece] {
        var memory = GenerationMemory()
        return makeBatch(count: count, occupiedCellCount: 0, opening: true, memory: &memory, using: &generator)
    }

    static func randomBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        using generator: inout R
    ) -> [HexPiece] {
        var memory = GenerationMemory()
        return makeBatch(count: count, occupiedCellCount: occupiedCellCount, opening: false, memory: &memory, using: &generator)
    }

    static func openingBatch<R: RandomNumberGenerator>(
        count: Int,
        memory: inout GenerationMemory,
        using generator: inout R
    ) -> [HexPiece] {
        makeBatch(count: count, occupiedCellCount: 0, opening: true, memory: &memory, using: &generator)
    }

    static func randomBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        memory: inout GenerationMemory,
        using generator: inout R
    ) -> [HexPiece] {
        makeBatch(count: count, occupiedCellCount: occupiedCellCount, opening: false, memory: &memory, using: &generator)
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
        memory: inout GenerationMemory,
        using generator: inout R
    ) -> [HexPiece] {
        let attempts = opening ? 4 : 7
        var bestProfiles: [TemplateProfile] = []
        var bestScore = Int.min
        for _ in 0..<attempts {
            let candidate = sampleBatch(
                count: count,
                occupiedCellCount: occupiedCellCount,
                opening: opening,
                memory: memory,
                using: &generator
            )
            let score = scoreBatch(candidate, occupiedCellCount: occupiedCellCount, opening: opening, memory: memory)
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

    private static func weightedTemplates(for occupiedCellCount: Int, opening: Bool) -> [WeightedTemplate] {
        templates.compactMap { template in
            let profile = profile(for: template)
            let size = profile.size
            var weight = 100
            if opening {
                guard template.tier < 2 else { return nil }
                weight += template.tier == 0 ? 120 : 40
                weight += size <= 2 ? 25 : 0
            } else if occupiedCellCount < 8 {
                weight += template.tier == 0 ? 60 : 15
                weight += size <= 3 ? 20 : -10
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
            }
            return WeightedTemplate(template: template, weight: max(1, weight))
        }
    }

    private static func sampleBatch<R: RandomNumberGenerator>(
        count: Int,
        occupiedCellCount: Int,
        opening: Bool,
        memory: GenerationMemory,
        using generator: inout R
    ) -> [TemplateProfile] {
        var available = weightedTemplates(for: occupiedCellCount, opening: opening)
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
                if memory.recentTemplateIDs.contains(candidate.template.id) {
                    weight = max(1, weight - 35)
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

        if opening {
            score += reliefCount * 26
            score += pivotCount * 10
            score -= pressureCount * 18
        } else if occupiedCellCount < 8 {
            score += reliefCount * 10
            score += pivotCount * 14
            score -= max(0, pressureCount - 1) * 14
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
