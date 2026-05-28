import Foundation

/// Global committed-board tension band (piece-agnostic).
/// Not `PieceFactory` tray-generation pressure.
enum BoardPressureBand: Equatable {
    case calm
    case attentive
    case taut
}

/// Per empty cell intensity derived from committed board structure.
enum BoardCellWhisper: Equatable {
    case calm
    case attentive
    case taut
}

struct BoardPressureContext: Equatable {
    let occupiedCellCount: Int
    /// Withholds structural line/occupancy reads on a truly empty board (gentle canvas).
    /// Distinct from tray `opening` generation, which stays pre–first-clear via `GameEngine`.
    let freezeStructuralSemantics: Bool
    let cols: Int
    let rows: Int
}

struct BoardPressureSnapshot: Equatable {
    let band: BoardPressureBand
    /// Empty in-bounds coordinates only.
    let cellWhisper: [HexCoordinate: BoardCellWhisper]
}

enum BoardPressure {
    /// Occupied cells 0...7 — aligned with early-run generation bands.
    static let calmOccupancyUpperBound = 7
    /// Occupied cells 8...13 — mid board squeeze.
    static let attentiveOccupancyUpperBound = 13
    /// Occupied cells 14+ — aligned with `PlacementEvaluation.survivalOccupancyThreshold`.
    static let tautOccupancyLowerBound = 14

    static func evaluate(board: HexBoard, context: BoardPressureContext) -> BoardPressureSnapshot {
        if context.freezeStructuralSemantics {
            return frozenEmptyBoardSnapshot(board: board, context: context)
        }

        let band = globalBand(occupiedCellCount: context.occupiedCellCount)
        let rowFills = (0..<context.rows).map { row in
            occupiedCount(inRow: row, board: board, cols: context.cols)
        }
        let colFills = (0..<context.cols).map { col in
            occupiedCount(inCol: col, board: board, rows: context.rows)
        }

        var cellWhisper: [HexCoordinate: BoardCellWhisper] = [:]
        for col in 0..<context.cols {
            for row in 0..<context.rows {
                let coordinate = HexCoordinate(col, row)
                guard board.isEmpty(at: coordinate) else { continue }
                cellWhisper[coordinate] = resolvedCellWhisper(
                    globalBand: band,
                    rowFill: rowFills[row],
                    colFill: colFills[col],
                    cols: context.cols,
                    rows: context.rows
                )
            }
        }

        return BoardPressureSnapshot(band: band, cellWhisper: cellWhisper)
    }

    private static func frozenEmptyBoardSnapshot(board: HexBoard, context: BoardPressureContext) -> BoardPressureSnapshot {
        var cellWhisper: [HexCoordinate: BoardCellWhisper] = [:]
        for col in 0..<context.cols {
            for row in 0..<context.rows {
                let coordinate = HexCoordinate(col, row)
                guard board.isEmpty(at: coordinate) else { continue }
                cellWhisper[coordinate] = .calm
            }
        }
        return BoardPressureSnapshot(band: .calm, cellWhisper: cellWhisper)
    }

    private static func globalBand(occupiedCellCount: Int) -> BoardPressureBand {
        if occupiedCellCount <= calmOccupancyUpperBound {
            return .calm
        }
        if occupiedCellCount <= attentiveOccupancyUpperBound {
            return .attentive
        }
        return .taut
    }

    private static func resolvedCellWhisper(
        globalBand: BoardPressureBand,
        rowFill: Int,
        colFill: Int,
        cols: Int,
        rows: Int
    ) -> BoardCellWhisper {
        let baseline = BoardCellWhisper(globalBand)
        let structural = structuralWhisper(rowFill: rowFill, colFill: colFill, cols: cols, rows: rows)
        return maxWhisper(baseline, structural)
    }

    private static func structuralWhisper(
        rowFill: Int,
        colFill: Int,
        cols: Int,
        rows: Int
    ) -> BoardCellWhisper {
        let hotThresholdRow = cols - 1
        let hotThresholdCol = rows - 1
        let warmThresholdRow = cols - 2
        let warmThresholdCol = rows - 2

        if rowFill >= hotThresholdRow || colFill >= hotThresholdCol {
            return .taut
        }
        if rowFill >= warmThresholdRow || colFill >= warmThresholdCol {
            return .attentive
        }
        return .calm
    }

    private static func occupiedCount(inRow row: Int, board: HexBoard, cols: Int) -> Int {
        (0..<cols).reduce(into: 0) { count, col in
            if !board.isEmpty(at: HexCoordinate(col, row)) {
                count += 1
            }
        }
    }

    private static func occupiedCount(inCol col: Int, board: HexBoard, rows: Int) -> Int {
        (0..<rows).reduce(into: 0) { count, row in
            if !board.isEmpty(at: HexCoordinate(col, row)) {
                count += 1
            }
        }
    }

    private static func maxWhisper(_ lhs: BoardCellWhisper, _ rhs: BoardCellWhisper) -> BoardCellWhisper {
        whisperRank(lhs) >= whisperRank(rhs) ? lhs : rhs
    }

    private static func whisperRank(_ whisper: BoardCellWhisper) -> Int {
        switch whisper {
        case .calm:
            return 0
        case .attentive:
            return 1
        case .taut:
            return 2
        }
    }
}

private extension BoardCellWhisper {
    init(_ band: BoardPressureBand) {
        switch band {
        case .calm:
            self = .calm
        case .attentive:
            self = .attentive
        case .taut:
            self = .taut
        }
    }
}
