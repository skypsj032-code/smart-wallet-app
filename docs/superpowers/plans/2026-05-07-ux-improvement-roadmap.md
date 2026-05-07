# UX 개선 로드맵 — 2026-05-07

> 인기 가계부(뱅크샐러드, 토스, Money Lover, YNAB)와의 비교 분석을 바탕으로 수립한 실행 계획.
> 임팩트 대비 공수 순으로 3개 Phase로 나눔.

---

## Phase 1 — Quick Wins (레이아웃·순서 수정, 기능 추가 없음)

### P1-A: 타임라인 날짜 그룹 헤더 + 일간 소계

**파일:** `lib/features/timeline/presentation/timeline_screen.dart`

**문제:** 단순 ListView로 전체 내역을 나열. 날짜 경계가 없어 하루치 지출 파악이 어려움.

**목표:**
```
5월 7일 (수)   ─────────────  지출 -35,000 / 수입 +50,000
  ├─ 점심           식비   -12,000
  ├─ 커피           카페   -3,000
  └─ 알바           수입   +50,000
```
- 날짜별로 `SliverStickyHeader` 또는 커스텀 헤더 위젯
- 헤더에 `그날 수입 합계 / 지출 합계` 표시
- 구현: `timelineTransactionsProvider` 결과를 날짜 기준 그룹화 → `_DayHeader` + `_DayTransactionList` 위젯

---

### P1-B: 대시보드 카드 순서 재배치

**파일:** `lib/features/dashboard/presentation/dashboard_screen.dart`

**문제:** 예산 잔여(`_BudgetStatusCard`)가 스크롤 맨 아래에 위치. 내러티브 카드가 상단 2번째 자리 차지.

**현재 순서:**
```
히어로 → 내러티브 → 수입/지출 스트립 → 홈링크 → 고정지출 제안 → 오늘루프 → 최근내역 → 예산
```

**목표 순서:**
```
히어로 (잔액 + 반응 애니메이션)
→ 예산 잔여 카드 (이번 달 남은 예산, 진행 바)
→ 수입 / 지출 스트립
→ 오늘 루프 카드 (오늘 입력한 내역)
→ 다가오는 고정지출
→ 최근 내역 (최대 5건)
→ 달력 / 통계 링크 카드 (DashboardHomeLinksCard)
→ 내러티브 카드 (AI 해석 — 덜 긴급한 정보로 하단 이동)
```

---

## Phase 2 — 구조적 변경 (내비게이션 재설계)

### P2-A: 탭 구조 개편 — 통계 독립 탭

**파일:** `lib/features/root/presentation/app_shell.dart`, 라우터

**문제:** 달력·통계가 `도구` 탭 안에 숨어있어 2~3단계 진입 필요.

**목표 탭:**
```
홈(0) / 내역(1) / 통계(2) / 설정(3)
```

- `도구` 탭 제거, `통계` 탭 신설
- 통계 탭 = 현재 `/statistics` 화면 (달력 뷰 전환 버튼 포함 예정)
- 달력(`/calendar`)은 통계 탭 상단에 **기간 뷰 전환 토글** (월별 캘린더 ↔ 목록)로 통합
- 예산·계좌·고정지출·검색·OCR → 설정 탭 하단 리스트로 이동 (현재 도구 탭 아이템)
- `_locationToIndex` 매핑 업데이트

**NavigationDestination 변경:**
```dart
// Before: 홈 / 내역 / 도구 / 설정
// After:  홈 / 내역 / 통계 / 설정
NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: '통계')
```

---

### P2-B: 글로벌 퀵 입력 → BottomSheet 전환

**파일:** `lib/features/root/presentation/app_shell.dart`, `lib/features/transactions/presentation/quick_entry_screen.dart`

**문제:** 바텀바 금액 입력 후 `기록` 버튼이 `/quick-entry` 화면으로 **페이지 전환**을 발생시킴. 현재 화면 맥락이 끊김.

**목표:**
- `기록` 버튼 → `showModalBottomSheet` (DraggableScrollableSheet)
- 모달 내부에 카테고리·날짜·계좌 선택까지 포함 (현재 quick_entry_screen.dart 내용 재사용)
- 저장 완료 시 모달만 닫힘 → 이전 화면 유지
- `/quick-entry` 라우트는 OCR 리뷰 등 외부 진입 전용으로만 남김

---

## Phase 3 — 화면 고도화

### P3-A: 통계 화면 PageView 3분할

**파일:** `lib/features/statistics/presentation/statistics_screen.dart`

**문제:** 1072줄 단일 스크롤. 사용자가 카테고리 섹션을 보려면 많이 스크롤해야 함.

**목표:**
```
[기간 요약] [카테고리] [추이 차트]
  ─────────────────────────────
  PageView or TabBarView
```
- `TabBar` 3개 탭: 요약 / 카테고리 / 추이
- 요약 탭: InsightPanel + OverviewPanel (현재 상단 섹션)
- 카테고리 탭: CategoryInsightPanel (현재 중간 섹션)
- 추이 탭: ChartsPanel (현재 하단 섹션)
- SegmentedButton(all/income/expense) 필터는 탭 바 위에 유지

---

### P3-B: 카테고리별 예산 vs 실지출 막대 차트

**파일:** `lib/features/budgets/presentation/budget_screen.dart`

**문제:** 카테고리별 예산 진행이 `LinearProgressIndicator` 리스트만으로 표현됨. 직관성 부족.

**목표:**
- 예산 있는 카테고리 → 가로 막대 차트 (예산 대비 사용 비율, 뱅크샐러드 스타일)
- 초과 시 빨간색 강조 (현재 `_progressColor` 함수 있음 → 차트에도 적용)
- 카테고리 아이콘 + 레이블 + 퍼센트 한 줄로

---

## 실행 우선순위

| 순서 | 항목 | 공수 | 임팩트 |
|------|------|------|--------|
| 1 | P1-A 타임라인 날짜 그룹 | 소 | 대 |
| 2 | P1-B 대시보드 카드 순서 | 소 | 대 |
| 3 | P2-A 탭 구조 개편 | 중 | 대 |
| 4 | P2-B 퀵입력 BottomSheet | 중 | 중 |
| 5 | P3-A 통계 PageView 분리 | 중 | 중 |
| 6 | P3-B 예산 막대 차트 | 소 | 중 |

---

## 주의 사항

- `CLAUDE.md` UI 사이즈 제약(퀵패널 치수)은 P2-B 작업 후에도 유지
- 탭 구조 변경(P2-A) 후 `_locationToIndex` + GoRouter 셸 라우트 둘 다 업데이트 필수
- 모든 커밋은 `feedback_git_plumbing.md` 패턴(mktree) 사용
