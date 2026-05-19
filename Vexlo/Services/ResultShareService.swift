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
    let dailyRitualHeadline: String?

    init(
        mode: Mode,
        score: Int,
        badge: String?,
        detail: String?,
        dailyRitualHeadline: String? = nil
    ) {
        self.mode = mode
        self.score = score
        self.badge = badge
        self.detail = detail
        self.dailyRitualHeadline = dailyRitualHeadline
    }
}

enum ResultShareService {
    static func activityItems(for payload: ResultSharePayload) -> [Any] {
        [ResultShareItemSource(payload: payload, title: summaryText(for: payload))]
    }

    private static func summaryText(for payload: ResultSharePayload) -> String {
        let mode = payload.mode == .daily ? "Today's Challenge" : "Main Run"
        let headline = payload.dailyRitualHeadline
        if let badge = payload.badge, !badge.isEmpty {
            if let headline, !headline.isEmpty {
                return "VEXLO - \(mode) - \(headline) - \(payload.score) - \(badge)"
            }
            return "VEXLO - \(mode) - \(payload.score) - \(badge)"
        }
        if let headline, !headline.isEmpty {
            return "VEXLO - \(mode) - \(headline) - \(payload.score)"
        }
        return "VEXLO - \(mode) - \(payload.score)"
    }

    fileprivate static func makeCardImage(for payload: ResultSharePayload) -> UIImage? {
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
        drawCentered(
            "VEXLO",
            y: 264,
            width: rect.width,
            font: .systemFont(ofSize: 56, weight: .bold),
            color: UIColor(hex: "F4F3FF").withAlphaComponent(0.94),
            kern: 9
        )
        let modeTitle = shareModeTitle(for: payload)
        drawCentered(
            modeTitle,
            y: 348,
            width: rect.width,
            font: .systemFont(ofSize: payload.mode == .daily ? 33 : 29, weight: .bold),
            color: UIColor(hex: payload.mode == .daily ? "DDE6FF" : "CFC8FF").withAlphaComponent(payload.mode == .daily ? 0.82 : 0.74),
            kern: payload.mode == .daily ? 4 : 3
        )
        drawCentered(
            "\(payload.score)",
            y: 620,
            width: rect.width,
            font: .monospacedDigitSystemFont(ofSize: 224, weight: .bold),
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

        let footerBaseY: CGFloat = payload.mode == .daily ? 928 : 956
        let footerPrimaryAlpha: CGFloat = payload.mode == .daily ? 0.86 : 0.8
        let footerLineSpacing: CGFloat = 58
        for (index, line) in footerLines.prefix(2).enumerated() {
            drawCentered(
                line,
                y: footerBaseY + CGFloat(index) * footerLineSpacing,
                width: rect.width,
                font: .systemFont(ofSize: index == 0 ? 36 : 30, weight: index == 0 ? .semibold : .regular),
                color: UIColor.white.withAlphaComponent(index == 0 ? footerPrimaryAlpha : 0.58),
                kern: index == 0 ? 3 : 0
            )
        }

        drawCentered(
            "Northfall Studio",
            y: 1388,
            width: rect.width,
            font: .systemFont(ofSize: 22, weight: .semibold),
            color: UIColor.white.withAlphaComponent(0.24),
            kern: 2
        )
    }

    private static func shareModeTitle(for payload: ResultSharePayload) -> String {
        if payload.mode == .daily {
            if let headline = payload.dailyRitualHeadline, !headline.isEmpty {
                return headline
            }
            return "TODAY'S CHALLENGE"
        }
        let completedRuns = GameCenterService.shared.completedRunCount
        guard completedRuns > 0 else { return "MAIN RUN" }
        return "MAIN RUN • RUN \(completedRuns)"
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
    private let payload: ResultSharePayload
    private let title: String
    private lazy var placeholderImage: UIImage = {
        let size = CGSize(width: 1200, height: 1600)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            context.cgContext.setFillColor(UIColor(hex: "080810").cgColor)
            context.cgContext.fill(CGRect(origin: .zero, size: size))
        }
    }()
    private lazy var renderedImage: UIImage = {
        ResultShareService.makeCardImage(for: payload) ?? placeholderImage
    }()

    init(payload: ResultSharePayload, title: String) {
        self.payload = payload
        self.title = title
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        placeholderImage
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        renderedImage
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
        metadata.imageProvider = NSItemProvider(object: renderedImage)
        return metadata
    }
}
