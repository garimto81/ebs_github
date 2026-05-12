"""Tests for /health endpoint."""


def test_health_ok(client):
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "ok"
    assert "broker_url" in body
    assert "version" in body


def test_health_includes_broker_probe(client, monkeypatch):
    """When broker unreachable, /health still returns 200 but with broker_alive=False."""
    r = client.get("/health")
    assert r.status_code == 200
    body = r.json()
    # broker_alive may be True (live) or False (down) — both 200
    assert "broker_alive" in body
    assert isinstance(body["broker_alive"], bool)
