# Recurring Spend Detection Plan

작성일: 2026-05-22  
기능 slug: `recurring-spend-detection`  
기능 크기: `medium`

- 바꿀 파일: `lib/features/dashboard/application/dashboard_summary_provider.dart`
- 새 파일: `lib/features/dashboard/application/recurring_spend_detector.dart`
- 새 파일: `test/features/dashboard/recurring_spend_detector_test.dart`
- 바꿀 파일: `test/features/dashboard/` 아래 대시보드 관련 테스트 또는 새 provider 테스트 파일
- 유지할 것: DB 스키마 변경 없이 기존 `transactions` 필드만 사용한다

- 단계 1: `RecurringSpendMatch`, `RecurringSpendGroup`, `RecurringSpendInsight` 같은 계산 모델을 새 파일로 분리한다.
- 단계 2: 거래명 정규화, 묶음 키 생성, 유형 판정, 점수 계산, 노출 여부 판정을 순수 Dart 함수로 구현한다.
- 단계 3: 고정비/구독은 엄격 판정, 반고정 생활비는 점수 판정으로 분기하는 2단계 하이브리드 로직을 구현한다.
- 단계 4: `dashboardSummaryProvider`에 반복지출 결과를 붙일 새 필드를 추가하고, 이번 달 총액/상위 3개/해석 문구를 함께 계산한다.
- 단계 5: 초기 홈 카드는 `노출 가능`으로 판정된 항목만 사용하고, 점수 미달 후보는 summary에 올리지 않는다.
- 단계 6: detector 단위 테스트에서 고정비, 구독, 반고정 생활비, 오탐 제외 케이스를 모두 검증한다.
- 단계 7: provider 테스트에서 대시보드 summary가 반복지출 총액과 상위 항목을 안정적으로 내보내는지 검증한다.

## 구현 세부 원칙

- detector는 UI와 분리된 순수 계산 모듈로 둔다.
- provider는 거래 조회와 detector 호출, summary 조립만 맡는다.
- 홈 카드 문구 생성을 detector 쪽에 넣지 말고 summary 조립 단계에서 처리한다.
- 초기 버전은 설명 가능성을 우선하므로 모델과 점수 항목을 코드에서 명시적으로 드러낸다.

## 테스트 케이스

- 같은 상호, 같은 금액, 30일 간격의 보험료가 `고정비`로 잡히는지
- 같은 상호, 같은 금액, 30일 간격의 OTT가 `구독`으로 잡히는지
- 같은 카테고리, 유사 금액, 짧은 반복 주기의 카페 지출이 `생활 반복` 후보로 잡히는지
- 우연히 두 번 발생한 유사 거래는 반복으로 잡히지 않는지
- `transfer` 거래는 항상 제외되는지
- 거래명/메모가 비어 있으면 제외되는지
- 점수 기준 미달 항목은 홈 노출 대상에서 빠지는지

## 확인 방법

- `flutter test --no-pub test/features/dashboard/recurring_spend_detector_test.dart`
- 관련 provider 테스트
- 구현 후 대시보드 summary에 반복지출 필드가 안정적으로 포함되는지 확인

## 구현 후 다음 단계

- 반복지출 홈 카드 UI spec/plan
- 반복지출 상세 바텀시트 plan
- 문구 톤과 상위 3개 정렬 기준 조정

