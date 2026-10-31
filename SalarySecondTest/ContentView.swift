import SwiftUI

/// This screen is a control: it proves the calculation works in an app,
/// NOT that WidgetKit can redraw a custom number every second.
struct ContentView: View {
    @State private var startedAt = Date()
    private let wonPerSecond = 5.0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("위젯 1초 갱신 실험")
                        .font(.title2.bold())
                    Text("앱에서는 1초 계산이 가능합니다. 위젯에서 같은 숫자가 변하는지 따로 확인하세요.")
                        .foregroundStyle(.secondary)

                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let style = SalaryTickerStyle(
                            start: startedAt,
                            end: startedAt.addingTimeInterval(3600),
                            initialWon: 10_000,
                            wonPerSecond: wonPerSecond
                        )
                        VStack(alignment: .leading, spacing: 10) {
                            Text("앱 내부: 계산 검증")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Text(style.format(context.date))
                                .font(.system(size: 33, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("초당 +5원 · 1시간 후 자동 정지")
                                .font(.footnote)
                                .foregroundStyle(.green)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
                    }

                    Button("앱 내부 계산 다시 시작") {
                        startedAt = Date()
                    }
                    .buttonStyle(.borderedProminent)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("아이폰에 위젯 3개를 추가하세요")
                            .font(.headline)
                        Text("① 급여 15분: 15분 동안 매초 +5원 시도")
                        Text("② 급여 1분: 60초 후 증가 정지 확인")
                        Text("③ 기본 타이머: Apple 시스템 타이머 대조군")
                    }
                    .font(.subheadline)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))

                    Text("홈 화면과 잠금 화면에 각각 추가하고, 숫자가 1초마다 바뀌는지 눈으로 확인하세요. 잠금 화면 위젯은 화면 공간 때문에 간소화됩니다. 화면이 꺼져 있어도 표시 수입은 현재 시각 기준으로 계산합니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle("초당급여 실험")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
