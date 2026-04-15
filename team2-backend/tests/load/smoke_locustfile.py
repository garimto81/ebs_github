"""Smoke load test — G-C4 (2026-04-15).

Testing_Strategy.md §9 SSOT 기반. 100 concurrent × 5min smoke.

실행:
    python -m locust -f tests/load/smoke_locustfile.py \
        --host http://localhost:8000 \
        --users 100 --spawn-rate 10 \
        --run-time 5m \
        --headless

수용 기준 (Phase 1):
    p50 < 100ms, p95 < 500ms, p99 < 1000ms, error rate < 1%
"""
from __future__ import annotations

import uuid
from random import randint

from locust import HttpUser, between, task


class LobbyUser(HttpUser):
    """Testing_Strategy.md §9.2 시나리오 5개 가중치."""

    wait_time = between(0.5, 2.0)
    host = "http://localhost:8000"

    def on_start(self) -> None:
        # 각 가상 사용자는 login 하여 JWT access_token 확보
        resp = self.client.post(
            "/api/v1/auth/login",
            json={"email": "admin@ebs.local", "password": "admin1234!"},
            name="[setup] /auth/login",
        )
        if resp.status_code == 200:
            token = resp.json().get("data", {}).get("access_token")
            if token:
                self.client.headers["Authorization"] = f"Bearer {token}"

    # ── 40% Lobby browse ──
    @task(40)
    def lobby_browse(self) -> None:
        with self.client.get("/api/v1/series", name="/series") as r:
            if r.status_code != 200:
                return
            series = r.json().get("data", [])
            if not series:
                return
            sid = series[0].get("series_id")
            if sid is None:
                return
        self.client.get(f"/api/v1/series/{sid}/events", name="/series/[id]/events")

    # ── 20% Table mutation ──
    @task(20)
    def table_mutation(self) -> None:
        idem_key = str(uuid.uuid4())
        self.client.post(
            "/api/v1/tables",
            json={"event_flight_id": 1, "table_no": randint(100, 9999), "name": "smoke", "type": "general"},
            headers={"Idempotency-Key": idem_key},
            name="/tables (POST)",
        )

    # ── 20% Player lookup ──
    @task(20)
    def player_lookup(self) -> None:
        self.client.get(
            "/api/v1/players?search=a&limit=50",
            name="/players?search",
        )

    # ── 15% WebSocket connect/hold ──
    # locust 는 기본 WebSocket 비지원 → HTTP upgrade 시뮬레이션 대신
    # /tables/{id}/events?since=0 replay 엔드포인트로 대체 (동등 부하 프록시)
    @task(15)
    def ws_replay_proxy(self) -> None:
        self.client.get(
            "/api/v1/tables/1/events?since=0&limit=100",
            name="/tables/[id]/events (ws proxy)",
        )

    # ── 5% Sync trigger (admin, rate-limited) ──
    @task(5)
    def sync_trigger(self) -> None:
        self.client.post(
            "/api/v1/sync/trigger/wsop_live",
            name="/sync/trigger/wsop_live",
        )
