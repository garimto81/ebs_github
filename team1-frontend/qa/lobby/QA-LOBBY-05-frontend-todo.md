# QA-LOBBY-05: ebs_lobby 프론트엔드 구현 TODO

| 날짜 | 항목 | 내용 |
|------|------|------|
| 2026-04-09 | 신규 작성 | BS-02 기준 React/TypeScript 프론트엔드 구현 TODO (T-01~T-20) |
| 2026-04-10 | critic revision | DEPRECATED 배너 추가 (React 19 TODO 리스트, Quasar 전환으로 폐기) |

> **⚠️ DEPRECATED — 참조용 아카이브**
> 본 문서는 **React 19 + Vite 6 TODO 리스트** 로 작성되었습니다.
> Team 1 의 기술 스택이 **Quasar Framework (Vue 3) + TypeScript** 로 확정(2026-04-10) 됨에 따라,
> 본 문서의 TODO 는 **역사적 참조용** 으로만 사용합니다. T-01 ~ T-20 의 각 항목이 다루는 "기능 수준의 부족 지점" 자체는 여전히 유효하지만, 구체적 구현 단계(React hooks, Zustand 슬라이스, react-router-dom 경로 등)는 Quasar/Pinia/Vue Router 로 재작성해야 하므로 코드 스니펫은 재사용 금지입니다.
> 신규 작업은 `QA-LOBBY-06+` 시리즈(Quasar 전환 후 신규 작성 예정)를 따릅니다.

---

## 개요

> **레포**: `C:\claude\ebs_lobby\` (React 19 + TypeScript + Vite + Zustand)
> **기준 문서**: `contracts/specs/BS-02-lobby/BS-02-lobby.md`
> **체크리스트**: `docs/qa/lobby/QA-LOBBY-02-checklist.md` (BS-02 대조 결과 구현율 ~55%)

기존 `QA-LOBBY-04`는 Flutter(Dart) 코드 기준이라 현재 React 코드베이스에 적용 불가.
이 문서는 **React/TypeScript ebs_lobby 전용** 구현 TODO다.

**범례**

| 기호 | 의미 |
|------|------|
| OPEN | 미구현 |
| IN_PROGRESS | 구현 중 |
| DONE | 완료 |

---

## CRITICAL

### [T-01] WebSocket UI 연결

| 항목 | 내용 |
|------|------|
| **우선순위** | CRITICAL |
| **BS-02 근거** | 라인 105-114 (실시간 데이터 동기화) |
| **QA 참조** | LB-07-03 |
| **Status** | OPEN |

**현황**: `src/hooks/use-websocket.ts` 훅 자체는 완성. 그러나 어떤 페이지에서도 `import` / 사용하지 않음 → 실시간 갱신 전무.

**구현 대상 파일**:
- `src/pages/TableListPage.tsx`
- `src/pages/TableDetailPage.tsx`
- `src/hooks/use-websocket.ts` (이벤트 타입 추가)

**구현 방법**:

```typescript
// TableListPage.tsx에 추가
const { lastMessage } = useWebSocket(`table:${flightId}`)
useEffect(() => {
  if (lastMessage?.type === 'table:status_changed') reload()
  if (lastMessage?.type === 'table:player_seated') reload()
}, [lastMessage])

// TableDetailPage.tsx에 추가
const { lastMessage } = useWebSocket(`table:${tableId}`)
useEffect(() => {
  if (lastMessage?.type === 'table:player_seated') reloadSeats()
  if (lastMessage?.type === 'hand:started') reloadHands()
}, [lastMessage])
```

**수락 기준**: CC에서 좌석 배정 시 Lobby TableDetailPage에서 새로고침 없이 즉시 반영.

---

### [T-02] 세션 복원 다이얼로그

| 항목 | 내용 |
|------|------|
| **우선순위** | CRITICAL |
| **BS-02 근거** | 라인 681-690 (세션 복원) |
| **QA 참조** | LB-08-07 |
| **Status** | OPEN |

**현황**: `src/pages/LoginPage.tsx:12` — 로그인 성공 시 무조건 `/series` 이동. `last_table_id` 기반 CC 직행 불가.

**구현 대상 파일**:
- `src/pages/LoginPage.tsx`
- `src/store/auth-store.ts` (SessionNavigation 타입 활용)

**구현 방법**:

```typescript
// LoginPage.tsx handleSubmit 내 수정
const result = await login(email, password)
if (result.session?.last_table_id) {
  setRestoreDialog({ tableId: result.session.last_table_id, flightId: result.session.last_flight_id })
} else {
  navigate('/series')
}

// 다이얼로그
<ConfirmDialog
  open={!!restoreDialog}
  title="Resume Previous Session?"
  message={`Return to Table #${restoreDialog?.tableId}?`}
  onConfirm={() => navigate(`/flights/${restoreDialog.flightId}/tables`)}
  onCancel={() => navigate('/series')}
/>
```

**수락 기준**: 테이블 진입 후 로그아웃 → 재로그인 시 "Continue" 버튼 클릭으로 해당 테이블 직행.

---

### [T-03] Degradation 배너 시스템

| 항목 | 내용 |
|------|------|
| **우선순위** | CRITICAL |
| **BS-02 근거** | 라인 670-679 (장애 복구 배너) |
| **QA 참조** | LB-10-01~05 |
| **Status** | OPEN |

**현황**: 완전 미구현. API 오류 / WS 끊김 시 사용자 안내 없음.

**구현 대상 파일**:
- `src/components/layout/AppLayout.tsx` (배너 삽입)
- 신규: `src/components/common/DegradationBanner.tsx`
- `src/hooks/use-api.ts` (전역 에러 상태 노출)

**구현 방법**:

```typescript
// DegradationBanner.tsx
type DegradationLevel = 'warn' | 'error' | 'readonly'
// warn(노란): WS 재연결 중
// error(빨간): API 연속 실패
// readonly(회색): DB 오류 422

// AppLayout.tsx 상단에 추가
{degradation && <DegradationBanner level={degradation.level} message={degradation.message} />}
```

**심각도별 처리**:

| 상황 | 배너 색상 | 메시지 |
|------|:--------:|--------|
| WS 연결 끊김 | 노란 | "연결 끊김 — 재연결 중..." |
| API 연속 3회 실패 | 빨간 | "서버 연결 오류 — 일부 기능 제한" |
| HTTP 422 응답 | 회색 | "읽기 전용 모드" |

**수락 기준**: 서버 미구동 상태에서 Lobby 접근 시 배너 표시. WS 재연결 성공 시 자동 해제.

---

## HIGH

### [T-04] Event 생성 폼 — Game Mode / Mix 프리셋

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | 라인 452-515 (Mix 게임 모드 UI 상세) |
| **QA 참조** | LB-02-08~09, GAP-L-008 |
| **Status** | OPEN |

**현황**: `src/pages/EventListPage.tsx` form — Game Mode 없음. `src/types/models.ts:41` `game_mode` 필드 존재하나 UI 미구현. 17종 Mix 이벤트 생성 차단.

**구현 대상 파일**: `src/pages/EventListPage.tsx`

**구현 방법**:

```typescript
// form 상태 확장
const [form, setForm] = useState({
  ...기존,
  game_mode: 'single' as 'single' | 'fixed_rotation' | 'dealers_choice',
  mix_preset: '',
  allowed_games: [] as number[],
  rotation_order: [] as number[],
  hands_per_rotation: 8,
})

// FormDialog 내 Game Mode radio
<div className="form-group">
  <label>Game Mode</label>
  <select value={form.game_mode} onChange={...}>
    <option value="single">Single</option>
    <option value="fixed_rotation">Fixed Rotation</option>
    <option value="dealers_choice">Dealer's Choice</option>
  </select>
</div>

// Fixed Rotation 선택 시 조건부 렌더링
{form.game_mode === 'fixed_rotation' && (
  <>
    <MixPresetSelect value={form.mix_preset} onChange={...} />
    <HandsPerRotationInput value={form.hands_per_rotation} onChange={...} />
  </>
)}
```

**Mix 프리셋 상수** (`src/utils/constants.ts`에 추가):

| 프리셋 | 포함 GameType ID |
|--------|:---------------:|
| HORSE | 2, 9, 13, 14, 15 |
| 8-Game | 1, 2, 3, 9, 13, 14, 15, 16 |
| PPC | 1, 3, 9, 16, 17 |

**수락 기준**: Fixed Rotation + HORSE 선택 → `allowed_games=[2,9,13,14,15]`, `rotation_order=[2,9,13,14,15]` 자동 채움.

---

### [T-05] Event 생성 폼 — Start Date / Starting Chip 추가

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | 라인 411-426 (Event 생성 폼 필드) |
| **QA 참조** | GAP-L-008 |
| **Status** | OPEN |

**현황**: form에 `start_time`, `starting_chip` 없음 → 필수 필드 누락.

**구현 대상 파일**: `src/pages/EventListPage.tsx`

**구현 방법**:

```typescript
// form 상태에 추가
start_time: '',      // date input → ISO string
starting_chip: 0,   // number input

// FormDialog에 추가
<div className="form-group">
  <label>Start Date *</label>
  <input type="datetime-local" value={form.start_time} onChange={...} required />
</div>
<div className="form-group">
  <label>Starting Chip *</label>
  <input type="number" min={1} value={form.starting_chip} onChange={...} required />
</div>
```

---

### [T-06] Blind Structure 인라인 설정

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | 라인 428-441 (BlindStructure 인라인 설정) |
| **QA 참조** | LB-02-10 |
| **Status** | OPEN |

**현황**: Event 생성 폼에 없음. `admin/BlindStructuresPage.tsx` 별도 페이지에서만 관리.

**구현 대상 파일**: `src/pages/EventListPage.tsx` (FormDialog 확장)

**구현 방법**:

```typescript
// Blind Structure 모드: 기존 선택 OR 신규 생성
type BlindMode = 'existing' | 'new'
const [blindMode, setBlindMode] = useState<BlindMode>('existing')
const [blindStructureLevels, setBlindStructureLevels] = useState([
  { level: 1, small_blind: 100, big_blind: 200, ante: 0, duration: 20 }
])

// FormDialog 내 Blind Structure 섹션
<details>
  <summary>Blind Structure *</summary>
  <div>
    <label>
      <input type="radio" value="existing" checked={blindMode==='existing'} onChange={...} />
      Use existing structure
    </label>
    <label>
      <input type="radio" value="new" checked={blindMode==='new'} onChange={...} />
      Create inline
    </label>

    {blindMode === 'existing'
      ? <BlindStructureSelect />
      : <BlindLevelTable levels={blindStructureLevels} onChange={setBlindStructureLevels} />
    }
  </div>
</details>
```

---

### [T-07] Event 상태 탭 필터

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | 라인 392-406 (Status 탭) |
| **QA 참조** | LB-02-02 |
| **Status** | OPEN |

**현황**: 전체 이벤트를 단일 테이블로 표시. 100개 이벤트 운영 시 탐색 불가.

**구현 대상 파일**: `src/pages/EventListPage.tsx`

**구현 방법**:

```typescript
const STATUS_TABS = ['all', 'created', 'announced', 'registering', 'running', 'completed']
const [activeTab, setActiveTab] = useState('all')

// useApiList 파라미터에 status 추가
const { data: events } = useApiList(eventsApi.list, {
  series_id: sid,
  status: activeTab === 'all' ? undefined : activeTab,
}, [sid, activeTab])

// 탭 UI
<div className="tab-bar">
  {STATUS_TABS.map(t => (
    <button key={t} className={activeTab===t ? 'tab active' : 'tab'} onClick={() => setActiveTab(t)}>
      {t.charAt(0).toUpperCase() + t.slice(1)}
    </button>
  ))}
</div>
```

---

### [T-08] Table 상태/타입 필터 + Summary bar

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | 라인 550-600 (테이블 관리 화면) |
| **QA 참조** | LB-04-03~04 |
| **Status** | OPEN |

**현황**: 필터 없음. Summary bar 없음.

**구현 대상 파일**: `src/pages/TableListPage.tsx`

**구현 방법**:

```typescript
// Summary bar
const summary = {
  players: tables.reduce((n, t) => n + (t.player_count ?? 0), 0),
  tables: tables.length,
  seats: tables.reduce((n, t) => n + (t.seat_count ?? 0), 0),
  seatsOccupied: tables.reduce((n, t) => n + (t.occupied_count ?? 0), 0),
}
// 헤더 아래 표시: "Players: 320 | Tables: 36 | Seats: 247 / 324"

// 필터 chip (client-side)
const filtered = tables.filter(t =>
  (typeFilter === 'all' || t.type === typeFilter) &&
  (statusFilter === 'all' || t.status === statusFilter)
)
```

---

### [T-09] Operator 할당 테이블 제한

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | BS-01 RBAC — Operator는 할당 테이블 CC 진입만 |
| **QA 참조** | LB-09-03 |
| **Status** | OPEN |

**현황**: Operator가 모든 테이블 접근 가능. 보안 요구사항 위반.

**구현 대상 파일**: `src/pages/TableListPage.tsx`, `src/api/tables.ts`

**구현 방법**:

```typescript
// TableListPage.tsx
const role = useAuthStore(s => s.user?.role)
const { data: tables } = useApiList(tablesApi.list, {
  flight_id: flightId,
  assigned_to_me: role === 'operator' ? true : undefined,
}, [flightId, role])
```

---

### [T-10] CC 모니터링 UI

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | 라인 735-746 (CC Lock 매트릭스, Active CC 드롭다운) |
| **QA 참조** | LB-06-02~04 |
| **Status** | OPEN |

**현황**: CC 상태 표시 없음. AppLayout에 CC 모니터링 UI 없음.

**구현 대상 파일**:
- `src/components/layout/AppLayout.tsx`
- `src/pages/TableListPage.tsx`

**구현 방법**:

```typescript
// AppLayout 헤더에 Active CC 드롭다운 추가
// WebSocket 'cc:status_changed' 이벤트 → 상태 배지 갱신
// TableListPage 카드 하단에 추가:
// "Operator: Kim | Hand #1247" 또는 "CC: IDLE"
```

---

### [T-11] Forgot Password 링크

| 항목 | 내용 |
|------|------|
| **우선순위** | HIGH |
| **BS-02 근거** | BS-01 §로그인 화면 목업 |
| **QA 참조** | LB-00-05 |
| **Status** | OPEN |

**현황**: 없음.

**구현 대상 파일**: `src/components/auth/LoginForm.tsx`

**구현 방법**:

```tsx
// 비밀번호 필드 아래 추가
<div style={{ textAlign: 'right', marginTop: 4 }}>
  <button type="button" className="link-btn" onClick={() => setShowForgotPassword(true)}>
    Forgot your password?
  </button>
</div>

// 모달: 이메일 입력 → POST /auth/forgot-password 호출
```

---

## MEDIUM

### [T-12] Series 월별 그룹핑

| 항목 | 내용 |
|------|------|
| **우선순위** | MEDIUM |
| **BS-02 근거** | 라인 350-359 (월별 그룹핑) |
| **QA 참조** | LB-01-02 |
| **Status** | OPEN |

**구현 대상 파일**: `src/pages/SeriesListPage.tsx`

```typescript
// begin_at 기준 월별 그룹핑
const grouped = seriesList.reduce((acc, s) => {
  const key = s.begin_at?.slice(0, 7) ?? 'Unknown' // "2026-04"
  ;(acc[key] ??= []).push(s)
  return acc
}, {} as Record<string, Series[]>)

// 렌더링
{Object.entries(grouped).map(([month, items]) => (
  <section key={month}>
    <h2 className="month-header">{formatMonth(month)} ({items.length})</h2>
    <div className="card-grid">{items.map(...)}</div>
  </section>
))}
```

---

### [T-13] Series 검색 바

| 항목 | 내용 |
|------|------|
| **우선순위** | MEDIUM |
| **BS-02 근거** | 라인 357 (검색 바) |
| **QA 참조** | LB-01-05 |
| **Status** | OPEN |

**구현 대상 파일**: `src/pages/SeriesListPage.tsx`

```typescript
const [q, setQ] = useState('')
const filtered = seriesList.filter(s =>
  s.series_name.toLowerCase().includes(q.toLowerCase())
)
// 헤더에 검색 input 추가
```

---

### [T-14] 2FA UI

| 항목 | 내용 |
|------|------|
| **우선순위** | MEDIUM |
| **BS-02 근거** | BS-01 §2FA 인증 |
| **QA 참조** | LB-00-06 |
| **Status** | OPEN |

**현황**: `src/types/models.ts:139` `totp_enabled` 필드 존재. UI 미구현.

**구현 대상 파일**: `src/components/auth/LoginForm.tsx`

```typescript
// login 응답 requires_2fa: true 시 2단계 표시
{step === '2fa' && (
  <div className="form-group">
    <label>2FA Code</label>
    <input type="text" maxLength={6} inputMode="numeric" value={totp} onChange={...} />
    <button type="button" onClick={handleVerify2fa}>Verify</button>
  </div>
)}
```

---

### [T-15] Feature Table 상태 전환 조건 검증

| 항목 | 내용 |
|------|------|
| **우선순위** | MEDIUM |
| **BS-02 근거** | 라인 704-721 (상태 전환 조건) |
| **QA 참조** | LB-04-19 |
| **Status** | OPEN |

**구현 대상 파일**: `src/pages/TableDetailPage.tsx`

```typescript
// Setup → Live 전환 클릭 시
const handleStatusTransition = (nextStatus: string) => {
  if (nextStatus === 'live' && table.type === 'feature') {
    if (!table.rfid_reader_id) {
      alert('Feature Table requires RFID reader assigned before going Live.')
      return
    }
    if (!table.deck_registered) {
      alert('Feature Table requires deck registered before going Live.')
      return
    }
  }
  tablesApi.updateStatus(tableId, nextStatus)
}
```

---

### [T-16] Player List 독립 화면

| 항목 | 내용 |
|------|------|
| **우선순위** | MEDIUM |
| **BS-02 근거** | 라인 590-601 (플레이어 목록) |
| **QA 참조** | LB-05-01 |
| **Status** | OPEN |

**현황**: 별도 PlayerListPage 없음. TableDetailPage 내 좌석 다이얼로그에서만 접근.

**구현 대상 파일**:
- 신규: `src/pages/PlayerListPage.tsx`
- `src/App.tsx` (라우트 추가: `/players`)
- `src/components/layout/Sidebar.tsx` (메뉴 추가)

---

### [T-17] 로그인 에러 메시지 분기

| 항목 | 내용 |
|------|------|
| **우선순위** | MEDIUM |
| **BS-02 근거** | BS-01 §에러 메시지 규칙 |
| **QA 참조** | LB-00-04 |
| **Status** | OPEN |

**구현 대상 파일**: `src/components/auth/LoginForm.tsx`

```typescript
} catch (err: any) {
  if (!navigator.onLine) setError('네트워크 연결을 확인하세요.')
  else if (err?.status === 401) setError('이메일 또는 비밀번호가 올바르지 않습니다.')
  else if (err?.status === 429) setError('로그인 시도 횟수 초과. 잠시 후 다시 시도하세요.')
  else if (err?.name === 'TimeoutError') setError('서버 응답 시간 초과.')
  else setError('로그인 실패. 다시 시도하세요.')
}
```

---

## LOW

### [T-18] Series 생성 폼 필드 보강

| 항목 | 내용 |
|------|------|
| **우선순위** | LOW |
| **BS-02 근거** | 라인 365-376 (Series 생성 폼) |
| **QA 참조** | GAP-L-007 |
| **Status** | OPEN |

**구현 대상 파일**: `src/pages/SeriesListPage.tsx`

추가 필드: Time Zone (select, 기본 `UTC`), Country Code (text input, 2자), Is Displayed (checkbox, 기본 true), Is Demo (checkbox, 기본 false), Series Image (URL input).

---

### [T-19] Table 생성 폼 필드 보강

| 항목 | 내용 |
|------|------|
| **우선순위** | LOW |
| **BS-02 근거** | 라인 550-580 (테이블 관리) |
| **QA 참조** | LB-04-11 |
| **Status** | OPEN |

**구현 대상 파일**: `src/pages/TableListPage.tsx`

추가 필드: Small Blind (number), Big Blind (number), Ante (number, 기본 0), Output Delay (seconds, 기본 0).

---

### [T-20] Flight 생성 폼 필드 보강

| 항목 | 내용 |
|------|------|
| **우선순위** | LOW |
| **BS-02 근거** | 라인 443-450 (Days/Flight 설정) |
| **QA 참조** | LB-03-06 |
| **Status** | OPEN |

**구현 대상 파일**: `src/pages/FlightListPage.tsx` (또는 EventListPage accordion 내 [+ New Flight])

추가 필드: Starting Stack (number, 기본 60000), Starting Blind Level (number, 기본 1), Is TBD (checkbox, 기본 false).

---

## 진행 현황 요약

| ID | 제목 | 우선순위 | 파일 | Status |
|----|------|:--------:|------|:------:|
| T-01 | WebSocket UI 연결 | CRITICAL | `src/pages/TableListPage.tsx`, `src/hooks/use-websocket.ts` | **DONE** |
| T-02 | 세션 복원 다이얼로그 | CRITICAL | `src/pages/LoginPage.tsx`, `src/store/auth-store.ts` | **DONE** |
| T-03 | Degradation 배너 시스템 | CRITICAL | `src/components/layout/AppLayout.tsx`, `src/components/common/DegradationBanner.tsx` | **DONE** |
| T-04 | Event 생성 — Game Mode / Mix 프리셋 | HIGH | `src/pages/EventListPage.tsx` | **DONE** |
| T-05 | Event 생성 — Start Date / Starting Chip | HIGH | `src/pages/EventListPage.tsx` | **DONE** |
| T-06 | Blind Structure 인라인 설정 | HIGH | `src/pages/EventListPage.tsx` | **DONE** |
| T-07 | Event 상태 탭 필터 | HIGH | `src/pages/EventListPage.tsx` | **DONE** |
| T-08 | Table 필터 + Summary bar | HIGH | `src/pages/TableListPage.tsx` | **DONE** |
| T-09 | Operator 할당 테이블 제한 | HIGH | `src/pages/TableListPage.tsx` | **DONE** |
| T-10 | CC 모니터링 UI | HIGH | `src/components/layout/AppLayout.tsx` | **DONE** |
| T-11 | Forgot Password 링크 | HIGH | `src/components/auth/LoginForm.tsx` | **DONE** |
| T-12 | Series 월별 그룹핑 | MEDIUM | `src/pages/SeriesListPage.tsx` | **DONE** |
| T-13 | Series 검색 바 | MEDIUM | `src/pages/SeriesListPage.tsx` | **DONE** |
| T-14 | 2FA UI | MEDIUM | `src/components/auth/LoginForm.tsx` | **DONE** |
| T-15 | Feature Table 전환 조건 검증 | MEDIUM | `src/pages/TableListPage.tsx` (TableExpandPanel) | **DONE** |
| T-16 | Player List 독립 화면 | MEDIUM | `src/pages/PlayerListPage.tsx` (신규) | **DONE** |
| T-17 | 로그인 에러 메시지 분기 | MEDIUM | `src/components/auth/LoginForm.tsx` | **DONE** |
| T-18 | Series 생성 폼 필드 보강 | LOW | `src/pages/SeriesListPage.tsx` | **DONE** |
| T-19 | Table 생성 폼 필드 보강 | LOW | `src/pages/TableListPage.tsx` | **DONE** |
| T-20 | Flight 생성 폼 필드 보강 | LOW | `src/pages/EventListPage.tsx` (accordion 내) | **DONE** |

**집계**: 전체 20개 **DONE** (2026-04-09)
