import Combine
import Foundation
import UIKit

final class GameEngine: ObservableObject {
    enum RunMode: Equatable {
        case normal
        case daily(dayID: String, seed: UInt64)
    }

    struct LiveRunSnapshot: Codable {
        struct PieceSnapshot: Codable {
            let offsets: [HexCoordinate]
            let colorHex: String
        }

        struct RunModeSnapshot: Codable {
            let kind: String
            let dayID: String?
            let seed: UInt64?

            init(runMode: RunMode) {
                switch runMode {
                case .normal:
                    kind = "normal"
                    dayID = nil
                    seed = nil
                case let .daily(dayID, seed):
                    kind = "daily"
                    self.dayID = dayID
                    self.seed = seed
                }
            }

            var runMode: RunMode {
                guard kind == "daily", let dayID, let seed else { return .normal }
                return .daily(dayID: dayID, seed: seed)
            }
        }

        let runMode: RunModeSnapshot
        let board: HexBoard.Snapshot
        let pieces: [PieceSnapshot?]
        let score: Int
        let best: Int
        let combo: Int
        let runStartBest: Int
        let didClearAny: Bool
        let maxCombo: Int
        let hasUsedContinue: Bool
        let hasUsedReroll: Bool
        let generationMemory: PieceFactory.GenerationMemory.Snapshot
        let dailyGeneratorState: UInt64?
    }

    @Published private(set) var board: HexBoard
    @Published private(set) var pieces: [HexPiece?]
    @Published private(set) var isGameOver: Bool = false
    let scoreEngine = ScoreEngine()
    private(set) var didClearAny: Bool = false
    private(set) var maxCombo: Int = 0
    private(set) var hasUsedContinue: Bool = false
    private(set) var hasUsedReroll: Bool = false
    private(set) var runMode: RunMode = .normal
    private let cols: Int = 7
    private let rows: Int = 7
    private let slotCount: Int = 3
    private var dailyGenerator: PieceFactory.SeededGenerator?
    private var generationMemory = PieceFactory.GenerationMemory()

    init() {
        board = HexBoard(cols: 7, rows: 7)
        pieces = PieceFactory.openingBatch(count: 3).map { Optional($0) }
    }

    func canPlace(_ piece: HexPiece, at anchor: HexCoordinate) -> Bool {
        piece.offsets.allSatisfy { offset in
            let coord = HexGeometry.coordinate(for: offset, anchoredAt: anchor)
            return board.isValid(coord) && board.isEmpty(at: coord)
        }
    }

    func place(_ piece: HexPiece, at anchor: HexCoordinate, slotIndex: Int) {
        guard canPlace(piece, at: anchor) else { return }
        piece.offsets.forEach { offset in
            let coord = HexGeometry.coordinate(for: offset, anchoredAt: anchor)
            board.place(color: piece.color, at: coord)
        }
        pieces[slotIndex] = nil
        processClears()
        refillIfNeeded()
        checkGameOver()
    }

    private func processClears() {
        let rows = board.fullRows()
        let cols = board.fullCols()
        let rowCoords = board.coordinatesForRows(rows)
        let colCoords = board.coordinatesForCols(cols)
        let allCoords = Array(Set(rowCoords + colCoords))
        guard !allCoords.isEmpty else {
            scoreEngine.resetCombo()
            return
        }
        board.clearCoordinates(allCoords)
        let result = scoreEngine.registerClear(
            cells: allCoords.count,
            lines: rows.count + cols.count,
            updatesBest: !isDailyChallenge
        )
        didClearAny = true
        maxCombo = max(maxCombo, result.combo)
    }

    private func refillIfNeeded() {
        guard pieces.allSatisfy({ $0 == nil }) else { return }
        pieces = nextBatch().map(Optional.init)
    }

    private func checkGameOver() {
        let activePieces = pieces.compactMap { $0 }
        guard !activePieces.isEmpty else { return }
        let allCoords = board.allCoordinates()
        let canPlaceAny = activePieces.contains { piece in
            allCoords.contains { coord in canPlace(piece, at: coord) }
        }
        isGameOver = !canPlaceAny
    }

    func restart(normalSeed: UInt64? = nil) {
        board = HexBoard(cols: cols, rows: rows)
        generationMemory = PieceFactory.GenerationMemory()
        pieces = openingBatch(normalSeed: normalSeed).map(Optional.init)
        scoreEngine.reset()
        didClearAny = false
        maxCombo = 0
        hasUsedContinue = false
        hasUsedReroll = false
        isGameOver = false
    }

    func startNormalRun(seed: UInt64? = nil) {
        runMode = .normal
        restart(normalSeed: seed)
    }

    func startDailyRun(dayID: String, seed: UInt64) {
        runMode = .daily(dayID: dayID, seed: seed)
        restart()
    }

    var isDailyChallenge: Bool {
        if case .daily = runMode {
            return true
        }
        return false
    }

    var dailyChallengeDayID: String? {
        guard case let .daily(dayID, _) = runMode else { return nil }
        return dayID
    }

    func canResumeAfterLoss() -> Bool {
        guard !isDailyChallenge, isGameOver, !hasUsedContinue else { return false }
        return makeRescueTray() != nil
    }

    func continueAfterLoss() -> Bool {
        guard !isDailyChallenge, isGameOver, !hasUsedContinue, let tray = makeRescueTray() else { return false }
        pieces = tray.map(Optional.init)
        hasUsedContinue = true
        isGameOver = false
        return true
    }

    private func occupiedCellCount() -> Int {
        board.allCoordinates().reduce(into: 0) { count, coord in
            if board.color(at: coord) != nil {
                count += 1
            }
        }
    }

    private func openingBatch(normalSeed: UInt64? = nil) -> [HexPiece] {
        switch runMode {
        case .normal:
            dailyGenerator = nil
            if let normalSeed {
                var generator = PieceFactory.SeededGenerator(seed: normalSeed)
                return PieceFactory.openingBatch(count: slotCount, memory: &generationMemory, using: &generator)
            }
            var generator = SystemRandomNumberGenerator()
            return PieceFactory.openingBatch(count: slotCount, memory: &generationMemory, using: &generator)
        case let .daily(_, seed):
            var generator = PieceFactory.SeededGenerator(seed: seed)
            let batch = PieceFactory.openingBatch(count: slotCount, memory: &generationMemory, using: &generator)
            dailyGenerator = generator
            return batch
        }
    }

    private func nextBatch() -> [HexPiece] {
        switch runMode {
        case .normal:
            var generator = SystemRandomNumberGenerator()
            return PieceFactory.randomBatch(
                count: slotCount,
                occupiedCellCount: occupiedCellCount(),
                memory: &generationMemory,
                using: &generator
            )
        case .daily:
            var generator = dailyGenerator ?? PieceFactory.SeededGenerator(seed: 0x9E3779B97F4A7C15)
            let batch = PieceFactory.randomBatch(
                count: slotCount,
                occupiedCellCount: occupiedCellCount(),
                memory: &generationMemory,
                using: &generator
            )
            dailyGenerator = generator
            return batch
        }
    }

    private func makeRescueTray() -> [HexPiece]? {
        PieceFactory.rescueBatch(
            count: slotCount,
            occupiedCellCount: occupiedCellCount()
        ) { [self] piece in
            board.allCoordinates().contains { coord in
                canPlace(piece, at: coord)
            }
        }
    }

    func canRerollPiece(at slotIndex: Int) -> Bool {
        guard !isDailyChallenge,
              !isGameOver,
              !hasUsedReroll,
              pieces.indices.contains(slotIndex),
              let current = pieces[slotIndex] else { return false }
        return makeRerollReplacement(for: current) != nil
    }

    func rerollPiece(at slotIndex: Int) -> Bool {
        guard !isDailyChallenge,
              !isGameOver,
              !hasUsedReroll,
              pieces.indices.contains(slotIndex),
              let current = pieces[slotIndex],
              let replacement = makeRerollReplacement(for: current) else { return false }
        pieces[slotIndex] = replacement
        hasUsedReroll = true
        return true
    }

    private func makeRerollReplacement(for piece: HexPiece) -> HexPiece? {
        PieceFactory.rerollReplacement(
            replacing: piece,
            occupiedCellCount: occupiedCellCount()
        ) { [self] candidate in
            board.allCoordinates().contains { coord in
                canPlace(candidate, at: coord)
            }
        }
    }

    func loadCaptureTerminalState(
        mode: RunMode,
        emptyCoordinates: Set<HexCoordinate>,
        tray: [HexPiece],
        score: Int,
        best: Int,
        combo: Int,
        didClearAny: Bool,
        maxCombo: Int
    ) {
        runMode = mode
        dailyGenerator = nil
        generationMemory = PieceFactory.GenerationMemory()
        board = HexBoard(cols: cols, rows: rows)
        let fillPalette = [
            UIColor(hex: "7A74F7"),
            UIColor(hex: "6A8CFA"),
            UIColor(hex: "55A7F6"),
            UIColor(hex: "52C0E0")
        ]
        for coord in board.allCoordinates() where !emptyCoordinates.contains(coord) {
            let color = fillPalette[(coord.col + coord.row) % fillPalette.count]
            board.place(color: color, at: coord)
        }
        pieces = Array(tray.prefix(slotCount)).map(Optional.init)
        while pieces.count < slotCount {
            pieces.append(nil)
        }
        scoreEngine.loadCaptureSnapshot(score: score, best: best, combo: combo)
        self.didClearAny = didClearAny
        self.maxCombo = maxCombo
        hasUsedContinue = false
        hasUsedReroll = false
        checkGameOver()
    }

    func makeLiveRunSnapshot(runStartBest: Int) -> LiveRunSnapshot? {
        guard !isGameOver else { return nil }
        return LiveRunSnapshot(
            runMode: .init(runMode: runMode),
            board: board.snapshot,
            pieces: pieces.map { piece in
                piece.map {
                    LiveRunSnapshot.PieceSnapshot(
                        offsets: $0.offsets,
                        colorHex: $0.color.hexString
                    )
                }
            },
            score: scoreEngine.score,
            best: scoreEngine.best,
            combo: scoreEngine.combo,
            runStartBest: runStartBest,
            didClearAny: didClearAny,
            maxCombo: maxCombo,
            hasUsedContinue: hasUsedContinue,
            hasUsedReroll: hasUsedReroll,
            generationMemory: generationMemory.snapshot,
            dailyGeneratorState: dailyGenerator?.stateSnapshot
        )
    }

    func restoreLiveRun(from snapshot: LiveRunSnapshot) {
        runMode = snapshot.runMode.runMode
        board = HexBoard(snapshot: snapshot.board)
        pieces = Array(snapshot.pieces.prefix(slotCount)).map { piece in
            piece.map { HexPiece(offsets: $0.offsets, color: UIColor(hex: $0.colorHex)) }
        }
        while pieces.count < slotCount {
            pieces.append(nil)
        }
        scoreEngine.restore(score: snapshot.score, best: snapshot.best, combo: snapshot.combo)
        didClearAny = snapshot.didClearAny
        maxCombo = snapshot.maxCombo
        hasUsedContinue = snapshot.hasUsedContinue
        hasUsedReroll = snapshot.hasUsedReroll
        generationMemory = PieceFactory.GenerationMemory(snapshot: snapshot.generationMemory)
        switch runMode {
        case .normal:
            dailyGenerator = nil
        case let .daily(_, seed):
            if let state = snapshot.dailyGeneratorState {
                dailyGenerator = PieceFactory.SeededGenerator(stateSnapshot: state)
            } else {
                dailyGenerator = PieceFactory.SeededGenerator(seed: seed)
            }
        }
        isGameOver = false
    }
}
