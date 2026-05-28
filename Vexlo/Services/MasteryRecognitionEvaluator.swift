import Foundation

/// Deterministic competency recognition from run residue history (Mastery v1).
enum MasteryRecognitionEvaluator {
    static let evaluationWindow = 16
    static let minimumHistoryCount = 4
    static let recoveryEvaluationWindow = 20

    private static let anchorReadingKeys: Set<String> = [
        "clear_rhythm_held",
        "close_to_best",
        "your_best_run_yet"
    ]

    static func recognizedCompetencies(
        history: [RunResidueRecord],
        alreadyRecognized: Set<MasteryCompetency>
    ) -> Set<MasteryCompetency> {
        guard history.count >= minimumHistoryCount else { return alreadyRecognized }
        var recognized = alreadyRecognized
        let recent = Array(history.prefix(evaluationWindow))
        let recentLong = Array(history.prefix(recoveryEvaluationWindow))

        if !recognized.contains(.laneReader),
           laneReaderCount(in: recent) >= 3 {
            recognized.insert(.laneReader)
        }

        if !recognized.contains(.anchorReader),
           anchorReaderCount(in: recent) >= 4 {
            recognized.insert(.anchorReader)
        }

        if !recognized.contains(.pressureReader),
           pressureReaderCount(in: recent) >= 3 {
            recognized.insert(.pressureReader)
        }

        if !recognized.contains(.chainReader),
           chainReaderCount(in: recent) >= 3 {
            recognized.insert(.chainReader)
        }

        if !recognized.contains(.recoveryReader),
           history.count >= 6,
           recoveryReaderCount(in: recentLong) >= 2 {
            recognized.insert(.recoveryReader)
        }

        return recognized
    }

    private static func laneReaderCount(in residues: [RunResidueRecord]) -> Int {
        residues.count(where: { residue in
            residue.didClearAny
                && (residue.lessonFlag == .laneOpening
                    || residue.readingDetailKey == "board_closed_early")
        })
    }

    private static func anchorReaderCount(in residues: [RunResidueRecord]) -> Int {
        residues.count(where: { residue in
            residue.didClearAny
                && residue.lessonFlag == .anchorDiscipline
                && anchorReadingKeys.contains(residue.readingDetailKey)
        })
    }

    private static func pressureReaderCount(in residues: [RunResidueRecord]) -> Int {
        residues.count(where: { residue in
            residue.didClearAny
                && (residue.lessonFlag == .pressureRelease
                    || (residue.terminalPressureBand == "taut"
                        && residue.readingDetailKey == "read_under_pressure"))
        })
    }

    private static func chainReaderCount(in residues: [RunResidueRecord]) -> Int {
        residues.count(where: { residue in
            residue.didClearAny
                && residue.lessonFlag == .chainConversion
                && residue.maxCombo >= 2
        })
    }

    private static func recoveryReaderCount(in residues: [RunResidueRecord]) -> Int {
        residues.count(where: { residue in
            residue.didClearAny && residue.lessonFlag == .recoveryTiming
        })
    }
}
