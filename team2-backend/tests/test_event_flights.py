"""Tests for event_flights levels endpoint — Phase 3.B (2026-05-06).

Endpoint: GET /api/v1/flights/{flight_id}/levels
Source: src/routers/event_flights.py
"""
from __future__ import annotations

from sqlalchemy import text
from fastapi.testclient import TestClient


def _admin_token(client: TestClient) -> str:
    r = client.post(
        "/api/v1/auth/login",
        json={"email": "admin@ebs.local", "password": "admin123"},
    )
    assert r.status_code == 200, r.text
    return r.json()["data"]["accessToken"]


def test_flight_levels_404_when_flight_missing(client: TestClient):
    token = _admin_token(client)
    r = client.get(
        "/api/v1/flights/999999/levels",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert r.status_code == 404


def test_flight_levels_requires_auth(client: TestClient):
    r = client.get("/api/v1/flights/1/levels")
    assert r.status_code in (401, 403)


def test_flight_levels_endpoint_registered(client: TestClient):
    """endpoint 자체가 router 에 등록되어 있는지 — OpenAPI spec 으로 검증."""
    r = client.get("/openapi.json")
    assert r.status_code == 200
    paths = r.json().get("paths", {})
    assert "/api/v1/flights/{flight_id}/levels" in paths
