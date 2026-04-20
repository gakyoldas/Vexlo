import Foundation
import UIKit

struct HexBoard {
    struct CellSnapshot: Codable {
        let coordinate: HexCoordinate
        let colorHex: String
    }

    struct Snapshot: Codable {
        let cols: Int
        let rows: Int
        let cells: [CellSnapshot]
    }

    let cols: Int
    let rows: Int
    private var cells: [HexCoordinate: UIColor] = [:]

    init(cols: Int, rows: Int) {
        self.cols = cols
        self.rows = rows
    }

    init(snapshot: Snapshot) {
        cols = snapshot.cols
        rows = snapshot.rows
        cells = snapshot.cells.reduce(into: [:]) { partial, cell in
            partial[cell.coordinate] = UIColor(hex: cell.colorHex)
        }
    }

    var snapshot: Snapshot {
        Snapshot(
            cols: cols,
            rows: rows,
            cells: cells
                .map { CellSnapshot(coordinate: $0.key, colorHex: $0.value.hexString) }
                .sorted {
                    ($0.coordinate.col, $0.coordinate.row) < ($1.coordinate.col, $1.coordinate.row)
                }
        )
    }

    func color(at coord: HexCoordinate) -> UIColor? {
        cells[coord]
    }

    func isEmpty(at coord: HexCoordinate) -> Bool {
        cells[coord] == nil
    }

    func isValid(_ coord: HexCoordinate) -> Bool {
        coord.col >= 0 && coord.col < cols &&
        coord.row >= 0 && coord.row < rows
    }

    mutating func place(color: UIColor, at coord: HexCoordinate) {
        guard isValid(coord) && isEmpty(at: coord) else { return }
        cells[coord] = color
    }

    mutating func clearCoordinates(_ coords: [HexCoordinate]) {
        coords.forEach { cells.removeValue(forKey: $0) }
    }

    func fullRows() -> [Int] {
        (0..<rows).filter { row in
            (0..<cols).allSatisfy { col in
                !isEmpty(at: HexCoordinate(col, row))
            }
        }
    }

    func fullCols() -> [Int] {
        (0..<cols).filter { col in
            (0..<rows).allSatisfy { row in
                !isEmpty(at: HexCoordinate(col, row))
            }
        }
    }

    func coordinatesForRows(_ rows: [Int]) -> [HexCoordinate] {
        rows.flatMap { row in
            (0..<cols).map { HexCoordinate($0, row) }
        }
    }

    func coordinatesForCols(_ cols: [Int]) -> [HexCoordinate] {
        cols.flatMap { col in
            (0..<rows).map { HexCoordinate(col, $0) }
        }
    }

    func allCoordinates() -> [HexCoordinate] {
        (0..<cols).flatMap { col in
            (0..<rows).map { HexCoordinate(col, $0) }
        }
    }
}
