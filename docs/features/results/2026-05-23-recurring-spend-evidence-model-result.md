# recurring-spend-evidence-model result

- 실제 변경: `RecurringSpendGroup`에 `confidence`와 `evidenceCodes`를 추가했고, detector가 반복지출 판정과 함께 설명 가능한 근거를 반환하도록 확장했다.
- 실제 변경: 고정비와 구독은 `높은 신뢰`, 생활 반복지출은 `보통 신뢰`로 구분해 상세 시트에서 그대로 노출하도록 연결했다.
- 실제 변경: 상세 시트의 `반복으로 본 이유`는 이제 `kind` 하드코딩 문구가 아니라 detector가 반환한 `evidenceCodes`를 번역해 보여준다.
- 계획과 차이: 초기 구상보다 `score` 자체를 UI에 직접 노출하지는 않았고, 사용자가 이해하기 쉬운 `신뢰 수준 + 근거 문구` 조합으로 먼저 정리했다.
- 검증: `./flutterw.bat test --no-pub test/features/dashboard/recurring_spend_detector_test.dart test/features/dashboard/dashboard_summary_provider_test.dart test/features/dashboard/dashboard_screen_test.dart`
- 다음 할 일: 반복지출 상세에서 `숨김`이나 `반복 아님` 같은 사용자 보정 액션을 붙일지 결정해야 한다.
