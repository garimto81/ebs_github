"""Cycle 17 — BrandPack CRUD endpoint tests (TDD Red).

S7 Backend: 이벤트 브랜딩 데이터 (사용자 표 #6).
SSOT: docs/1. Product/RIVE_Standards.md Ch.7 — 컬러 팔레트, 폰트, 로고 (3종), 그래픽 모티프.

Pattern: 기존 tests/test_routers_2_6_extended.py 의 _login_token / _admin_headers 와 동일.
"""
from __future__ import annotations

# ── helpers (test_routers_2_6_extended.py 패턴 재사용) ────


def _login_token(client, email="admin@test.com", password="Admin123!") -> str:
    resp = client.post("/api/v1/auth/login", json={"email": email, "password": password})
    return resp.json()["data"]["accessToken"]


def _admin_headers(client) -> dict:
    return {"Authorization": f"Bearer {_login_token(client)}"}


def _viewer_headers(client) -> dict:
    resp = client.post(
        "/api/v1/auth/login",
        json={"email": "viewer@test.com", "password": "View123!"},
    )
    return {"Authorization": f"Bearer {resp.json()['data']['accessToken']}"}


def _brand_pack_payload(name: str = "test_pack_alpha") -> dict:
    """Default name is 'test_pack_alpha' (NOT 'wsop_2026') to avoid colliding
    with the seeded default brand pack populated by init_db()."""
    return {
        "name": name,
        "displayName": "Test Pack Alpha",
        "primaryColor": "#000000",
        "secondaryColor": "#D4AF37",
        "accentColor": "#FFFFFF",
        "fontFamily": "Roboto",
        "logoPrimaryUrl": "https://cdn/example/wsop_primary.svg",
        "logoSecondaryUrl": "https://cdn/example/wsop_secondary.svg",
        "logoTertiaryUrl": "https://cdn/example/wsop_tertiary.svg",
        "motifData": "{\"grid\":\"diamond\"}",
        "isDefault": False,
    }


# ── BrandPack: list ────────────────────────────────


def test_list_brand_packs_unauthenticated_401(client, seed_users):
    resp = client.get("/api/v1/brand-packs")
    assert resp.status_code == 401


def test_list_brand_packs_admin_200_seeded(client, seed_users):
    """Default seed populates 1 BrandPack (wsop_2026) at init_db() time."""
    resp = client.get("/api/v1/brand-packs", headers=_admin_headers(client))
    assert resp.status_code == 200
    body = resp.json()
    assert "data" in body
    assert isinstance(body["data"], list)
    # 최소 1개 (seed). 다른 테스트에서 생성한 row 가 있을 수도 있으므로 >= 1.
    assert body["meta"]["total"] >= 1
    seeded = next((p for p in body["data"] if p["name"] == "wsop_2026"), None)
    assert seeded is not None, "wsop_2026 seed missing"
    assert seeded["isDefault"] is True


# ── BrandPack: create ──────────────────────────────


def test_create_brand_pack_admin_201(client, seed_users):
    resp = client.post(
        "/api/v1/brand-packs",
        json=_brand_pack_payload(),
        headers=_admin_headers(client),
    )
    assert resp.status_code == 201, resp.text
    body = resp.json()
    assert body["data"]["name"] == "test_pack_alpha"
    assert body["data"]["primaryColor"] == "#000000"
    assert body["data"]["logoPrimaryUrl"].endswith("wsop_primary.svg")
    assert body["data"]["isDefault"] is False
    assert isinstance(body["data"]["brandPackId"], int)


def test_create_brand_pack_viewer_403(client, seed_users):
    """RBAC: viewer 는 admin endpoint 호출 불가."""
    resp = client.post(
        "/api/v1/brand-packs",
        json=_brand_pack_payload("viewer_attempt"),
        headers=_viewer_headers(client),
    )
    assert resp.status_code == 403


def test_create_brand_pack_duplicate_name_409(client, seed_users):
    headers = _admin_headers(client)
    client.post("/api/v1/brand-packs", json=_brand_pack_payload("dup_test"), headers=headers)
    resp = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("dup_test"), headers=headers
    )
    assert resp.status_code == 409
    # FastAPI HTTPException default envelope: {"detail": {"code": ..., "message": ...}}
    assert resp.json()["detail"]["code"] == "DUPLICATE"


# ── BrandPack: get ─────────────────────────────────


def test_get_brand_pack_200(client, seed_users):
    headers = _admin_headers(client)
    created = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("get_test"), headers=headers
    ).json()
    bp_id = created["data"]["brandPackId"]
    resp = client.get(f"/api/v1/brand-packs/{bp_id}", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "get_test"


def test_get_brand_pack_404(client, seed_users):
    resp = client.get("/api/v1/brand-packs/99999", headers=_admin_headers(client))
    assert resp.status_code == 404


# ── BrandPack: update ──────────────────────────────


def test_update_brand_pack_admin_200(client, seed_users):
    headers = _admin_headers(client)
    created = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("update_test"), headers=headers
    ).json()
    bp_id = created["data"]["brandPackId"]
    resp = client.put(
        f"/api/v1/brand-packs/{bp_id}",
        json={"displayName": "Updated", "primaryColor": "#FF0000"},
        headers=headers,
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["data"]["displayName"] == "Updated"
    assert body["data"]["primaryColor"] == "#FF0000"
    # untouched fields remain
    assert body["data"]["secondaryColor"] == "#D4AF37"


# ── BrandPack: delete ──────────────────────────────


def test_delete_brand_pack_admin_200(client, seed_users):
    headers = _admin_headers(client)
    created = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("delete_test"), headers=headers
    ).json()
    bp_id = created["data"]["brandPackId"]
    resp = client.delete(f"/api/v1/brand-packs/{bp_id}", headers=headers)
    assert resp.status_code == 200
    # follow-up GET → 404
    resp2 = client.get(f"/api/v1/brand-packs/{bp_id}", headers=headers)
    assert resp2.status_code == 404


# ── BrandPack: activate ────────────────────────────


def test_activate_brand_pack_single_default(client, seed_users):
    """activate 시 모든 다른 BrandPack 의 isDefault=False."""
    headers = _admin_headers(client)
    a = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("a"), headers=headers
    ).json()["data"]
    b = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("b"), headers=headers
    ).json()["data"]

    # Activate a
    resp_a = client.post(
        f"/api/v1/brand-packs/{a['brandPackId']}/activate", headers=headers
    )
    assert resp_a.status_code == 200
    assert resp_a.json()["data"]["isDefault"] is True

    # Activate b — a 의 isDefault 가 False 가 되어야 함
    client.post(f"/api/v1/brand-packs/{b['brandPackId']}/activate", headers=headers)
    a_after = client.get(
        f"/api/v1/brand-packs/{a['brandPackId']}", headers=headers
    ).json()["data"]
    assert a_after["isDefault"] is False


# ── BrandPack: active endpoint ─────────────────────


def test_get_active_brand_pack_returns_default(client, seed_users):
    headers = _admin_headers(client)
    created = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("only"), headers=headers
    ).json()["data"]
    client.post(
        f"/api/v1/brand-packs/{created['brandPackId']}/activate", headers=headers
    )

    resp = client.get("/api/v1/brand-packs/active", headers=headers)
    assert resp.status_code == 200
    assert resp.json()["data"]["name"] == "only"


# ── BlindStructure GET endpoint regression (이미 존재, seed data 확인) ──


def test_list_blind_structures_endpoint_exists(client, seed_users):
    """GET /api/v1/blind-structures = Cycle 17 사용자 표 #7 요구사항."""
    resp = client.get("/api/v1/blind-structures", headers=_admin_headers(client))
    assert resp.status_code == 200
    body = resp.json()
    assert "data" in body
    assert "meta" in body
    assert "total" in body["meta"]


# ── BrandPack: schema field coverage (사용자 표 #6) ────


def test_brand_pack_required_fields_present_in_response(client, seed_users):
    """spec 명세: 컬러 3 (primary/secondary/accent) + 로고 3종 + 폰트 + motif 모두 schema 반영."""
    headers = _admin_headers(client)
    resp = client.post(
        "/api/v1/brand-packs", json=_brand_pack_payload("schema_check"), headers=headers
    )
    assert resp.status_code == 201
    data = resp.json()["data"]
    for required in (
        "brandPackId",
        "name",
        "displayName",
        "primaryColor",
        "secondaryColor",
        "accentColor",
        "fontFamily",
        "logoPrimaryUrl",
        "logoSecondaryUrl",
        "logoTertiaryUrl",
        "motifData",
        "isDefault",
        "createdAt",
        "updatedAt",
    ):
        assert required in data, f"missing field: {required}"
