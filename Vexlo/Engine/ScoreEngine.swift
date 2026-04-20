import Foundation

struct ScoreResult {
    let points: Int
    let combo: Int
    let clearedCells: Int
    let clearedLines: Int
}

final class ScoreEngine {
    private(set) var score: Int = 0
    private(set) var best: Int = 0
    private(set) var combo: Int = 0
    private let pointsPerCell: Int = 10
    private let comboBonus: Int = 2
    private let defaults = UserDefaults.standard
    private let bestKey = "nf_vexlo_best"

    init() {
        best = defaults.integer(forKey: bestKey)
    }

    @discardableResult
    func registerClear(cells: Int, lines: Int, updatesBest: Bool = true) -> ScoreResult {
        combo += 1
        let multiplier = 1 + (combo - 1) * comboBonus
        let points = cells * pointsPerCell * multiplier
        score += points
        if updatesBest, score > best {
            best = score
            defaults.set(best, forKey: bestKey)
        }
        return ScoreResult(
            points: points,
            combo: combo,
            clearedCells: cells,
            clearedLines: lines
        )
    }

    func resetCombo() {
        combo = 0
    }

    func reset() {
        score = 0
        combo = 0
    }

    func loadCaptureSnapshot(score: Int, best: Int, combo: Int) {
        self.score = score
        self.best = best
        self.combo = combo
    }

    func restore(score: Int, best: Int, combo: Int) {
        self.score = score
        self.best = best
        self.combo = combo
    }
}
