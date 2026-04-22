import UIKit
import LinkPresentation

struct ResultSharePayload {
    enum Mode {
        case normal
        case daily
    }

    let mode: Mode
    let score: Int
    let badge: String?
    let detail: String?
}

enum ResultShareService {
    static func activityItems(for payload: ResultSharePayload) -> [Any] {
        if let image = makeCardImage(for: payload) {
            return [ResultShareItemSource(image: image, title: summaryText(for: payload))]
        }
        return [summaryText(for: payload)]
    }

    private static func summaryText(for payload: ResultSharePayload) -> String {
        let mode = payload.mode == .daily ? "Today's Challenge" : "Main Run"
        if let badge = payload.badge, !badge.isEmpty {
            return "VEXLO - \(mode) - \(payload.score) - \(badge)"
        }
        return "VEXLO - \(mode) - \(payload.score)"
    }

    private static func makeCardImage(for payload: ResultSharePayload) -> UIImage? {
        let size = CGSize(width: 1200, height: 1600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            let cg = context.cgContext
            drawBackground(in: cg, size: size, mode: payload.mode)
            drawText(payload, in: CGRect(origin: .zero, size: size))
        }
    }

    private static func drawBackground(in context: CGContext, size: CGSize, mode: ResultSharePayload.Mode) {
        let rect = CGRect(origin: .zero, size: size)
        context.setFillColor(UIColor(hex: "080810").cgColor)
        context.fill(rect)

        let accent = UIColor(hex: mode == .daily ? "C7D0FF" : "7A74F7")
        context.setFillColor(accent.withAlphaComponent(0.13).cgColor)
        context.fillEllipse(in: CGRect(x: -160, y: -140, width: 720, height: 720))
        context.setFillColor(UIColor(hex: "A8B4FF").withAlphaComponent(0.06).cgColor)
        context.fillEllipse(in: CGRect(x: 650, y: 980, width: 640, height: 640))

        let card = UIBezierPath(roundedRect: rect.insetBy(dx: 84, dy: 108), cornerRadius: 56)
        UIColor(hex: "101020").withAlphaComponent(0.92).setFill()
        card.fill()
        UIColor(hex: "A8B4FF").withAlphaComponent(0.16).setStroke()
        card.lineWidth = 2
        card.stroke()

        for index in 0..<3 {
            let radius: CGFloat = [18, 12, 9][index]
            let x: CGFloat = [930, 260, 805][index]
            let y: CGFloat = [270, 1180, 1260][index]
            let path = HexGeometry.hexPath(radius: radius)
            context.saveGState()
            context.translateBy(x: x, y: y)
            context.addPath(path)
            context.setFillColor(accent.withAlphaComponent(index == 0 ? 0.18 : 0.1).cgColor)
            context.fillPath()
            context.restoreGState()
        }
    }

    private static func drawText(_ payload: ResultSharePayload, in rect: CGRect) {
        let mode = payload.mode == .daily ? "TODAY'S CHALLENGE" : "MAIN RUN"
        drawCentered(
            "VEXLO",
            y: 270,
            width: rect.width,
            font: .systemFont(ofSize: 54, weight: .semibold),
            color: UIColor(hex: "F4F3FF").withAlphaComponent(0.92),
            kern: 9
        )
        drawCentered(
            mode,
            y: 356,
            width: rect.width,
            font: .systemFont(ofSize: 31, weight: .semibold),
            color: UIColor(hex: payload.mode == .daily ? "DDE6FF" : "B5A8FF").withAlphaComponent(0.74),
            kern: 4
        )
        drawCentered(
            "\(payload.score)",
            y: 635,
            width: rect.width,
            font: .monospacedDigitSystemFont(ofSize: 210, weight: .bold),
            color: UIColor(hex: "FBF9FF")
        )

        var footerLines: [String] = []
        if let badge = payload.badge, !badge.isEmpty {
            footerLines.append(badge.uppercased())
        }
        if let detail = payload.detail, !detail.isEmpty {
            footerLines.append(detail)
        }
        if footerLines.isEmpty {
            footerLines.append(payload.mode == .daily ? "Daily Complete" : "Run Complete")
        }

        for (index, line) in footerLines.prefix(2).enumerated() {
            drawCentered(
                line,
                y: 970 + CGFloat(index) * 62,
                width: rect.width,
                font: .systemFont(ofSize: index == 0 ? 35 : 30, weight: index == 0 ? .semibold : .regular),
                color: UIColor.white.withAlphaComponent(index == 0 ? 0.76 : 0.54),
                kern: index == 0 ? 3 : 0
            )
        }
    }

    private static func drawCentered(
        _ string: String,
        y: CGFloat,
        width: CGFloat,
        font: UIFont,
        color: UIColor,
        kern: CGFloat = 0
    ) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .kern: kern
        ]
        let attributed = NSAttributedString(string: string, attributes: attributes)
        let size = attributed.size()
        attributed.draw(at: CGPoint(x: (width - size.width) * 0.5, y: y))
    }
}

private final class ResultShareItemSource: NSObject, UIActivityItemSource {
    private let image: UIImage
    private let title: String

    init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        image
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        title
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        metadata.imageProvider = NSItemProvider(object: image)
        return metadata
    }
}
