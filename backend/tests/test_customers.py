def get_token(client, email, password):
    response = client.post(
        "/api/auth/login",
        data={
            "username": email,
            "password": password
        }
    )
    return response.json()["access_token"]


def test_get_customers(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.get(
        "/api/customers",
        headers={"Authorization": f"Bearer {token}"}
    )

    assert response.status_code == 200
    assert len(response.json()) == 1


def test_create_customer_requires_admin(client):
    token = get_token(client, "salesman@test.com", "test123")

    response = client.post(
        "/api/customers",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": "New Customer",
            "email": "new@example.com",
            "phone": "9999999999",
            "address": "New Address"
        }
    )

    assert response.status_code == 403


def test_create_customer_admin(client):
    token = get_token(client, "admin@test.com", "admin123")

    response = client.post(
        "/api/customers",
        headers={"Authorization": f"Bearer {token}"},
        json={
            "name": "New Customer",
            "email": "new@example.com",
            "phone": "9999999999",
            "address": "New Address"
        }
    )

    assert response.status_code == 201
    assert response.json()["name"] == "New Customer"