import SwiftUI
import WidgetKit
import Foundation
import AppIntents

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


// Independent experiment: ordinary money text changed through one-second timeline entries.
// IMPORTANT: WidgetKit may skip/delay these entries. This is a diagnostic, not a guarantee.
struct SecondMoneyEntry: TimelineEntry {
    let date: Date
    let start: Date
    let won: Int
}

struct SecondMoneyProvider: TimelineProvider {
    func placeholder(in context: Context) -> SecondMoneyEntry {
        let now = Date()
        return SecondMoneyEntry(date: now, start: now, won: 10_000)
    }

    func getSnapshot(in context: Context, completion: @escaping (SecondMoneyEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SecondMoneyEntry>) -> Void) {
        let start = Date()
        let entries = (0...60).map { second in
            SecondMoneyEntry(
                date: start.addingTimeInterval(TimeInterval(second)),
                start: start,
                won: 10_000 + second * 5
            )
        }
        // After 60 seconds it stops at the final amount unless WidgetKit re-requests a timeline.
        completion(Timeline(entries: entries, policy: .never))
    }
}

struct SecondMoneyWidgetView: View {
    let entry: SecondMoneyEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        Group {
            if widgetFamily == .accessoryRectangular {
                VStack(alignment: .leading, spacing: 2) {
                    Text("1초 금액 타임라인")
                        .font(.caption2)
                    Text("₩\(entry.won.formatted())")
                        .font(.headline)
                        .monospacedDigit()
                    Text(entry.start, style: .timer)
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1초 금액 타임라인 실험")
                        .font(.caption.bold())
                    Text("₩\(entry.won.formatted())")
                        .font(.system(size: widgetFamily == .systemMedium ? 30 : 23,
                                      weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("목표: 1초마다 +5원 (60초간)")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text(entry.start, style: .timer)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SecondMoneyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "salary.second.timeline.experiment", provider: SecondMoneyProvider()) { entry in
            SecondMoneyWidgetView(entry: entry)
        }
        .configurationDisplayName("1초 금액 타임라인 실험")
        .description("60초 동안 1초마다 금액 변경을 요청합니다. iOS가 실제 갱신을 보장하지 않습니다.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}


// Separate diagnostic: use SwiftUI's clock-driven Text initializer, NOT
// a chain of 1-second WidgetKit timeline entries.
// The anchor is persisted inside this widget extension, so its reference
// time does not reset if WidgetKit requests a fresh timeline.
private enum AutoSalaryTestClock {
    static let key = "auto.salary.test.anchor.v1"

    static func persistedStart() -> Date {
        let store = UserDefaults.standard
        let saved = store.double(forKey: key)
        if saved > 1_000_000_000 {
            return Date(timeIntervalSince1970: saved)
        }
        let now = Date()
        store.set(now.timeIntervalSince1970, forKey: key)
        return now
    }
}

// Tiny, intentionally simple style: one integer number with no locale
// formatting, currency symbol or animated subviews. The currency sign is
// drawn separately so we can distinguish formatter/redaction failures.
struct AutoSalaryFormatStyle: DiscreteFormatStyle {
    let start: Date
    let end: Date

    func format(_ value: Date) -> String {
        let elapsed = max(0.0, min(floor(value.timeIntervalSince(start)),
                                   floor(end.timeIntervalSince(start))))
        let amount = 10_000 + Int(elapsed) * 5
        return String(amount)
    }

    func discreteInput(after input: Date) -> Date? {
        if input < start { return start }
        if input >= end { return nil }
        let next = start.addingTimeInterval(floor(input.timeIntervalSince(start)) + 1.0)
        return next <= end ? next : nil
    }

    func discreteInput(before input: Date) -> Date? {
        if input <= start { return nil }
        let elapsed = floor(min(input.timeIntervalSince(start),
                                end.timeIntervalSince(start)))
        if elapsed < 1 { return nil }
        return start.addingTimeInterval(elapsed - 0.001)
    }
}

struct AutoSalaryEntry: TimelineEntry {
    let date: Date
    let start: Date
    let end: Date
}

struct AutoSalaryProvider: TimelineProvider {
    private func entry(at now: Date) -> AutoSalaryEntry {
        let start = AutoSalaryTestClock.persistedStart()
        return AutoSalaryEntry(date: now, start: start,
                               end: start.addingTimeInterval(3600))
    }

    func placeholder(in context: Context) -> AutoSalaryEntry {
        let now = Date()
        return AutoSalaryEntry(date: now, start: now,
                               end: now.addingTimeInterval(3600))
    }

    func getSnapshot(in context: Context, completion: @escaping (AutoSalaryEntry) -> Void) {
        completion(entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AutoSalaryEntry>) -> Void) {
        // A single entry. Only SwiftUI's time-driven Text can animate on its own.
        // Do NOT request a reload every second.
        let now = Date()
        completion(Timeline(entries: [entry(at: now)], policy: .never))
    }
}

struct AutoSalaryWidgetView: View {
    let entry: AutoSalaryEntry
    @Environment(\.widgetFamily) private var family

    private var salaryStyle: AutoSalaryFormatStyle {
        AutoSalaryFormatStyle(start: entry.start, end: entry.end)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("자동 금액 · 화면 복귀 테스트")
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text("₩")
                // This is the ONLY experimental automatically formatted value.
                Text(.currentDate, format: salaryStyle)
                    .monospacedDigit()
            }
            .font(.system(size: family == .systemMedium ? 31 : 24,
                          weight: .bold, design: .rounded))
            .lineLimit(1)
            .minimumScaleFactor(0.5)

            HStack(spacing: 6) {
                Text("기본 타이머:")
                Text(entry.start, style: .timer)
                    .monospacedDigit()
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("시작 ₩10000 · 초당 +5원 · 최대 1시간")
                .font(.caption2)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct AutoSalaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "salary.auto.clock.test.v1", provider: AutoSalaryProvider()) { entry in
            AutoSalaryWidgetView(entry: entry)
        }
        .configurationDisplayName("자동 금액 화면 복귀 실험")
        .description("기본 타이머와 사용자 정의 자동 갱신 금액을 비교합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Experiment 4: an absolute-time salary timeline plus a genuine WidgetKit
// interaction button. Unlike the previous experiment, the start time does
// not reset when a new timeline is requested. Tapping the button triggers
// an AppIntent and (per WidgetKit) a new timeline from the current time.
// No App Group is needed for this isolated widget-only experiment.
private enum ManualSalaryTestClock {
    static let startKey = "salary.manual.test.start.v1"
    static let syncedKey = "salary.manual.test.lastSynced.v1"
    static let initialWon = 10_000
    static let wonPerSecond = 5

    static func persistedStart() -> Date {
        let store = UserDefaults.standard
        let timestamp = store.double(forKey: startKey)
        if timestamp > 1_000_000_000 {
            return Date(timeIntervalSince1970: timestamp)
        }
        let now = Date()
        store.set(now.timeIntervalSince1970, forKey: startKey)
        return now
    }

    static func amount(at moment: Date, from start: Date) -> Int {
        let elapsed = max(0, Int(floor(moment.timeIntervalSince(start))))
        return initialWon + elapsed * wonPerSecond
    }
}

struct SyncManualSalaryIntent: AppIntent {
    static var title: LocalizedStringResource = "현재 금액 동기화"
    static var description = IntentDescription("저장된 시작 시각으로 현재 급여를 다시 계산합니다.")

    func perform() async throws -> some IntentResult {
        // A widget-button intent automatically reloads its timeline on return.
        // Store a marker so the user can see that the intent actually ran.
        UserDefaults.standard.set(Date().timeIntervalSince1970,
                                  forKey: ManualSalaryTestClock.syncedKey)
        return .result()
    }
}

struct ResetManualSalaryIntent: AppIntent {
    static var title: LocalizedStringResource = "테스트 시작 시각 초기화"
    static var description = IntentDescription("급여 실험을 지금 시각부터 다시 시작합니다.")

    func perform() async throws -> some IntentResult {
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: ManualSalaryTestClock.startKey)
        UserDefaults.standard.set(now, forKey: ManualSalaryTestClock.syncedKey)
        return .result()
    }
}

struct ManualSalaryEntry: TimelineEntry {
    let date: Date
    let start: Date
    let won: Int
    let lastSynced: Date?
}

struct ManualSalaryProvider: TimelineProvider {
    func placeholder(in context: Context) -> ManualSalaryEntry {
        let now = Date()
        return ManualSalaryEntry(date: now, start: now,
                                 won: ManualSalaryTestClock.initialWon,
                                 lastSynced: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ManualSalaryEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ManualSalaryEntry>) -> Void) {
        let start = ManualSalaryTestClock.persistedStart()
        let now = Date()
        let syncEpoch = UserDefaults.standard.double(forKey: ManualSalaryTestClock.syncedKey)
        let lastSynced = syncEpoch > 1_000_000_000
            ? Date(timeIntervalSince1970: syncEpoch)
            : nil

        // 91 entries for a *short diagnostic only*, not a production strategy.
        // Every amount comes from the *absolute, persisted* start, so a new
        // timeline after a manual reload catches up rather than starting over.
        let entries = (0...90).map { offset -> ManualSalaryEntry in
            let moment = now.addingTimeInterval(TimeInterval(offset))
            return ManualSalaryEntry(
                date: moment,
                start: start,
                won: ManualSalaryTestClock.amount(at: moment, from: start),
                lastSynced: lastSynced
            )
        }
        // Allows the OS to request a new timeline, but never guarantees
        // a refresh precisely after 90 seconds or when the screen wakes.
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// Each supported family needs its own layout. Home Screen widgets use
// systemSmall/systemMedium; iPhone Lock Screen uses accessory families.
struct ManualSalaryWidgetView: View {
    let entry: ManualSalaryEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                // Single-line slot above the Lock Screen clock.
                Text("누적 급여 ₩\(entry.won.formatted())")
                    .lineLimit(1)

            case .accessoryCircular:
                // The circle is narrow: use the system's compact number style.
                VStack(spacing: 1) {
                    Image(systemName: "wonsign.circle.fill")
                        .font(.caption2)
                    Text("₩\(entry.won.formatted(.number.notation(.compactName)))")
                        .font(.caption.bold())
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .accessoryRectangular:
                // A compact Lock Screen layout: amount, elapsed timer, sync.
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("누적 급여")
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Button(intent: SyncManualSalaryIntent()) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("현재 금액 동기화")
                    }
                    Text("₩\(entry.won.formatted())")
                        .font(.headline)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                        Text(entry.start, style: .timer)
                            .monospacedDigit()
                    }
                    .font(.caption2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            default:
                // Keep the existing, working Home Screen widget unchanged.
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text("금액 복구 · 동기화 테스트")
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundStyle(.green)
                    }

                    Text("₩\(entry.won.formatted())")
                        .font(.system(size: family == .systemMedium ? 31 : 24,
                                      weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)

                    HStack(spacing: 5) {
                        Text("실제 경과:")
                        Text(entry.start, style: .timer)
                            .monospacedDigit()
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        Text("금액 기준:")
                        Text(entry.date, format: .dateTime.hour().minute().second())
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    HStack(spacing: 6) {
                        Button(intent: SyncManualSalaryIntent()) {
                            Label("현재 금액 동기화", systemImage: "arrow.clockwise")
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        .buttonStyle(.bordered)

                        if family == .systemMedium {
                            Button(intent: ResetManualSalaryIntent()) {
                                Label("처음부터", systemImage: "arrow.counterclockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .font(.caption2)

                    if family == .systemMedium, let lastSynced = entry.lastSynced {
                        Text("마지막 버튼 실행: \(lastSynced, format: .dateTime.hour().minute().second())")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct ManualSalaryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "salary.manual.sync.test.v1", provider: ManualSalaryProvider()) { entry in
            ManualSalaryWidgetView(entry: entry)
        }
        .configurationDisplayName("금액 복구·동기화 실험")
        .description("시작 시각을 고정하고 버튼으로 현재 금액이 복구되는지 확인합니다.")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

@main
struct SalaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        SalaryTickerWidget(kind: "salary.custom.15m", seconds: 900, shortMode: false)
        SalaryTickerWidget(kind: "salary.custom.1m", seconds: 60, shortMode: true)
        NativeTimerWidget()
        SecondMoneyWidget()
        ManualSalaryWidget()
    }
}
