"""Sliding-window rate limiter for broker publish (S11 Cycle 8 #340).

Per (topic, source) 60 초 sliding window. cascade:build-fail 등 noisy 토픽의
상한선을 server 단에서 강제하여 다운스트림 (observer, Iron Law Circuit Breaker)
보호.

설계 원칙:
  - In-memory only (broker 재시작 시 자동 초기화 — race-free).
  - deque 양쪽 끝 timestamp pruning → O(1) amortized.
  - per-topic 임계값 dict 로 토픽별 차등 적용 (cascade:build-fail < 1/min 등).
  - 미정의 토픽 → 무제한 (legacy compat — drop-in 안전).

Threshold matrix (Cycle 8 default):
  cascade:build-fail : 30 events / 60s window  (publisher dedup 60s 통과한 후 추가
                       server-side 상한. KPI < 1/시간 = 1/3600s 인데 60s window 30
                       건은 burst 허용치로 안전 마진).
  기타 토픽          : 무제한 (None).
"""
from __future__ import annotations

import time
from collections import defaultdict, deque
from threading import Lock
from typing import Dict, Optional, Tuple


# 토픽별 한계: (max_events, window_sec). None 또는 미존재 시 무제한.
DEFAULT_TOPIC_LIMITS: Dict[str, Tuple[int, int]] = {
    "cascade:build-fail": (30, 60),  # 60초당 최대 30건/source
}


class RateLimiter:
    """Sliding-window rate limiter, per (topic, source) key.

    Thread-safe (broker runs single asyncio loop, but explicit Lock 으로 미래
    멀티스레드 환경에서도 안전).
    """

    def __init__(self, topic_limits: Optional[Dict[str, Tuple[int, int]]] = None):
        self._limits = topic_limits if topic_limits is not None else DEFAULT_TOPIC_LIMITS
        self._windows: Dict[Tuple[str, str], deque] = defaultdict(deque)
        self._lock = Lock()
        self._stats = {"checked": 0, "allowed": 0, "throttled": 0}

    def check(self, topic: str, source: str, now: Optional[float] = None) -> Tuple[bool, str]:
        """Returns (allowed, reason).

        allowed=False 면 reason 에 throttle 사유 명시 (forensic 용).
        """
        if topic not in self._limits:
            return True, "no_limit"
        max_events, window_sec = self._limits[topic]
        ts = now if now is not None else time.time()
        key = (topic, source)
        with self._lock:
            self._stats["checked"] += 1
            window = self._windows[key]
            # 만료 항목 pruning (왼쪽 끝부터)
            cutoff = ts - window_sec
            while window and window[0] < cutoff:
                window.popleft()
            if len(window) >= max_events:
                self._stats["throttled"] += 1
                return False, (
                    f"rate_limit topic={topic} source={source}: "
                    f"{len(window)}/{max_events} events in {window_sec}s window"
                )
            window.append(ts)
            self._stats["allowed"] += 1
            return True, "ok"

    def stats(self) -> Dict:
        with self._lock:
            return dict(self._stats)

    def set_limit(self, topic: str, max_events: int, window_sec: int) -> None:
        """Runtime override. 테스트 / config reload 용도."""
        with self._lock:
            self._limits[topic] = (max_events, window_sec)

    def clear(self) -> None:
        """테스트 시 사용 — 모든 window state 초기화."""
        with self._lock:
            self._windows.clear()
            self._stats = {"checked": 0, "allowed": 0, "throttled": 0}


# Module-level singleton — broker server 와 라이프사이클 동일.
_default_limiter: Optional[RateLimiter] = None


def get_limiter() -> RateLimiter:
    """Lazy singleton accessor."""
    global _default_limiter
    if _default_limiter is None:
        _default_limiter = RateLimiter()
    return _default_limiter
