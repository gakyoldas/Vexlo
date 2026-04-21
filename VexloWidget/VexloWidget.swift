import SwiftUI
import WidgetKit

private struct VexloWidgetSnapshot: Codable {
    enum RunMode: String, Codable {
        case normal
        case daily
    }

    let canResumeRun: Bool
    let runMode: RunMode?
    let score: Int?
    let dayID: String
    let hasCompletedToday: Bool
    let streakCount: Int

    static let empty = VexloWidgetSnapshot(
        canResumeRun: false,
        runMode: nil,
        score: nil,
        dayID: "",
        hasCompletedToday: false,
        streakCount: 0
    )
}

private enum VexloWidgetContract {
    static let appGroupID = "group.com.northfallstudio.Vexlo"
    static let snapshotKey = "nf_vexlo_widget_surface_snapshot"
    static let widgetKind = "com.northfallstudio.Vexlo.reentry"
}

private struct VexloWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: VexloWidgetSnapshot
}

private struct VexloWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> VexloWidgetEntry {
        VexloWidgetEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in context: Context, completion: @escaping (VexloWidgetEntry) -> Void) {
        completion(VexloWidgetEntry(date: .now, snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VexloWidgetEntry>) -> Void) {
        let entry = VexloWidgetEntry(date: .now, snapshot: loadSnapshot())
        let nextRefresh = Calendar.autoupdatingCurrent.date(byAdding: .hour, value: 6, to: .now) ?? .now.addingTimeInterval(21_600)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func loadSnapshot() -> VexloWidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: VexloWidgetContract.appGroupID),
              let data = defaults.data(forKey: VexloWidgetContract.snapshotKey),
              let snapshot = try? JSONDecoder().decode(VexloWidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }
}

private struct VexloWidgetView: View {
    let entry: VexloWidgetEntry

    private var actionURL: URL {
        URL(string: entry.snapshot.canResumeRun ? "vexlo://resume" : "vexlo://daily")!
    }

    private var actionTitle: String {
        entry.snapshot.canResumeRun ? "Resume Run" : "Today’s Challenge"
    }

    private var supportingText: String {
        if entry.snapshot.canResumeRun, let score = entry.snapshot.score {
            return "Score \(score)"
        }
        if entry.snapshot.hasCompletedToday {
            return "Completed today"
        }
        if entry.snapshot.streakCount > 0 {
            return "\(entry.snapshot.streakCount)-day streak"
        }
        return "Daily ready"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.055, green: 0.062, blue: 0.078),
                    Color(red: 0.025, green: 0.03, blue: 0.043)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("VEXLO")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.9))

                Spacer(minLength: 8)

                Text(actionTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Text(supportingText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.62, green: 0.82, blue: 0.9).opacity(0.82))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(16)
        }
        .widgetURL(actionURL)
        .containerBackground(for: .widget) {
            Color(red: 0.025, green: 0.03, blue: 0.043)
        }
    }
}

struct VexloWidget: Widget {
    let kind = VexloWidgetContract.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VexloWidgetProvider()) { entry in
            VexloWidgetView(entry: entry)
        }
        .configurationDisplayName("Vexlo")
        .description("Resume a run or start today’s challenge.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    VexloWidget()
} timeline: {
    VexloWidgetEntry(date: .now, snapshot: .empty)
}
