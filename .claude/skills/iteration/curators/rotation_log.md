# Curator Rotation Log

V10.0 Hot-Swap Curator 의 swap 이력. 매 phase 종료 시 자동 append.

> 형식: `swap_policy.md` §rotation_log.md 형식 참조.

---

## 초기 상태 (V10.0 도입 시점)

- **활성 curator**: curator-a (ACTIVE) / curator-b (STANDBY)
- **첫 phase 호출**: 미정 (skill 첫 호출 시 기록)
- **rotation_log entry**: 0

> 첫 swap entry 는 첫 `/iteration` cycle 의 phase 종료 시점에 자동 추가됨.
