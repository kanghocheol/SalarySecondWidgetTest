import Foundation

@main
struct SalaryMathCheck {
    static func main() {
        let start = Date(timeIntervalSince1970: 1000000)
        let style = SalaryTickerStyle(start: start,
                                      end: start.addingTimeInterval(60),
                                      initialWon: 10_000,
                                      wonPerSecond: 5)
        precondition(style.format(start).contains("10,000"))
        precondition(style.format(start.addingTimeInterval(1)).contains("10,005"))
        precondition(style.format(start.addingTimeInterval(2)).contains("10,010"))
        precondition(style.format(start.addingTimeInterval(60)).contains("10,300"))
        precondition(style.format(start.addingTimeInterval(180)).contains("10,300"))
        precondition(style.discreteInput(after: start) == start.addingTimeInterval(1))
        precondition(style.discreteInput(after: start.addingTimeInterval(60)) == nil)
        print("PASS: 1-second money calculation and stop-at-end checks")
        print("NOTE: This does NOT confirm WidgetKit renders the custom style on iPhone.")
    }
}
