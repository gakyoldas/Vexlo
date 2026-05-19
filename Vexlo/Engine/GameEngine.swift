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
        let dailyBoardCharacterRawValue: Int?
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
    private var normalGenerator: PieceFactory.SeededGenerator?
    private var dailyGenerator: PieceFactory.SeededGenerator?
    private var dailyBoardCharacter: PieceFactory.BoardCharacter = .balanced
    private var generationMemory = PieceFactory.GenerationMemory()

    init() {
        board = HexBoard(cols: 7, rows: 7)
        pieces = PieceFactory.openingBatch(count: 3).map { Optional($0) }
    }

    func canPlace(_ piece: HexPiece, at anchor: HexCoordinate) -> Bool {
        previewPlacement(piece, at: anchor).isLegal
    }

    func previewPlacement(_ piece: HexPiece, at anchor: HexCoordinate) -> PlacementResolution {
        previewPlacementBundle(piece, at: anchor).resolution
    }

    func placementEvaluationContext() -> PlacementEvaluationContext {
        PlacementEvaluationContext(
            occupiedCellCount: occupiedCellCount(),
            isOpeningState: scoreEngine.score == 0 && !didClearAny
        )
    }

    func previewPlacementBundle(_ piece: HexPiece, at anchor: HexCoordinate) -> PlacementPreview {
        let resolution = board.placementResolution(for: piece, at: anchor)
        let evaluation = PlacementEvaluation.evaluate(
            resolution: resolution,
            context: placementEvaluationContext(),
            occupiedCoordinates: occupiedCellCoordinates()
        )
        return PlacementPreview(resolution: resolution, evaluation: evaluation)
    }

    func previewPlacementEvaluation(_ piece: HexPiece, at anchor: HexCoordinate) -> PlacementEvaluation? {
        previewPlacementBundle(piece, at: anchor).evaluation
    }

    func evaluatePlacement(_ piece: HexPiece, at anchor: HexCoordinate) -> PlacementEvaluation? {
        previewPlacementBundle(piece, at: anchor).evaluation
    }

    @discardableResult
    func place(_ piece: HexPiece, at anchor: HexCoordinate, slotIndex: Int) -> PlacementResolution {
        let resolution = previewPlacement(piece, at: anchor)
        guard resolution.isLegal else { return resolution }
        for coord in resolution.placedCoordinates {
            board.place(color: piece.color, at: coord)
        }
        pieces[slotIndex] = nil
        processClears()
        refillIfNeeded()
        checkGameOver()
        return resolution
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

    func startDailyRun(dayID: String, seed: UInt64, boardCharacter: PieceFactory.BoardCharacter = .balanced) {
        runMode = .daily(dayID: dayID, seed: seed)
        dailyBoardCharacter = boardCharacter
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

    private func occupiedCellCoordinates() -> Set<HexCoordinate> {
        Set(board.snapshot.cells.map(\.coordinate))
    }

    private func openingBatch(normalSeed: UInt64? = nil) -> [HexPiece] {
        switch runMode {
        case .normal:
            dailyGenerator = nil
            if let normalSeed {
                var generator = PieceFactory.SeededGenerator(seed: normalSeed)
                let batch = PieceFactory.openingBatch(count: slotCount, memory: &generationMemory, using: &generator)
                normalGenerator = generator
                return batch
            }
            normalGenerator = nil
            var generator = SystemRandomNumberGenerator()
            return PieceFactory.openingBatch(count: slotCount, memory: &generationMemory, using: &generator)
        case let .daily(_, seed):
            normalGenerator = nil
            var generator = PieceFactory.SeededGenerator(seed: seed)
            let batch = PieceFactory.openingBatch(count: slotCount, memory: &generationMemory, using: &generator, boardCharacter: dailyBoardCharacter)
            dailyGenerator = generator
            return batch
        }
    }

    private func nextBatch() -> [HexPiece] {
        switch runMode {
        case .normal:
            if var generator = normalGenerator {
                let batch = PieceFactory.randomBatch(
                    count: slotCount,
                    occupiedCellCount: occupiedCellCount(),
                    memory: &generationMemory,
                    using: &generator
                )
                normalGenerator = generator
                return batch
            }
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
                using: &generator,
                boardCharacter: dailyBoardCharacter
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
        normalGenerator = nil
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

    func loadCaptureComboReviewState() {
        runMode = .normal
        normalGenerator = nil
        dailyGenerator = nil
        generationMemory = PieceFactory.GenerationMemory()
        board = HexBoard(cols: cols, rows: rows)
        scoreEngine.loadCaptureSnapshot(score: 0, best: 280, combo: 0)
        didClearAny = false
        maxCombo = 0
        hasUsedContinue = false
        hasUsedReroll = false
        isGameOver = false

        let fillPalette = [
            UIColor(hex: "7A74F7"),
            UIColor(hex: "6A8CFA"),
            UIColor(hex: "55A7F6"),
            UIColor(hex: "52C0E0"),
            UIColor(hex: "63C7B0")
        ]
        let setupCells = [
            HexCoordinate(0, 1), HexCoordinate(1, 1), HexCoordinate(2, 1),
            HexCoordinate(3, 1), HexCoordinate(4, 1), HexCoordinate(5, 1),
            HexCoordinate(0, 3), HexCoordinate(1, 3), HexCoordinate(2, 3),
            HexCoordinate(3, 3), HexCoordinate(4, 3), HexCoordinate(5, 3),
            HexCoordinate(1, 5), HexCoordinate(3, 5), HexCoordinate(5, 5),
            HexCoordinate(2, 0), HexCoordinate(4, 2), HexCoordinate(6, 4)
        ]
        for (index, coord) in setupCells.enumerated() {
            board.place(color: fillPalette[index % fillPalette.count], at: coord)
        }

        let firstClearPiece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "F4B860"))
        let secondClearPiece = HexPiece(offsets: [HexCoordinate(0, 0)], color: UIColor(hex: "8EDFCB"))
        pieces = [
            firstClearPiece,
            secondClearPiece,
            HexPiece(offsets: [HexCoordinate(0, 0), HexCoordinate(1, 0), HexCoordinate(0, 1)], color: UIColor(hex: "7A74F7"))
        ].map(Optional.init)
        place(firstClearPiece, at: HexCoordinate(6, 1), slotIndex: 0)
        place(secondClearPiece, at: HexCoordinate(6, 3), slotIndex: 1)
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
            dailyGeneratorState: dailyGenerator?.stateSnapshot,
            dailyBoardCharacterRawValue: isDailyChallenge ? dailyBoardCharacter.rawValue : nil
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
            normalGenerator = nil
            dailyGenerator = nil
            dailyBoardCharacter = .balanced
        case let .daily(_, seed):
            normalGenerator = nil
            dailyBoardCharacter = snapshot.dailyBoardCharacterRawValue.flatMap { PieceFactory.BoardCharacter(rawValue: $0) } ?? .balanced
            if let state = snapshot.dailyGeneratorState {
                dailyGenerator = PieceFactory.SeededGenerator(stateSnapshot: state)
            } else {
                dailyGenerator = PieceFactory.SeededGenerator(seed: seed)
            }
        }
        isGameOver = false
    }
}
