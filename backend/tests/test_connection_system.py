"""
Tests for the Patient-Caregiver Connection System.

Covers:
- Patient connection credential generation
- Credential expiration and invalidation
- Caregiver scan / join flow
- Race condition protection
- Format validation
- Inspect endpoint
"""
import re
import uuid
import threading
from datetime import datetime, timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import get_db
from app.models.user import ConnectionCode

client = TestClient(app)


def _register_and_login(role: str, suffix: str = None):
    """Helper: register a user with the given role and return their access token."""
    sfx = suffix or uuid.uuid4().hex[:8]
    email = f"test_{sfx}@example.com"
    phone = f"+919800{sfx[:6]}"
    password = "testpassword123"

    reg = client.post(
        "/auth/register",
        json={
            "name": f"Test {role.capitalize()} {sfx}",
            "email": email,
            "phone": phone,
            "password": password,
            "role": role,
            "age": 72 if role == "PATIENT" else None,
            "emergency_contact_name": "Emergency" if role == "PATIENT" else None,
            "emergency_contact_phone": "+919999999999" if role == "PATIENT" else None,
        },
    )
    assert reg.status_code == 201, f"Registration failed: {reg.text}"

    login = client.post(
        "/auth/login",
        json={"username": email, "password": password},
    )
    assert login.status_code == 200, f"Login failed: {login.text}"
    data = login.json()
    return data["access_token"], data["user_id"]


# ---------------------------------------------------------------------------
# 1. Patient credential generation
# ---------------------------------------------------------------------------

class TestConnectionCredentialGeneration:

    def test_patient_can_generate_code(self):
        """Patient receives a valid XXXX-XXXX code and an expiry timestamp."""
        token, _ = _register_and_login("PATIENT")
        r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 200
        data = r.json()
        assert "code" in data
        assert re.match(r"^[A-Z0-9]{4}-[A-Z0-9]{4}$", data["code"]), f"Invalid code format: {data['code']}"
        assert "expires_at" in data

    def test_caregiver_cannot_generate_code(self):
        """Caregiver must be rejected when requesting a patient code."""
        token, _ = _register_and_login("CAREGIVER")
        r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert r.status_code == 403

    def test_regenerating_code_invalidates_old_code(self):
        """When a patient regenerates, the previous code must be invalidated."""
        token, user_id = _register_and_login("PATIENT")
        headers = {"Authorization": f"Bearer {token}"}

        r1 = client.post("/connections/generate-code", headers=headers)
        first_code = r1.json()["code"]

        r2 = client.post("/connections/generate-code", headers=headers)
        second_code = r2.json()["code"]

        assert first_code != second_code, "Codes should differ after regeneration"

        # Try joining with the old (invalidated) code
        cg_token, _ = _register_and_login("CAREGIVER")
        join_r = client.post(
            "/connections/join",
            json={"code": first_code},
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert join_r.status_code == 400  # Code already used/invalidated

    def test_code_expires_server_side(self):
        """A code that is forcibly expired in the DB is rejected by the join endpoint."""
        token, user_id = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {token}"},
        )
        code = gen_r.json()["code"]

        # Force-expire the code via DB
        db = next(get_db())
        try:
            cc = db.query(ConnectionCode).filter(ConnectionCode.code == code).first()
            assert cc is not None
            cc.expires_at = datetime.utcnow() - timedelta(minutes=1)
            db.commit()
        finally:
            db.close()

        cg_token, _ = _register_and_login("CAREGIVER")
        join_r = client.post(
            "/connections/join",
            json={"code": code},
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert join_r.status_code == 400
        assert "expired" in join_r.json()["detail"].lower()


# ---------------------------------------------------------------------------
# 2. Format validation
# ---------------------------------------------------------------------------

class TestCodeFormatValidation:

    def setup_method(self):
        """Create a fresh caregiver token for each test."""
        self.cg_token, _ = _register_and_login("CAREGIVER")
        self.headers = {"Authorization": f"Bearer {self.cg_token}"}

    def test_malformed_code_rejected_by_join(self):
        for bad_code in ["ABCDEFGH", "abc-1234", "ABCD-12#4", "ABCD-12345", "AB-1234"]:
            r = client.post(
                "/connections/join",
                json={"code": bad_code},
                headers=self.headers,
            )
            assert r.status_code in (400, 404), f"Expected error for code '{bad_code}', got {r.status_code}"

    def test_lowercase_code_accepted_by_join(self):
        """Backend must normalise lowercase input to uppercase before matching."""
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]
        lower_code = code.lower()

        r = client.post(
            "/connections/join",
            json={"code": lower_code},
            headers=self.headers,
        )
        # 200 = connected, or it was valid format (normalised)
        assert r.status_code == 200

    def test_canonical_format_accepted(self):
        """XXXX-XXXX format works if code exists in the DB."""
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        r = client.post(
            "/connections/join",
            json={"code": code},
            headers=self.headers,
        )
        assert r.status_code == 200


# ---------------------------------------------------------------------------
# 3. Caregiver join flow
# ---------------------------------------------------------------------------

class TestCaregiverJoinFlow:

    def test_caregiver_connects_successfully(self):
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        cg_token, _ = _register_and_login("CAREGIVER")
        join_r = client.post(
            "/connections/join",
            json={"code": code},
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert join_r.status_code == 200
        assert "connected" in join_r.json()["message"].lower()

    def test_code_cannot_be_reused(self):
        """Once a code is used for a successful connection, it must be rejected for a second caregiver."""
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        cg1_token, _ = _register_and_login("CAREGIVER")
        join1 = client.post(
            "/connections/join",
            json={"code": code},
            headers={"Authorization": f"Bearer {cg1_token}"},
        )
        assert join1.status_code == 200

        cg2_token, _ = _register_and_login("CAREGIVER")
        join2 = client.post(
            "/connections/join",
            json={"code": code},
            headers={"Authorization": f"Bearer {cg2_token}"},
        )
        assert join2.status_code == 400
        assert "used" in join2.json()["detail"].lower()

    def test_patient_cannot_join_as_caregiver(self):
        """A Patient JWT must be rejected from the /join endpoint."""
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        r = client.post(
            "/connections/join",
            json={"code": code},
            headers={"Authorization": f"Bearer {pt_token}"},  # Patient token!
        )
        assert r.status_code == 403

    def test_unauthenticated_caregiver_rejected(self):
        r = client.post("/connections/join", json={"code": "ABCD-1234"})
        assert r.status_code == 401


# ---------------------------------------------------------------------------
# 4. Inspect endpoint
# ---------------------------------------------------------------------------

class TestInspectEndpoint:

    def test_inspect_valid_code(self):
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        cg_token, _ = _register_and_login("CAREGIVER")
        r = client.get(
            f"/connections/inspect?code={code}",
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert r.status_code == 200
        data = r.json()
        assert "patient_id" in data
        assert "patient_name" in data
        assert data["code"] == code

    def test_inspect_invalid_code(self):
        cg_token, _ = _register_and_login("CAREGIVER")
        r = client.get(
            "/connections/inspect?code=ZZZZ-ZZZZ",
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert r.status_code == 404

    def test_patient_cannot_inspect(self):
        pt_token, _ = _register_and_login("PATIENT")
        r = client.get(
            "/connections/inspect?code=ABCD-1234",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        assert r.status_code == 403


# ---------------------------------------------------------------------------
# 5. Race condition test
# ---------------------------------------------------------------------------

class TestRaceCondition:

    def test_two_caregivers_same_code_only_one_succeeds(self):
        """Both caregivers attempt to join with the same code concurrently.
        Only one should succeed; the other must be rejected.
        """
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        cg1_token, _ = _register_and_login("CAREGIVER")
        cg2_token, _ = _register_and_login("CAREGIVER")

        results = []

        def try_join(token):
            r = client.post(
                "/connections/join",
                json={"code": code},
                headers={"Authorization": f"Bearer {token}"},
            )
            results.append(r.status_code)

        t1 = threading.Thread(target=try_join, args=(cg1_token,))
        t2 = threading.Thread(target=try_join, args=(cg2_token,))
        t1.start()
        t2.start()
        t1.join()
        t2.join()

        successes = results.count(200)
        assert successes == 1, f"Expected exactly 1 success, got statuses: {results}"

    def test_relationship_created_after_connection(self):
        """After successful connection, the caregiver can see the patient in their connections list."""
        pt_token, _ = _register_and_login("PATIENT")
        gen_r = client.post(
            "/connections/generate-code",
            headers={"Authorization": f"Bearer {pt_token}"},
        )
        code = gen_r.json()["code"]

        cg_token, _ = _register_and_login("CAREGIVER")
        join_r = client.post(
            "/connections/join",
            json={"code": code},
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert join_r.status_code == 200

        connections_r = client.get(
            "/connections",
            headers={"Authorization": f"Bearer {cg_token}"},
        )
        assert connections_r.status_code == 200
        patients = connections_r.json()
        assert len(patients) >= 1
