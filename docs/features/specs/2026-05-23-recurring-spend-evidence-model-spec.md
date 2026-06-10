# Recurring Spend Evidence Model Spec

작성일: 2026-05-23  
기능 slug: `recurring-spend-evidence-model`  
기능 크기: `medium`  
상태: draft

## 왜 하는가

- 현재 반복지출 상세 시트는 `kind` 기준의 설명만 보여준다.
- 이 설명은 방향은 맞지만, 실제 detector가 어떤 근거를 썼는지 구조적으로 드러나지 않는다.
- 자동 판정 신뢰를 더 높이려면 UI가 임의 문구를 만들지 않고, detector가 만든 근거 데이터를 직접 받아야 한다.

## 문제 정의

- `RecurringSpendGroup`에는 현재 `kind`, `score`, `transactions`만 있다.
- score가 왜 그렇게 나왔는지, 어떤 규칙이 충족됐는지, 신뢰 수준이 어느 정도인지 구조화된 필드가 없다.
- 그래서 presentation에서 문자열을 임의로 조립하고 있고, detector와 UI 사이 설명 책임이 분리돼 있다.

## 목표

- detector가 `설명 가능한 근거`를 데이터로 반환한다.
- UI는 이 근거를 그대로 읽어 보여준다.
- 사용자는 `왜 반복으로 봤는지`뿐 아니라 `어느 정도 확신하는지`도 이해한다.

## 비목표

- AI 자연어 생성
- 사용자가 detector 규칙을 수정하는 기능
- 전체 판정 알고리즘 재설계

## 추가할 데이터

`RecurringSpendGroup` 또는 인접 모델에 아래 구조를 추가한다.

### 1. 신뢰 수준

예:

- `high`
- `medium`

초기 규칙:

- score 90 이상: `high`
- score 80~89: `medium`

`low`는 현재 홈/바텀시트에 노출하지 않으므로 이번 범위에서 필요 없다.

### 2. 근거 코드 리스트

UI가 임의 추측하지 않도록, detector는 문자열이 아니라 구조화된 근거 코드를 반환한다.

예:

- `monthly_cadence`
- `stable_amount`
- `subscription_keyword`
- `recent_repeat_count`
- `same_category_pattern`
- `same_account_pattern`

### 3. 근거 메타데이터

필요한 경우 수치도 함께 둔다.

예:

- 최근 45일 반복 횟수
- 금액 편차 허용 여부
- 최근/이전 월 금액

모든 수치를 처음부터 다 넣을 필요는 없지만, UI가 설명을 더 구체화할 수 있을 정도는 제공해야 한다.

## 모델 원칙

- detector는 `판정`과 `설명`을 동시에 반환한다.
- presentation은 detector 결과를 번역만 한다.
- 같은 판정이라도 근거가 다르면 다른 설명이 나와야 한다.

## kind별 최소 근거 세트

### fixed

최소 포함:

- `monthly_cadence`
- `stable_amount`

선택 포함:

- `same_account_pattern`

### subscription

최소 포함:

- `subscription_keyword`
- `stable_amount`

선택 포함:

- `recent_repeat_count`

### lifestyle

최소 포함:

- `recent_repeat_count`
- `same_category_pattern`

선택 포함:

- `stable_amount`
- `same_account_pattern`

## UI 매핑 원칙

UI는 근거 코드를 아래처럼 번역한다.

- `monthly_cadence`
  - `월간 간격이 비슷하게 이어졌어요`
- `stable_amount`
  - `비슷한 금액으로 반복됐어요`
- `subscription_keyword`
  - `구독/정기결제처럼 보이는 이름이 반복됐어요`
- `recent_repeat_count`
  - `최근 45일 안에 여러 번 반복됐어요`
- `same_category_pattern`
  - `같은 카테고리 흐름으로 이어졌어요`
- `same_account_pattern`
  - `같은 결제 수단에서 반복됐어요`

즉 문구는 presentation에 있지만, 선택 기준은 detector가 가진다.

## 신뢰 수준 노출 원칙

상세 시트에 다음 중 하나를 보여줄 수 있게 한다.

- `높은 신뢰`
- `보통 신뢰`

표현 목적:

- 사용자가 결과를 맹신하지 않게 하면서도
- detector가 어느 정도 확신하는지 가볍게 이해하게 한다.

## 범위

이번 기능에 포함:

- detector 결과 구조 확장
- evidence code와 confidence level 추가
- 기존 테스트 보강
- 상세 시트가 이 필드를 읽도록 연결할 준비

이번 기능에서 제외:

- 전체 UI 문구 재작성
- low confidence 그룹 노출
- 사용자 제어 기능

## 성공 기준

- detector 결과만 보면 `왜 그렇게 판단했는지`를 구조적으로 알 수 있다.
- presentation helper가 임의 규칙을 새로 만들지 않는다.
- 상세 시트가 score뿐 아니라 신뢰 수준도 자연스럽게 보여줄 수 있다.

## 다음 단계

- evidence model plan 작성
- detector 테스트에 evidence와 confidence 기대값 추가
- detector 구현 확장
- 상세 시트 UI를 새 필드에 맞게 수정
