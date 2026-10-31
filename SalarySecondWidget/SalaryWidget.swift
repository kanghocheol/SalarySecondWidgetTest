import SwiftUI
import WidgetKit

struct SalaryEntry: TimelineEntry {
    let date: Date
    let start: Date
    let end: Date
}

struct SalaryTimelineProvider: TimelineProvider {
    let duration: TimeInterval

    func placeholder(in context: Context) -> SalaryEntry {
        let now = Date()
        return SalaryEntry(date: now, start: now, end: now.addingTimeInterval(duration))
    }

    func getSnapshot(in context: Context, completion: @escaping (SalaryEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalaryEntry>) -> Void) {
        // Starts when the OS requests a widget timeline, so users can test at any hour.
        let now = Date()
        let entry = SalaryEntry(date: now, start: now, end: now.addingTimeInterval(duration))
        // Do not refresh at the end: observe that the amount freezes at its end value.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct SalaryTickerWidgetView: View {
    let entry: SalaryEntry
    let shortMode: Bool
    @Environment(\.widgetFamily) private var widgetFamily

    // Diagnostic A/B test: render ordinary text, not a custom DiscreteFormatStyle.
    // The only moving value in this widget is the system-supported timer.
    var body: some View {
        Group {
            if widgetFamily == .accessoryInline {
                Text("₩10,000 · 고정 금액")
            } else if widgetFamily == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 3) {
                    Text("급여 표시 테스트")
                        .font(.caption2)
                    HStack(spacing: 8) {
                        Text("₩10,000")
                            .font(.headline)
                        Text(entry.start, style: .timer)
                            .font(.caption)
                            .monospacedDigit()
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text("금액 + 타이머 표시 테스트")
                            .font(.caption.bold())
                        Spacer(minLength: 1)
                        Image(systemName: "wonsign.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text("₩10,000")
                        .font(.system(size: widgetFamily == .systemMedium ? 30 : 23,
                                      weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .monospacedDigit()
                    Text("금액 고정 · 아래 타이머만 증가")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(entry.start, style: .timer)
                        .font(.headline)
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SalaryTickerWidget: Widget {
    let kind: String
    let seconds: TimeInterval
    let shortMode: Bool

    init() {
        self.kind = "salary.custom.15m"
        self.seconds = 900
        self.shortMode = false
    }

    init(kind: String, seconds: TimeInterval, shortMode: Bool) {
        self.kind = kind
        self.seconds = seconds
        self.shortMode = shortMode
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalaryTimelineProvider(duration: seconds)) { entry in
            SalaryTickerWidgetView(entry: entry, shortMode: shortMode)
        }
        .configurationDisplayName(shortMode ? "고정금액+타이머 (1분)" : "고정금액+타이머 (15분)")
        .description("금액이 정상 표시되는지 확인하고 Apple 기본 타이머가 1초마다 변하는지 비교합니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct NativeTimerWidgetView: View {
    let entry: SalaryEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if widgetFamily == .accessoryInline {
                Text(entry.start, style: .timer)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("시스템 기본 타이머")
                        .font(.caption)
                    Text(entry.start, style: .timer)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("커스텀 금액 위젯과 비교")
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct NativeTimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "native.timer.control", provider: SalaryTimelineProvider(duration: 3600)) { entry in
            NativeTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("기본 타이머 대조군")
        .description("Apple이 직접 갱신하는 기본 타이머")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct SalaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalaryTickerWidget(kind: "salary.custom.15m", seconds: 900, shortMode: false)
        SalaryTickerWidget(kind: "salary.custom.1m", seconds: 60, shortMode: true)
        NativeTimerWidget()
    }
}
