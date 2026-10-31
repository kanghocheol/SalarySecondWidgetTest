import Foundation

/// Experimental custom format style. Compiles on Swift 6.2 Foundation.
/// WidgetKit rendering of this *custom* type is NOT verified.
struct SalaryTickerStyle: DiscreteFormatStyle {
    let start: Date
    let end: Date
    let initialWon: Double
    let wonPerSecond: Double

    func format(_ value: Date) -> String {
        let validSeconds = max(0.0, min(floor(value.timeIntervalSince(start)), floor(end.timeIntervalSince(start))))
        let won = initialWon + validSeconds * wonPerSecond
        return "₩" + won.formatted(
            .number.grouping(.automatic).precision(.fractionLength(2))
        )
    }

    func discreteInput(after input: Date) -> Date? {
        if input < start { return start }
        if input >= end { return nil }
        let nextSeconds = floor(input.timeIntervalSince(start)) + 1.0
        let next = start.addingTimeInterval(nextSeconds)
        return next <= end ? next : nil
    }

    func discreteInput(before input: Date) -> Date? {
        if input <= start { return nil }
        let effectiveSeconds = min(input.timeIntervalSince(start), end.timeIntervalSince(start))
        let currentSecond = floor(effectiveSeconds)
        if currentSecond < 1 { return nil }
        // One millisecond before the previous visible second boundary.
        return start.addingTimeInterval(currentSecond - 0.001)
    }
}
