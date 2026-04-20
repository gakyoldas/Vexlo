import Foundation
import CoreGraphics

struct HexCoordinate: Hashable, Equatable, Codable {
    let col: Int
    let row: Int
    init(_ col: Int, _ row: Int) {
        self.col = col
        self.row = row
    }
}

enum HexGeometry {
    static let radius: CGFloat = 28
    static let width: CGFloat = radius * 2
    static let height: CGFloat = radius * sqrt(3)
    static let horizontalSpacing: CGFloat = radius * 1.5
    static let verticalSpacing: CGFloat = height
    private static let halfHeight: CGFloat = height * 0.5

    static func pixelCenter(
        for coord: HexCoordinate,
        origin: CGPoint
    ) -> CGPoint {
        let x = origin.x + CGFloat(coord.col) * horizontalSpacing
        let oddOffset = coord.col % 2 == 1 ? height * 0.5 : 0
        let y = origin.y + CGFloat(coord.row) * verticalSpacing + oddOffset
        return CGPoint(x: x, y: y)
    }

    static func nearestCoordinate(
        to point: CGPoint,
        origin: CGPoint,
        cols: Int,
        rows: Int
    ) -> HexCoordinate? {
        var best: HexCoordinate?
        var bestDist = CGFloat.infinity
        for col in 0..<cols {
            for row in 0..<rows {
                let coord = HexCoordinate(col, row)
                let center = pixelCenter(for: coord, origin: origin)
                let dist = hypot(point.x - center.x, point.y - center.y)
                if dist < bestDist {
                    bestDist = dist
                    best = coord
                }
            }
        }
        return bestDist < radius * 1.2 ? best : nil
    }

    static func localPieceCenter(for offset: HexCoordinate, radius: CGFloat) -> CGPoint {
        let hSpacing = radius * 1.5
        let vSpacing = radius * sqrt(3)
        return CGPoint(
            x: CGFloat(offset.col) * hSpacing,
            y: CGFloat(offset.row) * vSpacing + CGFloat(offset.col) * vSpacing * 0.5
        )
    }

    static func coordinate(for localOffset: HexCoordinate, anchoredAt anchor: HexCoordinate) -> HexCoordinate {
        let anchorAxial = axialCoordinate(for: anchor)
        return offsetCoordinate(
            q: anchorAxial.q + localOffset.col,
            r: anchorAxial.r + localOffset.row
        )
    }

    static func boardBounds(cols: Int, rows: Int) -> CGRect {
        var minX = CGFloat.infinity
        var maxX = -CGFloat.infinity
        var minY = CGFloat.infinity
        var maxY = -CGFloat.infinity
        for col in 0..<cols {
            for row in 0..<rows {
                let center = pixelCenter(for: HexCoordinate(col, row), origin: .zero)
                minX = min(minX, center.x - radius)
                maxX = max(maxX, center.x + radius)
                minY = min(minY, center.y - halfHeight)
                maxY = max(maxY, center.y + halfHeight)
            }
        }
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }

    private static func axialCoordinate(for offset: HexCoordinate) -> (q: Int, r: Int) {
        let q = offset.col
        let r = offset.row - (offset.col - (offset.col & 1)) / 2
        return (q, r)
    }

    private static func offsetCoordinate(q: Int, r: Int) -> HexCoordinate {
        HexCoordinate(q, r + (q - (q & 1)) / 2)
    }

    static func hexPath(radius r: CGFloat) -> CGPath {
        let path = CGMutablePath()
        for i in 0..<6 {
            let angle = CGFloat.pi / 3 * CGFloat(i) - CGFloat.pi / 6
            let x = r * cos(angle)
            let y = r * sin(angle)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}
