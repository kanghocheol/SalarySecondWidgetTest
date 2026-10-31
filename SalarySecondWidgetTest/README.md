# 초당급여 위젯 iOS 실험 프로젝트

> 목표: **iOS 18+ 아이폰의 홈 화면 및 잠금 화면 일반 위젯**에서 사용자 정의 `DiscreteFormatStyle`로 **금액이 매초 바뀌는지** 검증합니다. Apple이 이 동작을 보장하지는 않습니다. **빌드 성공 ≠ 실제 위젯 1초 갱신 성공**.

## 실험 내용

| 위젯 | 기대 동작 | 확인 포인트 |
| --- | --- | --- |
| **급여 15분** | `₩10,000.00 → ₩10,005.00 → ₩10,010.00` (15분간 매초) | 커스텀 포맷이 위젯에서 실제로 동작하는가 |
| **급여 1분 퇴근** | 60초 후 `₩10,300.00`에서 정지 | 시간이 지나면 별도 갱신 없이 정지하는가 |
| **기본 타이머 대조군** | `00:01 → 00:02` | Apple 기본 `Text(date, style: .timer)`의 갱신 여부 |

세 가지 위젯 모두 **홈 화면 (Small/Medium)** 및 **잠금 화면 (Rectangular/Inline)** 크기를 정의했습니다. 대조군은 사용자 정의 금액 렌더링이 실패할 때 원인을 구분하기 위해 넣었습니다.

## Windows 사용자: GitHub 클라우드 Mac으로 빌드 검사

1. 이 ZIP을 풀어 나온 `SalarySecondWidgetTest` 폴더 **안의 파일 전체**를 GitHub 저장소 최상위에 올립니다. `.github/workflows/build-ios.yml`도 포함해야 합니다.
2. GitHub 저장소 → **Actions** → **Build iOS test app (unsigned)** → **Run workflow**.
3. 성공하면 해당 실행의 **Artifacts**에서 `SalarySecondTest-unsigned-ipa`를 받습니다.
4. 결과물 `UnsignedSalarySecondTest.ipa`는 **서명되지 않은 파일**입니다. 그대로는 아이폰에 설치할 수 없습니다. 또한 여기서는 Xcode 컴파일 및 위젯 확장 번들 생성만 확인한 것입니다.

## 아이폰 실제 설치 (중요)

**가장 재현성이 좋은 방법:** Apple Developer Program에 가입하고, Codemagic 같은 클라우드 Mac 빌드 서비스에서 앱·위젯 확장을 서명해서 TestFlight에 배포합니다. iOS 버전 18 이상인지 확인하세요. App Store Connect의 앱 및 위젯 Bundle ID도 설정해야 합니다.

- Apple Developer Program: https://developer.apple.com/kr/programs/
- Codemagic iOS signing: https://docs.codemagic.io/yaml-code-signing/signing-ios/
- Codemagic TestFlight: https://docs.codemagic.io/yaml-publishing/app-store-connect/

**무료 Apple 계정 + Xcode가 설치된 빌린 Mac:** Xcode에서 `project.yml`을 XcodeGen으로 프로젝트로 생성한 후 Personal Team으로 기기 테스트가 가능합니다. 단, 무료 프로비저닝은 만료되므로 주기적으로 다시 설치해야 합니다.

**Windows에서 Sideloadly 등으로 IPA 설치:** 서명되지 않은 IPA를 개인용으로 재서명하는 경로는 있으나, *위젯 확장 서명/설치가 실제로 유지되는지* 보장하지 않습니다. 일반 앱 설치 성공은 이 실험의 성공이 아닙니다. 위젯이 설치 후 목록에 나타나지 않는다면 테스트 불가입니다. Apple ID 비밀번호를 출처가 불분명한 사이트에 입력하지 마세요.

## Mac에 접근할 수 있을 때 Xcode 직접 실행

```bash
brew install xcodegen
cd SalarySecondWidgetTest
xcodegen generate
open SalarySecondTest.xcodeproj
```

Xcode → 대상 기기 선택 → Signing & Capabilities → Team 지정 → `com.example.salarysecondtest` 및 `com.example.salarysecondtest.widget`를 자기 계정의 고유 Bundle ID로 변경 → Run.

## 테스트 절차

1. 앱 설치 → 홈 화면을 길게 눌러 **위젯 추가** → `초당급여 위젯` 검색.
2. **급여 15분** 위젯 추가 → 10초 동안 연속 관찰. 돈 숫자가 매초 바뀌는지 확인.
3. **기본 타이머 대조군**도 추가 → 둘의 동작 비교.
4. **급여 1분 퇴근** 위젯을 새로 추가 → 60초 후 금액 증가가 정지하는지 확인.
5. iPhone 잠금 화면 편집 → 같은 앱의 직사각형 위젯 추가 → 10초 관찰.
6. 화면을 끈 후 다시 켜서 경과시간에 해당하는 수입으로 바뀌는지 확인.
7. AOD(상시표시)가 켜져 있다면 일반 잠금 화면과 결과를 별도로 기록.

**판정표**

| 결과 | 의미 |
| --- | --- |
| 기본 타이머 OK, 급여 위젯 OK | 해당 iOS/기기/상태에서 커스텀 매초 렌더링 **관찰 성공** |
| 기본 타이머 OK, 급여 위젯 정지/빈 칸 | WidgetKit에서 커스텀 렌더링 미지원 또는 구현 문제 가능성 |
| 둘 다 멈춤 | 화면/절전/위젯 배치/업데이트 정책 영향 가능성 |
| 위젯 자체가 없음 | 빌드, 서명 또는 위젯 확장 번들 문제 가능성 |

## 계산 로직 자체 테스트 (Linux/Windows Swift 설치 시)

```bash
swiftc Shared/SalaryTickerStyle.swift Tests/SalaryMathCheck.swift -o SalaryMathCheck
./SalaryMathCheck
```

## 제약

- **실제 아이폰 빌드/실행 검증은 하지 않았습니다.** SwiftUI/WidgetKit은 Xcode가 필요합니다.
- 초기 시간은 `getTimeline()`을 WidgetKit이 호출한 때이며, 사용자 실제 출근 시각과는 다릅니다. 그래서 어느 시각이든 15분/1분 실험을 할 수 있습니다.
- 초당 금액 증가는 `TimeDataSource`와 `DiscreteFormatStyle`에 의해 시스템이 자동으로 다시 렌더링한다는 *가설*을 검증하는 코드입니다. Apple 정책상 일반 위젯의 계속 실행·실시간 업데이트는 보장되지 않습니다.
- `WidgetCenter` 타임라인 재로딩을 1초마다 강제로 요청하지 않습니다.
- iPhone의 위치나 개인 급여 데이터는 수집하지 않습니다.
