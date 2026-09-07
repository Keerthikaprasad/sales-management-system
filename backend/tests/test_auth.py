def test_login_success(client):
    response = client.post(
        "/api/auth/login",
        data={
            "username": "salesman@test.com",
            "password": "test123"
        }
    )

    assert response.status_code == 200

    data = response.json()

    assert "access_token" in data
    assert data["token_type"] == "bearer"


def test_login_invalid_password(client):
    response = client.post(
        "/api/auth/login",
        data={
            "username": "salesman@test.com",
            "password": "wrongpassword"
        }
    )

    assert response.status_code == 401