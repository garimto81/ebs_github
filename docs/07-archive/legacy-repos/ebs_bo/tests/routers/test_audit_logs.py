from bo.db.models import AuditLog


def _seed_logs(session, user_id):
    for i in range(5):
        log = AuditLog(
            user_id=user_id,
            entity_type="table" if i % 2 == 0 else "session",
            entity_id=i + 1,
            action="create" if i % 2 == 0 else "login",
            detail=f"Test log {i}",
        )
        session.add(log)
    session.commit()


def test_list_audit_logs(client, auth_headers, admin_user, session):
    _seed_logs(session, admin_user.user_id)
    resp = client.get("/api/v1/audit-logs", headers=auth_headers)
    assert resp.status_code == 200
    assert resp.json()["meta"]["total"] >= 5


def test_filter_by_entity_type(client, auth_headers, admin_user, session):
    _seed_logs(session, admin_user.user_id)
    resp = client.get("/api/v1/audit-logs?entity_type=table", headers=auth_headers)
    assert resp.status_code == 200
    for item in resp.json()["data"]:
        assert item["entity_type"] == "table"


def test_filter_by_action(client, auth_headers, admin_user, session):
    _seed_logs(session, admin_user.user_id)
    resp = client.get("/api/v1/audit-logs?action=login", headers=auth_headers)
    assert resp.status_code == 200
    for item in resp.json()["data"]:
        assert item["action"] == "login"


def test_pagination(client, auth_headers, admin_user, session):
    _seed_logs(session, admin_user.user_id)
    resp = client.get("/api/v1/audit-logs?page=1&limit=2", headers=auth_headers)
    assert resp.status_code == 200
    assert len(resp.json()["data"]) <= 2
    assert resp.json()["meta"]["limit"] == 2


def test_unauthorized(client):
    resp = client.get("/api/v1/audit-logs")
    assert resp.status_code in (401, 403)


def test_viewer_cannot_access(client, viewer_headers):
    resp = client.get("/api/v1/audit-logs", headers=viewer_headers)
    assert resp.status_code == 403
