// TableFSM from BS-00 §Table 상태 and BS-05-00 §Table FSM vs HandFSM 경계 (CCR-031).
//
// - EMPTY: 테이블 없음. CC 시작 불가.
// - CLOSED: 운영 종료. CC 읽기 전용.
// - SETUP: 테이블 생성 중. 좌석 편집 가능, 핸드 시작 불가.
// - LIVE: 핸드 진행 가능. HandFSM 활성.
// - PAUSED: 운영 일시 중지. HandFSM 동결. 액션 버튼 전부 비활성.

enum TableFsm {
  empty,
  closed,
  setup,
  live,
  paused,
}
