"""Circuit Breaker — CLOSED -> OPEN -> HALF_OPEN FSM."""
import time
from collections import deque
from typing import Any, Callable

from src.app.config import settings


class CircuitOpenError(Exception):
    """Raised when circuit is OPEN and call is rejected."""

    def __init__(self, remaining_s: float = 0):
        self.remaining_s = remaining_s
        super().__init__(f"Circuit OPEN, retry after {remaining_s:.1f}s")


class CircuitBreaker:
    """Sliding-window circuit breaker.

    CLOSED: all calls pass through, failures tracked.
    OPEN: all calls rejected for open_duration_s.
    HALF_OPEN: one trial call allowed; success -> CLOSED, failure -> OPEN.
    """

    def __init__(
        self,
        failure_ratio: float | None = None,
        window_size: int | None = None,
        open_duration_s: int | None = None,
    ):
        self.failure_ratio = failure_ratio if failure_ratio is not None else settings.cb_failure_ratio
        self.window_size = window_size if window_size is not None else settings.cb_window_size
        self.open_duration_s = open_duration_s if open_duration_s is not None else settings.cb_open_duration_s

        self.state: str = "CLOSED"
        self._window: deque[bool] = deque(maxlen=self.window_size)  # True=success, False=failure
        self._opened_at: float = 0.0

    def _failure_rate(self) -> float:
        if not self._window:
            return 0.0
        failures = sum(1 for ok in self._window if not ok)
        return failures / len(self._window)

    def _check_open_timeout(self) -> None:
        """Transition OPEN -> HALF_OPEN if timeout elapsed."""
        if self.state == "OPEN" and (time.monotonic() - self._opened_at) >= self.open_duration_s:
            self.state = "HALF_OPEN"

    def _record_success(self) -> None:
        self._window.append(True)

    def _record_failure(self) -> None:
        self._window.append(False)

    async def call(self, fn: Callable, *args: Any, **kwargs: Any) -> Any:
        """Execute fn through circuit breaker."""
        self._check_open_timeout()

        if self.state == "OPEN":
            remaining = self.open_duration_s - (time.monotonic() - self._opened_at)
            raise CircuitOpenError(max(0, remaining))

        try:
            result = await fn(*args, **kwargs)
            self._record_success()
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self._window.clear()
            return result
        except CircuitOpenError:
            raise
        except Exception:
            self._record_failure()
            if self.state == "HALF_OPEN":
                self.state = "OPEN"
                self._opened_at = time.monotonic()
            elif self._failure_rate() >= self.failure_ratio:
                self.state = "OPEN"
                self._opened_at = time.monotonic()
            raise
