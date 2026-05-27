# 스마트 월렛 향후 발전 로드맵 (Phase 3 & 4)

본 문서는 스마트 월렛(Smart Wallet)의 기초 기능(MVP) 및 UX 개편(Phase 1, 2)이 완료됨에 따라, 어플리케이션을 상용 서비스 수준의 "개인 금융 비서"로 진화시키기 위한 중장기 로드맵을 정의합니다.

## 🎯 Phase 3: "자동화 및 인텔리전스" (Zero-Effort Logging)
사용자가 직접 수기로 가계부를 작성하는 수고를 최소화하고, 앱이 스스로 데이터를 수집하고 분류하는 데 집중합니다.

### 1. AI 기반 영수증 인식 및 파싱 (OCR + LLM)
*   **기능 요약:** 영수증을 사진으로 찍으면 상호명, 금액, 날짜, 카테고리를 자동 추출하여 입력 폼에 채워주는 기능.
*   **기술 스택:**
    *   `google_mlkit_text_recognition`: 온디바이스에서 사진 속 텍스트(Raw Text) 추출.
    *   **로직:** 추출된 Raw Text를 자체 Regex 엔진으로 분석하거나, Cloud Function (Gemini API 등)을 거쳐 JSON 형태(`{merchant, amount, date, category}`)로 구조화.
*   **연관 파일:** `features/ocr/data/ocr_service.dart` 고도화.

### 2. 안드로이드 결제 알림(Push/SMS) 파싱 봇
*   **기능 요약:** 스마트폰에 수신되는 카드사 문자나 은행 앱의 푸시 알림을 백그라운드에서 감지하여 자동으로 거래 내역 작성을 유도.
*   **기술 스택:** `notification_listener_service` (안드로이드 전용).
*   **로직:**
    *   알림을 보낸 패키지명(ex: `com.shinhancard.smartapp`) 필터링.
    *   정규식을 통해 금액과 사용처 추출 후 앱 내 푸시 혹은 즉시 DB Insert.

---

## 🎯 Phase 4: "자산 확장 및 클라우드" (Wealth & Sync)
단순 수입/지출 관리를 넘어, 개인의 총 자산을 관리하고 데이터를 안전하게 클라우드에 보관합니다.

### 3. 순자산(Net Worth) 대시보드 및 투자 자산 지원
*   **기능 요약:** 현금/예적금뿐만 아니라 주식, 암호화폐, 대출(부채) 등을 추가하여 총 자산의 우상향 그래프를 시각화.
*   **기술 스택:** `fl_chart`의 라인 차트 고도화.
*   **로직:**
    *   자산 계좌(`Accounts`)의 Type을 `Stock`, `Crypto`, `Loan` 등으로 확장.
    *   시간 흐름에 따른 순자산 변동 스냅샷 생성.

### 4. 다중 통화 (Multi-Currency) 지원
*   **기능 요약:** 해외 여행 시 달러(USD), 엔화(JPY) 등 외화로 지출을 기록해도, 실시간(또는 고정) 환율을 적용하여 메인 통계에는 원화(KRW)로 환산되어 합산되도록 지원.
*   **로직:** `Transactions` 테이블에 `currency`와 `exchangeRate` 필드 추가.

### 5. 클라우드 동기화 (Cloud Sync & Backup)
*   **기능 요약:** 수동 JSON 파일 백업에서 벗어나, Google 계정 연동을 통한 백그라운드 자동 백업 및 다중 기기 실시간 동기화.
*   **기술 스택:** `firebase_auth`, `cloud_firestore` 혹은 `googleapis` (구글 드라이브 연동).
*   **로직:** 로컬 Drift DB의 변경 사항(Conflict Resolution)을 클라우드와 양방향 동기화.

---

## 💡 구현 추천 우선순위
1.  **영수증 OCR 엔진 고도화:** 이미 UI가 준비되어 있으므로, ML Kit 연동만으로 즉각적인 WOW 이펙트 창출 가능.
2.  **안드로이드 알림 파싱:** 실사용자의 리텐션(재방문율)을 획기적으로 끌어올릴 수 있는 킬러 피처.
3.  **순자산 시각화:** 최근 적용된 Glassmorphism 기반의 대시보드 UI(`wealth_hero_backdrop`)와 가장 잘 어울리는 기능.
