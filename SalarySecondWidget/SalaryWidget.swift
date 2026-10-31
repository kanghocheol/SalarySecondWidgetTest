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
    @Environment(\.widgetFamily) private var widgetFamily

    private var style: SalaryTickerStyle {
        SalaryTickerStyle(start: entry.start,
                          end: entry.end,
                          initialWon: 10_000,
                          wonPerSecond: 5)
    }

    var body: some View {
        Group {
            if widgetFamily == .accessoryInline {
                Text(.currentDate, format: style)
            } else if widgetFamily == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 1) {
                    Text("누적 수입 · +5원/초")
                        .font(.caption2)
                    Text(.currentDate, format: style)
                        .font(.headline)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(shortMode ? "퇴근 정지 실험" : "실시간 급여 실험")
                            .font(.caption.bold())
                        Spacer(minLength: 1)
                        Image(systemName: "wonsign.circle.fill")
                            .foregroundStyle(.green)
                    }
                    Text(.currentDate, format: style)
                        .font(.system(size: widgetFamily == .systemMedium ? 30 : 23,
                                      weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .monospacedDigit()
                    Text("+5원/초 · \(shortMode ? "60초 후 정지" : "15분 후 정지")")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    // System timer control makes it easier to tell if the OS clock updates.
                    Text(entry.start, style: .timer)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
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
        .configurationDisplayName(shortMode ? "급여 1분 퇴근" : "급여 15분")
        .description(shortMode ? "1초마다 5원 증가 후 1분에 정지하는지 테스트" : "1초마다 5원 증가하는지 테스트")
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
